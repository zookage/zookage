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

import org.apache.hadoop.fs.Path;
import org.apache.hadoop.security.UserGroupInformation;
import org.apache.hadoop.yarn.client.cli.LogsCLI;
import org.apache.hadoop.yarn.conf.YarnConfiguration;

class YarnLogs {
  public static void main(String[] args) throws Exception {
    YarnConfiguration conf = new YarnConfiguration();
    conf.addResource(new Path("/etc/hive/conf/hive-site.xml"));
    String principal = conf.getTrimmed("hive.server2.authentication.kerberos.principal");
    String keytab = conf.getTrimmed("hive.server2.authentication.kerberos.keytab");
    if (principal == null || principal.isEmpty() || keytab == null || keytab.isEmpty()) {
      throw new IllegalStateException("HiveServer2 Kerberos principal and keytab must be configured");
    }
    UserGroupInformation.setConfiguration(conf);
    UserGroupInformation.loginUserFromKeytab(principal, keytab);
    LogsCLI.main(args);
  }
}
