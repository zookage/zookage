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

"${integration_dir}/divider.sh" "Start fetching warnings of all containers"

# shellcheck disable=SC2016
"${base_dir}/bin/logs" | grep WARN \
  | grep -v 'WARNING: .* does not exist. Creating.' \
  | grep -v 'pod/hdfs-namenode-.* conf.Configuration: No unit for' \
  | grep -v 'pod/hdfs-namenode-.* hdfs.DFSUtilClient: Namenode for .* remains unresolved for ID' \
  | grep -v 'pod/hdfs-namenode-.* ha.HealthMonitor: Transport-level exception trying to monitor health of NameNode' \
  | grep -v 'pod/hdfs-namenode-.* ha.ActiveStandbyElector: Ignoring stale result from old client with sessionId' \
  | grep -v 'pod/hdfs-namenode-.* ha.EditLogTailer: Edit log tailer interrupted' \
  | grep -v 'pod/hdfs-datanode-.* conf.Configuration: No unit for' \
  | grep -v 'pod/hdfs-datanode-.* datanode.DataNode: Slow BlockReceiver write data to disk cost' \
  | grep -v 'pod/hdfs-datanode-.* datanode.DataNode: Slow PacketResponder send ack to upstream took' \
  | grep -v 'pod/hdfs-datanode-.* impl.FsDatasetImpl: Lock held time above threshold' \
  | grep -v 'pod/hdfs-datanode-.* datanode.DataNode: Slow BlockReceiver write packet to mirror took' \
  | grep -v 'pod/hdfs-datanode-.* datanode.DataNode: Slow flushOrSync took' \
  | grep -v 'pod/hdfs-datanode-.* datanode.DataNode: Problem connecting to server:' \
  | grep -v 'pod/hdfs-datanode-.* ipc.Client: Address change detecte' \
  `# HDFS-16347` \
  | grep -v 'pod/hdfs-datanode-.* datanode.DirectoryScanner: dfs.datanode.directoryscan.throttle.limit.ms.per.sec set to value above 1000 ms/sec' \
  | grep -v 'pod/hdfs-httpfs-.* log4j:WARN' \
  | grep -v 'pod/hdfs-httpfs-.* \[SetPropertiesRule\]{Server/Service/Engine/Host} Setting property' \
  | grep -v 'pod/hdfs-httpfs-.* Creation of SecureRandom instance for session ID generation using \[SHA1PRNG\] took' \
  | grep -v 'pod/hdfs-journalnode-.* common.Storage: Storage directory .* does not exist' \
  | grep -v 'pod/hdfs-journalnode-.* server.JournalNodeSyncer: Journal at .* has no edit logs' \
  | grep -v 'pod/yarn-nodemanager-.* nodemanager.DefaultContainerExecutor: Exit code from container' \
  | grep -v "pod/yarn-nodemanager-.* containermanager.ContainerManagerImpl: couldn't find container" \
  | grep -v "pod/yarn-nodemanager-.* containermanager.ContainerManagerImpl: couldn't find app" \
  | grep -v 'pod/yarn-nodemanager-.* nodemanager.DefaultContainerExecutor: delete returned false for path' \
  | grep -v 'pod/tez-ui-.* Creation of SecureRandom instance for session ID generation using \[SHA1PRNG\] took' \
  | grep -v 'pod/hive-metastore-.* nodemanager.DefaultContainerExecutor: Exit code from' \
  | grep -v 'pod/hive-metastore-.* Failed to create directory: /home/hive/.beeline' \
  | grep -v 'pod/hive-metastore-.* util.DriverDataSource: Registered driver with driverClassName=org.apache.derby.jdbc.EmbeddedDriver' \
  | grep -v 'pod/hive-metastore-.* metastore.ObjectStore: Failed to get database' \
  | grep -v 'pod/hive-hiveserver2-.* session.SessionState: METASTORE_FILTER_HOOK will be ignored' \
  | grep -v 'pod/hive-hiveserver2-.* Hive-on-MR is deprecated in Hive 2 and may not be available in the future versions.' \
  | grep -v 'pod/hive-hiveserver2-.* server.HiveServer2: No policy provider found, skip creating PrivilegeSynchonizer' \
  | grep -v 'pod/hive-hiveserver2-.* mapreduce.JobResourceUploader: Hadoop command-line option parsing not performed' \
  | grep -v 'pod/hive-hiveserver2-.* mapreduce.Counters: Group org.apache.hadoop.mapred.Task$Counter is deprecated' \
  `# Needs TX` \
  | grep -v 'pod/hive-hiveserver2-.* metadata.Hive: Cannot get a table snapshot for' \
  `# https://github.com/apache/datasketches-hive/pull/66` \
  | grep -v 'pod/hive-hiveserver2-.* exec.FunctionRegistry: UDF Class org.apache.hive.org.apache.datasketches.hive' \
  `# HIVE-27120` \
  | grep -v 'pod/hive-hiveserver2-.* conf.HiveConf: HiveConf of name hive.internal.ss.authz.settings.applied.marker does not exist' \
  | grep -v 'pod/zookeeper-server-.* org.eclipse.jetty.server.handler.ContextHandler .* contextPath ends with' \
  | grep -v 'pod/zookeeper-server-.* org.eclipse.jetty.server.handler.ContextHandler -- Empty contextPath' \
  | grep -v 'pod/zookeeper-server-.* org.eclipse.jetty.security.SecurityHandler .* has uncovered http methods for path:' \
  | grep -v 'pod/zookeeper-server-.* org.apache.zookeeper.server.quorum.QuorumCnxManager -- Cannot open channel to' \
  | grep -v 'pod/zookeeper-server-.* org.apache.zookeeper.server.quorum.Learner -- Unexpected exception' \
  | grep -v 'pod/zookeeper-server-.* org.apache.zookeeper.server.quorum.Learner -- Exception when following the leader' \
  | grep -v 'pod/zookeeper-server-.* org.apache.zookeeper.server.quorum.QuorumPeer -- PeerState set to LOOKING' \
  | grep -v 'pod/zookeeper-server-.* org.apache.zookeeper.server.quorum.Learner -- Got zxid' \
  `# Initialization` \
  | grep -v 'pod/hbase-master-.* region.MasterRegion: failed to clean up initializing flag' \
  | grep -v 'pod/hbase-master-.* assignment.AssignmentManager: No servers available; cannot place' \
  `# Initialization` \
  | grep -v 'pod/ozone-.*: STARTUP_MSG:' \
  | grep -v 'pod/ozone-recon-.* scm.ReconPipelineManager: Pipeline PipelineID=.* already exists in Recon pipeline metadata' \
  | grep -v 'pod/ozone-scm-.* balancer.ContainerBalancer: Could not find persisted configuration for ContainerBalancer when checking if ContainerBalancer should run. ContainerBalancer should not run now.' \
  | grep -v 'pod/ozone-scm-.* ha.SequenceIdGenerator: Failed to allocate a batch for localId, expected lastId is 0, actual lastId is' \
  | grep -v 'pod/ozone-scm-.* scm.SCMCommonPlacementPolicy: Unable to find enough nodes that meet the space requirement of' \
  `# Permission` \
  | grep -v 'pod/ozone-om-.* helpers.OzoneAclUtil: Failed to get primary group from user .*' \
  `# HDDS-8395` \
  | grep -v 'ozone-s3g-.* impl.MetricsSystemImpl: S3Gateway metrics system already initialized!' \
  `# Container security` \
  | grep -v 'pod/trino-coordinator-.* # WARNING: Unable to attach Serviceability Agent' \
  `# Jersey warning` \
  | grep -v 'pod/trino-coordinator-.* registered in SERVER runtime does not implement any provider interfaces applicable' \
  | grep -v 'pod/trino-coordinator-.* of type io.trino.execution.resourcegroups.ResourceGroupManager<?>' \
  `# https://github.com/trinodb/trino/pull/18374` \
  | grep -v 'pod/trino-coordinator-.* getRoot in io.trino.server.ui.WebUiStaticResource contains empty path annotation' \
  `# Container security` \
  | grep -v 'pod/trino-worker-.* # WARNING: Unable to attach Serviceability Agent' \
  `# Jersey warning` \
  | grep -v 'pod/trino-worker-.* registered in SERVER runtime does not implement any provider interfaces applicable' \
  || true

"${integration_dir}/divider.sh" "Finished fetching warnings of all containers"
