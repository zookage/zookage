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

"${integration_dir}/divider.sh" "Start fetching warnings of all containers"

# shellcheck disable=SC2016
"${base_dir}/bin/logs" | grep WARN \
  | grep -v 'WARNING: .* does not exist. Creating.' \
  | grep -v 'pod/hdfs-namenode-.* hdfs.DFSUtilClient: Namenode for .* remains unresolved for ID' \
  | grep -v 'pod/hdfs-namenode-.* ha.HealthMonitor: Transport-level exception trying to monitor health of NameNode' \
  | grep -v 'pod/hdfs-namenode-.* ha.ActiveStandbyElector: Ignoring stale result from old client with sessionId' \
  | grep -v 'pod/hdfs-namenode-.* ha.EditLogTailer: Edit log tailer interrupted' \
  | grep -v 'pod/hdfs-namenode-.* blockmanagement.BlockPlacementPolicy: Failed to place enough replicas' \
  | grep -v 'pod/hdfs-namenode-.* protocol.BlockStoragePolicy: Failed to place enough replicas' \
  | grep -v 'pod/hdfs-datanode-.* datanode.DataNode: Problem connecting to server:' \
  | grep -v 'pod/hdfs-datanode-.* hdfs.DFSUtilClient: Namenode for zookage remains unresolved for ID' \
  | grep -v 'pod/hdfs-datanode-.* impl.FsDatasetImpl: dfsUsed file missing in' \
  | grep -v 'pod/hdfs-datanode-.* ipc.Client: Address change detected' \
  | grep -v 'pod/hdfs-httpfs-.* hdfs.DFSUtilClient: Namenode for zookage remains unresolved for ID' \
  | grep -v 'pod/hdfs-httpfs-.* ipc.Client: Address change detected' \
  | grep -v 'pod/hdfs-httpfs-.* ipc.Client: Exception when handle ConnectionFailure: Invalid host name:' \
  | grep -v 'pod/hdfs-httpfs-.* impl.MetricsSystemImpl: httpfs metrics system already initialized!' \
  | grep -v 'pod/hdfs-httpfs-.*: WARNING: An illegal reflective access operation has occurred' \
  | grep -v 'pod/hdfs-httpfs-.*: WARNING: Illegal reflective access by .*' \
  | grep -v 'pod/hdfs-httpfs-.*: WARNING: Please consider reporting this to the maintainers of .*' \
  | grep -v 'pod/hdfs-httpfs-.*: WARNING: Use --illegal-access=warn to enable warnings of further illegal reflective access operations' \
  | grep -v 'pod/hdfs-httpfs-.*: WARNING: All illegal access operations will be denied in a future release' \
  | grep -v 'pod/hdfs-journalnode-.* common.Storage: Storage directory .* does not exist' \
  | grep -v 'pod/hdfs-journalnode-.* server.JournalNodeSyncer: Journal at .* has no edit logs' \
  | grep -v 'pod/yarn-nodemanager-.* nodemanager.DefaultContainerExecutor: Exit code from container' \
  | grep -v "pod/yarn-nodemanager-.* containermanager.ContainerManagerImpl: couldn't find container" \
  | grep -v "pod/yarn-nodemanager-.* containermanager.ContainerManagerImpl: couldn't find app" \
  | grep -v 'pod/yarn-nodemanager-.* nodemanager.DefaultContainerExecutor: delete returned false for path' \
  | grep -v 'pod/yarn-resourcemanager-.* ha.ActiveStandbyElector: Ignoring stale result from old client with sessionId' \
  | grep -v 'pod/yarn-resourcemanager-.* zookeeper.ClientCnxn: Session 0x0 .* Attempting reconnect except it is a SessionExpiredException\.' \
  | grep -v 'pod/hive-hiveserver2-.* conf.HiveConf: HiveConf of name hive.cluster.id does not exist' \
  | grep -v 'pod/hive-hiveserver2-.* exec.FunctionRegistry: UDF Class org.apache.hadoop.hive.ql.udf.generic.GenericUDFToJson does not have description\.' \
  | grep -v "pod/hive-hiveserver2-.* tez.TezConfigurationFactory: Skip adding 'tez.application.tags' to dagConf, as it's an AM scoped property" \
  | grep -v 'pod/hive-llap-.* impl.LlapDaemon: NodeManager host/port not found in environment\. Values retrieved: host=null, port=null' \
  | grep -v 'pod/hive-llap-.* conf.HiveConf: HiveConf of name hive.cluster.id does not exist' \
  | grep -v 'pod/hive-llap-.* exec.FunctionRegistry: UDF Class org.apache.hadoop.hive.ql.udf.generic.GenericUDFToJson does not have description\.' \
  | grep -v 'pod/hive-llap-.* objectinspector.StandardStructObjectInspector: Trying to access' \
  | grep -v 'pod/hive-llap-.* objectinspector.StandardStructObjectInspector: ignoring similar errors\.' \
  | grep -v 'pod/hive-llap-.* impl.LlapTaskReporter: Exiting TaskReporter thread with pending queue size=' \
  `# Needs TX` \
  | grep -v 'pod/hive-hiveserver2-.* metadata.Hive: Cannot get a table snapshot for' \
  | grep -v 'pod/hive-metastore-server-.*: WARNING: Unable to create a system terminal' \
  | grep -v 'pod/hive-metastore-server-.* metastore.ServletSecurity: Servlet security is disabled for org.apache.iceberg.rest.HMSCatalogServlet@.*' \
  | grep -v 'pod/postgres-database-.* WARNING:  there is no transaction in progress' \
  | grep -v 'pod/zookeeper-server-.* org.eclipse.jetty.server.handler.ContextHandler .* contextPath ends with' \
  | grep -v 'pod/zookeeper-server-.* org.eclipse.jetty.server.handler.ContextHandler -- Empty contextPath' \
  | grep -v 'pod/zookeeper-server-.* org.eclipse.jetty.security.SecurityHandler .* has uncovered http methods for path:' \
  | grep -v 'pod/zookeeper-server-.* org.apache.zookeeper.server.quorum.QuorumCnxManager -- Cannot open channel to' \
  | grep -v 'pod/zookeeper-server-.* org.apache.zookeeper.server.quorum.QuorumCnxManager -- Exception when using channel:' \
  | grep -v 'pod/zookeeper-server-.* org.apache.zookeeper.server.quorum.QuorumCnxManager -- Connection broken for id' \
  | grep -v 'pod/zookeeper-server-.* org.apache.zookeeper.server.quorum.QuorumCnxManager -- Interrupting SendWorker thread from RecvWorker\.' \
  | grep -v 'pod/zookeeper-server-.* org.apache.zookeeper.server.quorum.QuorumCnxManager -- Send worker leaving thread id' \
  | grep -v 'pod/zookeeper-server-.* org.apache.zookeeper.server.quorum.Learner -- Unexpected exception' \
  | grep -v 'pod/zookeeper-server-.* org.apache.zookeeper.server.quorum.Learner -- Exception when following the leader' \
  | grep -v 'pod/zookeeper-server-.* org.apache.zookeeper.server.quorum.QuorumPeer -- PeerState set to LOOKING' \
  | grep -v 'pod/zookeeper-server-.* org.apache.zookeeper.server.quorum.Learner -- Got zxid' \
  | grep -v 'pod/zookeeper-server-.* org.apache.zookeeper.server.NIOServerCnxn -- Close of session 0x0' \
  | grep -v 'pod/zookeeper-server-.* org.apache.zookeeper.server.ZKDatabase -- Unable to find proposals from txnlog for zxid: 0x0' \
  `# Initialization` \
  | grep -v 'pod/hbase-master-.* hdfs.DataStreamer: DataStreamer Exception' \
  | grep -v 'pod/hbase-master-.* region.MasterRegion: failed to clean up initializing flag' \
  | grep -v 'pod/hbase-master-.* assignment.AssignmentManager: No servers available; cannot place' \
  `# Initialization` \
  | grep -v 'pod/\(hbase\|ozone\)-.* conditionevaluator.RangerScriptConditionEvaluator: initScriptEngineCreator(): failed to create engine using plugin-class-loader by creator org.apache.ranger.plugin.util.GraalScriptEngineCreator' \
  | grep -v 'pod/\(hbase\|ozone\)-.* conditionevaluator.RangerScriptConditionEvaluator: initScriptEngineCreator(): failed to create engine using plugin-class-loader by creator org.apache.ranger.plugin.util.JavaScriptEngineCreator' \
  | grep -v 'pod/\(hbase\|ozone\)-.* conditionevaluator.RangerScriptConditionEvaluator: createScriptEngine(serviceType=tag): failed to create script engine' \
  | grep -v 'pod/ozone-.*: STARTUP_MSG:' \
  | grep -v 'pod/ozone-recon-.* scm.ReconPipelineManager: Pipeline PipelineID=.* already exists in Recon pipeline metadata' \
  | grep -v 'pod/ozone-datanode-.* statemachine.EndpointStateMachine: Unable to communicate to Recon server at .* for past 0 seconds\.' \
  | grep -v 'pod/ozone-scm-.* balancer.ContainerBalancer: Could not find persisted configuration for ContainerBalancer when checking if ContainerBalancer should run. ContainerBalancer should not run now.' \
  | grep -v 'pod/ozone-scm-.* ha.SequenceIdGenerator: Failed to allocate a batch for localId, expected lastId is 0, actual lastId is' \
  | grep -v 'pod/ozone-scm-.* scm.SCMCommonPlacementPolicy: Unable to find enough nodes that meet the space requirement of' \
  `# Permission` \
  | grep -v 'pod/ozone-om-.* helpers.OzoneAclUtil: Failed to get primary group from user .*' \
  `# HDDS-8395` \
  | grep -v 'ozone-s3g-.* impl.MetricsSystemImpl: S3Gateway metrics system already initialized!' \
  | grep -v 'pod/ranger-admin-.*DefaultJoranConfigurator@.*logback.xml.*' \
  | grep -v "pod/ranger-admin-.* WARNING: Config 'ranger.keystore.file' or 'ranger.service.https.attrib.keystore.file' is not found or contains blank value" \
  | grep -v "pod/ranger-admin-.* WARNING: Config 'ranger.truststore.file' is not found or contains blank value!" \
  | grep -v "pod/ranger-admin-.* WARNING: A context path must either be an empty string or start with a '/' and do not end with a '/'. The path \\[/\\] does not meet these criteria and has been changed to \\[\\]" \
  | grep -v 'pod/ranger-admin-.* WARNING: The following warnings have been detected with resource and/or provider classes:' \
  | grep -v 'pod/ranger-admin-.* WARNING: A HTTP GET method, public void org.apache.ranger.rest.RoleREST.getRolesInJson.* MUST return a non-void type\.' \
  | grep -v 'pod/ranger-admin-.* WARNING: A HTTP GET method, public void org.apache.ranger.rest.ServiceREST.getPoliciesInExcel.* MUST return a non-void type\.' \
  | grep -v 'pod/ranger-admin-.* WARNING: A HTTP GET method, public void org.apache.ranger.rest.ServiceREST.getPoliciesInCsv.* MUST return a non-void type\.' \
  | grep -v 'pod/ranger-admin-.* WARNING: A HTTP GET method, public void org.apache.ranger.rest.ServiceREST.getPoliciesInJson.* MUST return a non-void type\.' \
  | grep -v 'pod/ranger-usersync-.*DefaultJoranConfigurator@.*logback.xml.*' \
  | grep -v 'pod/spark-historyserver-.* WARNING: Using incubator modules: jdk.incubator.vector' \
  | grep -v 'pod/trino-coordinator-.* WARNING: Using incubator modules: jdk.incubator.vector' \
  | grep -v 'pod/trino-coordinator-.* # WARNING: Unable to attach Serviceability Agent\.' \
  | grep -v 'pod/trino-coordinator-.*io.trino.memory.RemoteNodeMemory.*Memory info update request to http://.* has not returned in .*' \
  | grep -v 'pod/trino-coordinator-.*io.trino.memory.RemoteNodeMemory.*Error fetching memory info from http://.* returned status 503' \
  | grep -v 'pod/trino-worker-.* WARNING: Using incubator modules: jdk.incubator.vector' \
  | grep -v 'pod/trino-worker-.* # WARNING: Unable to attach Serviceability Agent\.' \
  | grep -v 'pod/trino-worker-.*io.trino.node.AnnounceNodeAnnouncer.*Failed to announce node state to http://.*: 503'


# shellcheck disable=SC2181
if [ $? -eq 0 ]; then
  "${integration_dir}/divider.sh" "Warnings are found"
  exit 1
fi

"${integration_dir}/divider.sh" "Finished fetching warnings of all containers"
