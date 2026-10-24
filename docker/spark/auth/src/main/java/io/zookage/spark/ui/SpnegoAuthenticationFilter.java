/*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package io.zookage.spark.ui;

import java.io.IOException;
import java.security.Principal;
import java.security.PrivilegedActionException;
import java.security.PrivilegedExceptionAction;
import java.util.Base64;
import java.util.HashMap;
import java.util.Map;

import javax.security.auth.Subject;
import javax.security.auth.login.AppConfigurationEntry;
import javax.security.auth.login.Configuration;
import javax.security.auth.login.LoginContext;
import javax.security.auth.login.LoginException;

import jakarta.servlet.Filter;
import jakarta.servlet.FilterChain;
import jakarta.servlet.FilterConfig;
import jakarta.servlet.ServletException;
import jakarta.servlet.ServletRequest;
import jakarta.servlet.ServletResponse;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletRequestWrapper;
import jakarta.servlet.http.HttpServletResponse;
import org.ietf.jgss.GSSContext;
import org.ietf.jgss.GSSCredential;
import org.ietf.jgss.GSSException;
import org.ietf.jgss.GSSManager;
import org.ietf.jgss.Oid;

/**
 * SPNEGO authentication for Spark 4's Jakarta Servlet based web UI.
 *
 * <p>The service principal and keytab are supplied through Spark's filter parameters. The filter
 * is intended for the History Server only; a live Spark driver has no HTTP service keytab.
 */
public final class SpnegoAuthenticationFilter implements Filter {
  private static final String NEGOTIATE = "Negotiate";

  private final GSSManager gssManager = GSSManager.getInstance();
  private LoginContext loginContext;
  private Subject subject;
  private String principal;
  private String realm;
  private Oid principalNameOid;
  private Oid[] mechanisms;

  @Override
  public void init(FilterConfig config) throws ServletException {
    principal = requiredParameter(config, "principal");
    String keytab = requiredParameter(config, "keytab");
    int realmSeparator = principal.lastIndexOf('@');
    if (!principal.startsWith("HTTP/") || realmSeparator <= "HTTP/".length()
        || realmSeparator == principal.length() - 1) {
      throw new ServletException("SPNEGO principal must be HTTP/<host>@<realm>");
    }
    realm = principal.substring(realmSeparator + 1);

    Map<String, String> options = new HashMap<>();
    options.put("principal", principal);
    options.put("keyTab", keytab);
    options.put("useKeyTab", "true");
    options.put("storeKey", "true");
    options.put("doNotPrompt", "true");
    options.put("isInitiator", "false");
    Configuration jaas = new Configuration() {
      @Override
      public AppConfigurationEntry[] getAppConfigurationEntry(String name) {
        return new AppConfigurationEntry[] {
            new AppConfigurationEntry("com.sun.security.auth.module.Krb5LoginModule",
                AppConfigurationEntry.LoginModuleControlFlag.REQUIRED, options)
        };
      }
    };

    try {
      principalNameOid = new Oid("1.2.840.113554.1.2.2.1");
      mechanisms = new Oid[] {
          new Oid("1.3.6.1.5.5.2"),
          new Oid("1.2.840.113554.1.2.2")
      };
      loginContext = new LoginContext("SparkHistoryServerSPNEGO", null, null, jaas);
      loginContext.login();
      subject = loginContext.getSubject();
    } catch (GSSException | LoginException e) {
      throw new ServletException("Cannot initialize Spark History Server SPNEGO", e);
    }
  }

  private static String requiredParameter(FilterConfig config, String name) throws ServletException {
    String value = config.getInitParameter(name);
    if (value == null || value.isBlank()) {
      throw new ServletException("Missing SPNEGO filter parameter: " + name);
    }
    return value;
  }

  @Override
  public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
      throws IOException, ServletException {
    HttpServletRequest httpRequest = (HttpServletRequest) request;
    HttpServletResponse httpResponse = (HttpServletResponse) response;
    String authorization = httpRequest.getHeader("Authorization");
    if (authorization == null || !authorization.regionMatches(true, 0, NEGOTIATE + " ", 0, 10)) {
      challenge(httpResponse, null);
      return;
    }

    byte[] clientToken;
    try {
      clientToken = Base64.getDecoder().decode(authorization.substring(10).trim());
    } catch (IllegalArgumentException e) {
      challenge(httpResponse, null);
      return;
    }
    if (clientToken.length == 0) {
      challenge(httpResponse, null);
      return;
    }

    Authentication authentication;
    try {
      authentication = Subject.doAs(subject,
          (PrivilegedExceptionAction<Authentication>) () -> accept(clientToken));
    } catch (PrivilegedActionException e) {
      Exception cause = e.getException();
      if (cause instanceof GSSException) {
        GSSException gss = (GSSException) cause;
        if (gss.getMajor() == GSSException.NO_CRED
            || gss.getMajor() == GSSException.CREDENTIALS_EXPIRED) {
          throw new ServletException("SPNEGO service credentials are unavailable", gss);
        }
        challenge(httpResponse, null);
        return;
      }
      throw new ServletException("SPNEGO authentication failed", cause);
    }

    if (!authentication.established) {
      challenge(httpResponse, authentication.serverToken);
      return;
    }
    if (authentication.serverToken != null && authentication.serverToken.length > 0) {
      httpResponse.setHeader("WWW-Authenticate",
          NEGOTIATE + " " + Base64.getEncoder().encodeToString(authentication.serverToken));
    }

    String user = shortUserName(authentication.clientPrincipal, realm);
    if (user == null) {
      httpResponse.setStatus(HttpServletResponse.SC_FORBIDDEN);
      return;
    }
    Principal userPrincipal = () -> authentication.clientPrincipal;
    chain.doFilter(new HttpServletRequestWrapper(httpRequest) {
      @Override
      public String getAuthType() {
        return "SPNEGO";
      }

      @Override
      public String getRemoteUser() {
        return user;
      }

      @Override
      public Principal getUserPrincipal() {
        return userPrincipal;
      }
    }, response);
  }

  private Authentication accept(byte[] clientToken) throws GSSException {
    GSSCredential credential = null;
    GSSContext context = null;
    try {
      credential = gssManager.createCredential(
          gssManager.createName(principal, principalNameOid),
          GSSCredential.INDEFINITE_LIFETIME, mechanisms, GSSCredential.ACCEPT_ONLY);
      context = gssManager.createContext(credential);
      byte[] serverToken = context.acceptSecContext(clientToken, 0, clientToken.length);
      if (!context.isEstablished()) {
        // A new request cannot resume this context after it is disposed below.
        return new Authentication(false, null, null);
      }
      return new Authentication(true, context.getSrcName().toString(), serverToken);
    } finally {
      if (context != null) {
        context.dispose();
      }
      if (credential != null) {
        credential.dispose();
      }
    }
  }

  static String shortUserName(String clientPrincipal, String realm) {
    if (clientPrincipal == null) {
      return null;
    }
    int separator = clientPrincipal.lastIndexOf('@');
    if (separator < 1 || !realm.equals(clientPrincipal.substring(separator + 1))) {
      return null;
    }
    String user = clientPrincipal.substring(0, separator);
    // Service principals must not acquire the ACLs of the similarly named user.
    return user.indexOf('/') >= 0 ? null : user;
  }

  private static void challenge(HttpServletResponse response, byte[] serverToken) {
    String header = NEGOTIATE;
    if (serverToken != null && serverToken.length > 0) {
      header += " " + Base64.getEncoder().encodeToString(serverToken);
    }
    response.setHeader("WWW-Authenticate", header);
    response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
  }

  @Override
  public void destroy() {
    if (loginContext != null) {
      try {
        loginContext.logout();
      } catch (LoginException ignored) {
        // The container is stopping; there is no credential left to use.
      }
    }
  }

  private static final class Authentication {
    private final boolean established;
    private final String clientPrincipal;
    private final byte[] serverToken;

    private Authentication(boolean established, String clientPrincipal, byte[] serverToken) {
      this.established = established;
      this.clientPrincipal = clientPrincipal;
      this.serverToken = serverToken;
    }
  }
}
