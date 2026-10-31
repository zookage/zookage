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
readonly base_dir=$(dirname "$(dirname "$(cd "$(dirname "$0")" || exit; pwd)")")

"${integration_dir}/divider.sh" "Start checking ZooKeeper"

expect_failure() {
  local -r description=$1
  shift

  if "$@"; then
    echo "${description} unexpectedly succeeded" >&2
    exit 1
  fi
}

if [[ ${ZOOKAGE_TEST_MODE:-} == "auth" ]]; then
  "${base_dir}/bin/kubectl" exec -i client-node-0 -- sh -c \
    'umask 077; cat > /tmp/zookeeper-client-jaas.conf' <<'JAAS'
Client {
  com.sun.security.auth.module.Krb5LoginModule required
  useKeyTab=true
  storeKey=true
  useTicketCache=false
  keyTab="/etc/secrets/client/client.keytab"
  principal="zookage@ZOOKAGE.LOCAL";
};
JAAS
fi

zk_stat() {
  local -r host=$1
  local -r client_flags=$2

  "${base_dir}/bin/kubectl" exec client-node-0 -- env \
    ZOOCFGDIR=/opt/zookeeper/conf \
    CLIENT_JVMFLAGS="${client_flags}" \
    timeout 20 /opt/zookeeper/bin/zkCli.sh -server "${host}:2181" stat /
}

for i in {0..2}; do
  zookeeper_host="zookeeper-server-${i}.zookeeper-server.zookage.svc.cluster.local"
  if [[ ${ZOOKAGE_TEST_MODE:-} == "auth" ]]; then
    expect_failure "AdminServer access" \
      "${base_dir}/bin/kubectl" exec client-node-0 -- \
      curl --fail --silent --show-error --max-time 5 \
      "http://${zookeeper_host}:8080/commands/monitor"
    if ! stat_response=$(zk_stat "${zookeeper_host}" \
      "-Djava.security.auth.login.config=/tmp/zookeeper-client-jaas.conf" 2>&1) ||
      ! grep -Eq 'cZxid = ' <<< "${stat_response}"; then
      echo "Kerberos-authenticated ZooKeeper access failed: ${stat_response}" >&2
      exit 1
    fi
    unauth_response=$(zk_stat "${zookeeper_host}" \
      "-Dzookeeper.sasl.client=false" 2>&1) || true
    if grep -Eq 'cZxid = ' <<< "${unauth_response}" ||
      ! grep -Eq 'AuthFailed|Session closed' <<< "${unauth_response}"; then
      echo "Unauthenticated ZooKeeper access was not rejected: ${unauth_response}" >&2
      exit 1
    fi
    echo "Kerberos authentication succeeded and unauthenticated access was rejected by ${zookeeper_host}"
  else
    admin_url="http://${zookeeper_host}:8080/commands/monitor"
    monitor_response=$("${base_dir}/bin/kubectl" exec client-node-0 -- \
      curl --fail --silent --show-error --max-time 10 \
      "${admin_url}")
    if ! grep -Eq '"error"[[:space:]]*:[[:space:]]*null' <<< "${monitor_response}" ||
      ! grep -Eq '"server_state"[[:space:]]*:[[:space:]]*"(leader|follower)"' <<< "${monitor_response}"; then
      echo "ZooKeeper server ${i} is not serving as a leader or follower: ${monitor_response}" >&2
      exit 1
    fi
    echo "${monitor_response}"
  fi
done

"${integration_dir}/divider.sh" "Finished checking ZooKeeper"
echo "The test command succeeded."
echo
