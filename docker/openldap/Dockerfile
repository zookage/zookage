# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# syntax=docker/dockerfile:experimental
ARG ubuntu_image

# hadolint ignore=DL3006
FROM ${ubuntu_image}

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# hadolint ignore=DL3008
RUN apt-get update \
  && printf '%s\n' \
    'slapd slapd/internal/adminpw password admin' \
    'slapd slapd/internal/generated_adminpw password admin' \
    'slapd slapd/password1 password admin' \
    'slapd slapd/password2 password admin' \
    'slapd slapd/domain string example.com' \
    | debconf-set-selections \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    -o Dpkg::Options::=--path-include=/usr/share/doc/krb5-kdc-ldap/kerberos.openldap.ldif.gz \
    krb5-kdc-ldap \
    ldap-utils \
    slapd \
  && zcat /usr/share/doc/krb5-kdc-ldap/kerberos.openldap.ldif.gz > /tmp/kerberos.openldap.ldif \
  && slapadd -n 0 -F /etc/ldap/slapd.d -l /tmp/kerberos.openldap.ldif \
  && chown -R openldap:openldap /etc/ldap/slapd.d \
  && apt-get clean \
  && rm -rf /tmp/kerberos.openldap.ldif /var/lib/apt/lists/*

COPY entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod 0755 /usr/local/bin/docker-entrypoint.sh

USER openldap:openldap
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["slapd", "-d", "0", "-h", "ldap://0.0.0.0:389/ ldapi:///"]
