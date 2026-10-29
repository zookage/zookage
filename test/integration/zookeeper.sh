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

for i in {0..2}; do
  zookeeper_host="zookeeper-server-${i}.zookeeper-server.zookage.svc.cluster.local"
  if [[ ${ZOOKAGE_TEST_MODE:-} == "auth" ]]; then
    admin_url="https://${zookeeper_host}:8080/commands/monitor"

    expect_failure "Plain HTTP AdminServer access" \
      "${base_dir}/bin/kubectl" exec client-node-0 -- \
      curl --fail --silent --show-error --max-time 10 \
      "http://${zookeeper_host}:8080/commands/monitor"
    expect_failure "AdminServer access without a client certificate" \
      "${base_dir}/bin/kubectl" exec client-node-0 -- \
      curl --fail --silent --show-error --max-time 10 \
      --cacert /etc/hadoop/conf/zookage-ca.crt \
      "${admin_url}"
    monitor_response=$("${base_dir}/bin/kubectl" exec client-node-0 -- \
      curl --fail --silent --show-error --max-time 10 \
      --cacert /etc/hadoop/conf/zookage-ca.crt \
      --cert-type P12 \
      --cert /etc/secrets/zookeeper-client/zookeeper-client.p12:zookage \
      "${admin_url}")
  else
    admin_url="http://${zookeeper_host}:8080/commands/monitor"
    monitor_response=$("${base_dir}/bin/kubectl" exec client-node-0 -- \
      curl --fail --silent --show-error --max-time 10 \
      "${admin_url}")
  fi
  if ! grep -Eq '"error"[[:space:]]*:[[:space:]]*null' <<< "${monitor_response}" ||
    ! grep -Eq '"server_state"[[:space:]]*:[[:space:]]*"(leader|follower)"' <<< "${monitor_response}"; then
    echo "ZooKeeper server ${i} is not serving as a leader or follower: ${monitor_response}" >&2
    exit 1
  fi
  echo "${monitor_response}"
done

"${integration_dir}/divider.sh" "Finished checking ZooKeeper"
echo "The test command succeeded."
echo
