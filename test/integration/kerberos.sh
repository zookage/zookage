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
readonly base_dir=$(dirname "$(dirname "${integration_dir}")")

"${integration_dir}/divider.sh" "Start checking Kerberos"

"${integration_dir}/run.sh" /bin/bash -lc "kdestroy || true"

if "${integration_dir}/run.sh" timeout 20s yarn application -list; then
  echo "Unauthenticated YARN access unexpectedly succeeded." >&2
  exit 1
fi

"${integration_dir}/run.sh" kinit \
  -kt /etc/kerberos/secrets/client.keytab \
  zookage@ZOOKAGE.LOCAL
"${integration_dir}/run.sh" klist
"${integration_dir}/run.sh" yarn application -list

readonly nodemanager_replicas=$("${base_dir}/bin/kubectl" get statefulset yarn-nodemanager -o jsonpath='{.spec.replicas}')
for ((ordinal = 0; ordinal < nodemanager_replicas; ordinal++)); do
  "${base_dir}/bin/kubectl" exec -i "yarn-nodemanager-${ordinal}" -c nodemanager -- /bin/bash -eu <<'EOF'
"${HADOOP_HOME}/bin/container-executor" --checksetup
test "$(id -g)" = 1010
test "$(stat -c '%u:%g:%a' "${HADOOP_HOME}/bin/container-executor")" = 0:1010:6050
for user in zookage alice hive trino; do
  getent passwd "${user}"
  id "${user}"
  [[ " $(id -G "${user}") " != *" 1010 "* ]]
done
test -r /etc/yarn/secrets/yarn.keytab
test "$(stat -c '%u:%g:%a' /etc/yarn/secrets)" = 1012:1012:700
test "$(stat -c '%u:%g:%a' /etc/yarn/secrets/yarn.keytab)" = 1012:1012:400
test "$(stat -c '%u:%g:%a' /var/lib/sss/pipes)" = 0:0:755
test "$(stat -c '%u:%g:%a' /var/lib/sss/pipes/private)" = 0:0:700
awk '
  ($2 == "/etc/yarn/secrets" || $2 == "/var/lib/sss/pipes") && $4 ~ /(^|,)ro(,|$)/ { protected++ }
  END { exit protected != 2 }
' /proc/mounts
EOF
done

"${integration_dir}/divider.sh" "Finished checking Kerberos"
echo "The Kerberos smoke test succeeded."
echo
