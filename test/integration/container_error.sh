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

"${integration_dir}/divider.sh" "Start fetching errors of all containers"

# shellcheck disable=SC2016
"${base_dir}/bin/logs" \
  | awk -v auth="${ZOOKAGE_TEST_MODE:-}" '
    function flushCuratorErrors() {
      if (curatorError != "") print curatorError
      if (listenerError != "") print listenerError
      curatorError = listenerError = curatorPod = curatorKind = ""
    }
    # Hadoop 3.4.1 tries to parse the root of each LLAP token cache as a token.
    # Suppress only the startup exception identified by its stack trace.
    {
      if (curatorError != "") {
        if ($1 != curatorPod) flushCuratorErrors()
        else if ($0 ~ / ERROR /) {
          if (listenerError == "" &&
              /listen\.MappingListenerManager: Listener \(org\.apache\.curator\.framework\.recipes\.cache\.CuratorCacheListenerBuilderImpl\$2@[0-9a-f]+\) threw an exception$/) {
            listenerError = $0
            next
          }
          flushCuratorErrors()
        } else if (listenerError != "" && /Caused by:/) {
          if (curatorKind == "key") expectedCause = /Caused by: java\.io\.EOFException$/
          else expectedCause = /Caused by: java\.io\.IOException: Unknown version of delegation token 49$/
          max = curatorPod ~ /^pod\/hive-llap-/ ? 2 : 1
          if (!expectedCause || ++rootEvents[curatorPod SUBSEP curatorKind] > max) flushCuratorErrors()
          else curatorError = listenerError = curatorPod = curatorKind = ""
        }
      }
      if (auth == "auth" && $0 ~ / ERROR / &&
          ($1 ~ /^pod\/hive-hiveserver2-[^:]+:$/ || $1 ~ /^pod\/hive-llap-[0-9]+:$/) &&
          /delegation\.ZKDelegationTokenSecretManager: Error while processing Curator (keyCacheListener|tokenCacheListener) NODE_CREATED \/ NODE_CHANGED event$/) {
        curatorError = $0
        curatorPod = $1
        curatorKind = /keyCacheListener/ ? "key" : "token"
        next
      }
      print
    }
    END { flushCuratorErrors() }
  ' \
  | grep ' ERROR ' \
  | awk -v auth="${ZOOKAGE_TEST_MODE:-}" '
    # Hive registers the query-routing appender before starting it at startup.
    $1 ~ /^pod\/hive-hiveserver2-[^:]+:$/ &&
        / Log4j2-TF-[0-9]+-AsyncLogger\[AsyncContext@[0-9a-f]+\]-[0-9]+ ERROR Attempted to append to non-started appender query-routing$/ {
      if (++seen[$1 SUBSEP "query-routing"] == 1) next
    }
    auth == "auth" && $1 ~ /^pod\/ozone-(datanode|om|recon|scm)-[0-9]+:$/ && /\[main\] ERROR/ {
      kind = ""
      if (/CertificateClient: Default certificate serial id is not set\. Can.t locate the default certificate for this client\.$/) kind = "serial"
      else if ($1 ~ /^pod\/ozone-scm-/ && /keys\.KeyStorage: Failed to read the public key\.$/) kind = "key"
      else if (/utils\.CertificateSignRequest: Invalid domain ozone-.*\.zookage\.svc\.cluster\.local$/) kind = "csr"
      else if (/utils\.SelfSignedCertificate: Invalid domain ozone-.*\.zookage\.svc\.cluster\.local$/) kind = "self"
      if (kind != "" && ++seen[$1 SUBSEP kind] == 1) next
    }
    { print }
  ' \
  | grep -v 'pod/hive-llap-.* impl.LlapDaemon: Cannot find CONTAINER_ID; LLAP tokens may grant access to subsequent instances of the cluster with the same name' \
  | grep -v 'pod/hive-llap-.* impl.QueryTracker: Ignore this\. Log line to interact with logger\. Query complete:' \
  | grep -v 'pod/hive-metastore-server-.*:   "CQ_ERROR_MESSAGE"' \
  | grep -v 'pod/hive-metastore-server-.*:   "CC_ERROR_MESSAGE"' \
  | grep -v 'pod/hive-metastore-server-.*:     "ERROR_MESSAGE" VARCHAR(2000)' \
  | grep -v 'pod/hive-metastore-server-.* rest.HMSCatalogServlet: Error processing REST request' \
  | grep -v 'pod/ozone-datanode-.* ERROR datanode.RunningDatanodeState: Error in executing end point task\.' \
  | grep -v 'pod/yarn-timelineserver-.* delegation.AbstractDelegationTokenSecretManager: ExpiredTokenRemover received java.lang.InterruptedException: sleep interrupted' \
  | grep -v "pod/\(hbase\|ozone\)-.* conditionevaluator.RangerScriptConditionEvaluator: failed to initialize condition 'accessed-after-expiry': script engine 'JavaScript' was not created" \
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
