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

set -u

readonly integration_dir=$(cd "$(dirname "$0")" || exit; pwd)
readonly base_dir=$(dirname "$(dirname "${integration_dir}")")

kerberos_errors='^$'
if [[ ${ZOOKAGE_AUTH_TEST:-} == "1" ]]; then
  # Hadoop parses the root of each LLAP token cache as a token at startup.
  kerberos_errors='pod/hive-(hiveserver2-[^:]+|llap-[0-9]+): .*delegation\.ZKDelegationTokenSecretManager: Error while processing Curator (keyCacheListener|tokenCacheListener) NODE_CREATED / NODE_CHANGED event$'
  # shellcheck disable=SC2016
  kerberos_errors+='|pod/hive-(hiveserver2-[^:]+|llap-[0-9]+): .*listen\.MappingListenerManager: Listener \(org\.apache\.curator\.framework\.recipes\.cache\.CuratorCacheListenerBuilderImpl\$2@[0-9a-f]+\) threw an exception$'
  # Ozone creates certificates and keys on the first secure startup.
  kerberos_errors+='|pod/ozone-(datanode|om|recon|scm)-[0-9]+: .*\[main\] ERROR .*CertificateClient: Default certificate serial id is not set\. Can.t locate the default certificate for this client\.$'
  kerberos_errors+='|pod/ozone-scm-[0-9]+: .*\[main\] ERROR keys\.KeyStorage: Failed to read the public key\.$'
  kerberos_errors+='|pod/ozone-(datanode|om|recon|scm)-[0-9]+: .*\[main\] ERROR utils\.(CertificateSignRequest|SelfSignedCertificate): Invalid domain ozone-.*\.zookage\.svc\.cluster\.local$'
fi
readonly kerberos_errors

"${integration_dir}/divider.sh" "Start fetching errors of all containers"

# shellcheck disable=SC2016
"${base_dir}/bin/logs" \
  | grep ' ERROR ' \
  | grep -Ev "${kerberos_errors}" \
  | grep -v 'pod/hive-hiveserver2-.* ERROR Attempted to append to non-started appender query-routing$' \
  | grep -v 'pod/hive-llap-.* impl.LlapDaemon: Cannot find CONTAINER_ID; LLAP tokens may grant access to subsequent instances of the cluster with the same name' \
  | grep -v 'pod/hive-llap-.* impl.QueryTracker: Ignore this\. Log line to interact with logger\. Query complete:' \
  | grep -v 'pod/hive-metastore-server-.*:   "CQ_ERROR_MESSAGE"' \
  | grep -v 'pod/hive-metastore-server-.*:   "CC_ERROR_MESSAGE"' \
  | grep -v 'pod/hive-metastore-server-.*:     "ERROR_MESSAGE" VARCHAR(2000)' \
  | grep -v 'pod/hive-metastore-server-.* rest.HMSCatalogServlet: Error processing REST request' \
  | grep -v 'pod/ozone-datanode-.* ERROR datanode.RunningDatanodeState: Error in executing end point task\.' \
  | grep -v 'pod/yarn-timelineserver-.* delegation.AbstractDelegationTokenSecretManager: ExpiredTokenRemover received java.lang.InterruptedException: sleep interrupted' \
  | grep -v "pod/\(hbase\|ozone\)-.* conditionevaluator.RangerScriptConditionEvaluator: failed to initialize condition 'accessed-after-expiry': script engine 'JavaScript' was not created" \
  | grep -v 'pod/hbase-master-.* procedure2\.RemoteProcedureDispatcher: DelayQueue for RemoteProcedureDispatcher is not empty when timed waiting elapsed\.' \
  | grep -v 'pod/ranger-admin-.*: could not find TAG ServiceDef..' \
  | grep -v 'pod/ranger-admin-.*: failed to load/create serviceType' \
  | grep -v 'pod/trino-coordinator-.*	io.airlift.discovery.client.CachingServiceSelector	Cannot connect to discovery server for refresh (trino/general)' \
  | grep -v 'pod/trino-worker-.*	io.airlift.discovery.client.CachingServiceSelector	Cannot connect to discovery server for refresh (trino/general)' \
  | grep -v 'pod/zookeeper-server-.* org.apache.zookeeper.server.quorum.Learner -- Unexpected exception, connectToLeader exceeded' \
  | grep -v 'pod/zookeeper-server-.* org.apache.zookeeper.server.quorum.Learner -- Failed connect to' \
  | grep -v 'pod/zookeeper-server-.* org.apache.zookeeper.server.quorum.QuorumCnxManager -- Exception while listening to address' \
  | grep -v 'pod/zookeeper-server-.* org.apache.zookeeper.server.NettyServerCnxnFactory -- Unsuccessful handshake with session 0x0'

# shellcheck disable=SC2181
if [ $? -eq 0 ]; then
  "${integration_dir}/divider.sh" "Errors are found"
  exit 1
fi

"${integration_dir}/divider.sh" "Finished fetching errors of all containers"
