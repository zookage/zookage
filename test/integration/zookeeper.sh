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
  "${base_dir}/bin/kubectl" exec -it \
    "zookeeper-server-${i}" \
    -- \
    env JAVA_TOOL_OPTIONS= \
    /opt/zookeeper/bin/zkServer.sh \
    status

  if [[ ${ZOOKAGE_TEST_MODE:-} == "auth" ]]; then
    zookeeper_host="zookeeper-server-${i}.zookeeper-server.zookage.svc.cluster.local"
    admin_url="https://${zookeeper_host}:8080/commands/ruok"

    expect_failure "Plain HTTP AdminServer access" \
      "${base_dir}/bin/kubectl" exec client-node-0 -- \
      curl --fail --silent --show-error --max-time 10 \
      "http://${zookeeper_host}:8080/commands/ruok"
    expect_failure "AdminServer access without a client certificate" \
      "${base_dir}/bin/kubectl" exec client-node-0 -- \
      curl --fail --silent --show-error --max-time 10 \
      --cacert /etc/zookeeper/conf/zookage-ca.crt \
      "${admin_url}"
    "${base_dir}/bin/kubectl" exec client-node-0 -- \
      curl --fail --silent --show-error --max-time 10 \
      --cacert /etc/zookeeper/conf/zookage-ca.crt \
      --cert-type P12 \
      --cert /etc/secrets/zookeeper-client/zookeeper-client.p12:zookage \
      "${admin_url}"
  fi
done

if [[ ${ZOOKAGE_TEST_MODE:-} == "auth" ]]; then
  zookeeper_host=zookeeper-server-0.zookeeper-server.zookage.svc.cluster.local
  "${base_dir}/bin/kubectl" exec client-node-0 -- \
    /opt/zookeeper/bin/zkCli.sh \
    -server "${zookeeper_host}:2181" -timeout 10000 -waitforconnection ls /
  expect_failure "Four-letter-word access without a client certificate" \
    "${base_dir}/bin/kubectl" exec zookeeper-server-0 -- \
    env JAVA_TOOL_OPTIONS= \
    CLIENT_JVMFLAGS="-Dzookeeper.client.secure=true -Dzookeeper.clientCnxnSocket=org.apache.zookeeper.ClientCnxnSocketNetty -Dzookeeper.ssl.trustStore.location=/etc/zookeeper/conf/zookage-truststore.jks -Dzookeeper.ssl.trustStore.password=zookage" \
    /opt/zookeeper/bin/zkServer.sh status
  expect_failure "Plaintext ZooKeeper client access" \
    "${base_dir}/bin/kubectl" exec client-node-0 -- \
    env JAVA_TOOL_OPTIONS=-Djava.security.auth.login.config=/etc/zookeeper/conf/client-jaas.conf \
    CLIENT_JVMFLAGS= \
    /opt/zookeeper/bin/zkCli.sh \
    -server "${zookeeper_host}:2181" -timeout 3000 -waitforconnection ls /
  expect_failure "ZooKeeper client access without SASL" \
    "${base_dir}/bin/kubectl" exec client-node-0 -- \
    env CLIENT_JVMFLAGS=-Dzookeeper.sasl.client=false \
    /opt/zookeeper/bin/zkCli.sh \
    -server "${zookeeper_host}:2181" -timeout 10000 -waitforconnection ls /
fi

"${integration_dir}/divider.sh" "Finished checking ZooKeeper"
echo "The test command succeeded."
echo
