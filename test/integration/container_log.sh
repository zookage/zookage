#!/bin/bash
set -eu

readonly integration_dir=$(cd "$(dirname "$0")"; pwd)
readonly base_dir=$(dirname "$(dirname "${integration_dir}")")

check_errors () {
  ! "${base_dir}/bin/logs" | grep ERROR \
    | grep -v 'pod/hive-hiveserver2-.* metadata.Hive: .*mofu_tez not found' \
    | grep -v 'pod/hive-hiveserver2-.* metadata.Hive: .*mofu_mr not found'
}

check_warnings () {
  # shellcheck disable=SC2016
  ! "${base_dir}/bin/logs" | grep WARN \
    | grep -v 'WARNING: .* does not exist. Creating.' \
    | grep -v 'pod/hdfs-namenode-.* conf.Configuration: No unit for' \
    | grep -v 'pod/hdfs-namenode-.* hdfs.DFSUtilClient: Namenode for null remains unresolved for ID null' \
    | grep -v 'pod/hdfs-datanode-.* conf.Configuration: No unit for' \
    | grep -v 'pod/hdfs-datanode-.* datanode.DataNode: Slow BlockReceiver write data to disk cost' \
    | grep -v 'pod/hdfs-datanode-.* datanode.DataNode: Slow PacketResponder send ack to upstream took' \
    | grep -v 'pod/hdfs-datanode-.* impl.FsDatasetImpl: Lock held time above threshold' \
    | grep -v 'pod/hdfs-datanode-.* datanode.DataNode: Slow BlockReceiver write packet to mirror took' \
    | grep -v 'pod/hdfs-datanode-.* datanode.DataNode: Slow flushOrSync took' \
    | grep -v 'pod/hdfs-httpfs-.* log4j:WARN' \
    | grep -v 'pod/hdfs-httpfs-.* \[SetPropertiesRule\]{Server/Service/Engine/Host} Setting property' \
    | grep -v 'pod/hdfs-httpfs-.* Creation of SecureRandom instance for session ID generation using \[SHA1PRNG\] took' \
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
    | grep -v 'pod/hive-hiveserver2-.* mapreduce.Counters: Group org.apache.hadoop.mapred.Task$Counter is deprecated'
}

"${integration_dir}/divider.sh" "Start fetching errors of all containers"
check_errors
"${integration_dir}/divider.sh" "Finished fetching errors of all containers"
echo "No error is found."

"${integration_dir}/divider.sh" "Start fetching warnings of all containers"
check_warnings
"${integration_dir}/divider.sh" "Finished fetching warnings of all containers"
echo "No warning is found."
