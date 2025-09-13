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
  | grep -v 'pod/hdfs-httpfs-.* impl.MetricsSystemImpl: httpfs metrics system already initialized!' \
  | grep -v 'pod/hdfs-journalnode-.* common.Storage: Storage directory .* does not exist' \
  | grep -v 'pod/hdfs-journalnode-.* server.JournalNodeSyncer: Journal at .* has no edit logs' \
  | grep -v 'pod/yarn-nodemanager-.* nodemanager.DefaultContainerExecutor: Exit code from container' \
  | grep -v "pod/yarn-nodemanager-.* containermanager.ContainerManagerImpl: couldn't find container" \
  | grep -v "pod/yarn-nodemanager-.* containermanager.ContainerManagerImpl: couldn't find app" \
  | grep -v 'pod/yarn-nodemanager-.* nodemanager.DefaultContainerExecutor: delete returned false for path' \
  | grep -v 'pod/hive-hiveserver2-.* conf.HiveConf: HiveConf of name hive.cluster.id does not exist' \
  | grep -v "pod/hive-hiveserver2-.* tez.TezConfigurationFactory: Skip adding 'tez.application.tags' to dagConf, as it's an AM scoped property" \
  `# Needs TX` \
  | grep -v 'pod/hive-hiveserver2-.* metadata.Hive: Cannot get a table snapshot for' \
  | grep -v 'pod/iam-directory-server-.* entry.DefaultAttribute: ERR_13207_VALUE_ALREADY_EXISTS' \
  | grep -v "pod/iam-directory-server-.* core.DefaultDirectoryService: You didn't change the admin password of directory service instance 'default'.  Please update the admin password as soon as possible to prevent a possible security breach" \
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
  | grep -v 'pod/trino-coordinator-.* WARNING: Using incubator modules: jdk.incubator.vector' \
  | grep -v 'pod/trino-worker-.* WARNING: Using incubator modules: jdk.incubator.vector'


# shellcheck disable=SC2181
if [ $? -eq 0 ]; then
  "${integration_dir}/divider.sh" "Warnings are found"
  exit 1
fi

"${integration_dir}/divider.sh" "Finished fetching warnings of all containers"
