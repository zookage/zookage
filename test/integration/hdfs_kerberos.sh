#!/bin/bash
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

set -eu

readonly integration_dir=$(cd "$(dirname "$0")"; pwd)
readonly kerberos_hdfs_env="HADOOP_SECURITY_AUTHENTICATION=kerberos HADOOP_RPC_PROTECTION=authentication"
readonly kerberos_hdfs_command="${kerberos_hdfs_env} hdfs dfs -ls /"
readonly smoke_path="/user/zookage/.kerberos-smoke"
readonly httpfs_url="http://hdfs-httpfs.zookage.svc.cluster.local:14000/webhdfs/v1/?op=liststatus"

"${integration_dir}/divider.sh" "Start checking HDFS Kerberos"

"${integration_dir}/run.sh" /bin/bash -lc "kdestroy || true"

if "${integration_dir}/run.sh" timeout 20s /bin/bash -lc "${kerberos_hdfs_command}"; then
  echo "Unauthenticated HDFS RPC access unexpectedly succeeded." >&2
  exit 1
fi
if "${integration_dir}/run.sh" curl --fail "${httpfs_url}"; then
  echo "Unauthenticated HttpFS access unexpectedly succeeded." >&2
  exit 1
fi

"${integration_dir}/run.sh" kinit \
  -kt /etc/kerberos/secrets/client.keytab \
  zookage@ZOOKAGE.LOCAL
"${integration_dir}/run.sh" klist
"${integration_dir}/run.sh" /bin/bash -lc "${kerberos_hdfs_command}"
"${integration_dir}/run.sh" /bin/bash -lc \
  "${kerberos_hdfs_env} hdfs dfs -put -f /etc/hosts ${smoke_path}"
"${integration_dir}/run.sh" /bin/bash -lc \
  "${kerberos_hdfs_env} hdfs dfs -cat ${smoke_path} | cmp - /etc/hosts"
"${integration_dir}/run.sh" /bin/bash -lc \
  "${kerberos_hdfs_env} hdfs dfs -rm ${smoke_path}"
"${integration_dir}/run.sh" curl --fail --negotiate -u : "${httpfs_url}"

"${integration_dir}/divider.sh" "Finished checking HDFS Kerberos"
echo "The HDFS Kerberos smoke test succeeded."
echo
