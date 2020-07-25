#!/bin/bash
set -eu

if [ $# -eq 0 ]; then
  /bin/bash
  exit 0
fi

function await_path() {
  until ${HADOOP_HOME}/bin/hdfs dfs -ls $1; do
    sleep 1
  done
}

function await_http() {
  until curl $1; do
    sleep 1
  done
}

function is_hadoop2() {
  readonly hadoop_version=$(${HADOOP_HOME}/bin/hdfs version | head -n 1)
  if [[ ${hadoop_version} == "Hadoop 2."* ]]; then
    return 0
  else
    return 1
  fi
}

readonly command=$1

if [ "${command}" == "hdfs-namenode" ]; then
  ${HADOOP_HOME}/bin/hdfs namenode -format -force
  ${HADOOP_HOME}/bin/hdfs namenode
  exit 0
elif [ "${command}" == "hdfs-datanode" ]; then
  ${HADOOP_HOME}/bin/hdfs datanode
  exit 0
elif [ "${command}" == "hdfs-httpfs-prepare" ]; then
  if is_hadoop2; then
    # Use the root user.
    cp -R ${HADOOP_HOME}/share/hadoop/httpfs/tomcat ${CATALINA_BASE}
    chown -R httpfs:httpfs ${CATALINA_BASE}
  fi
  exit 0
elif [ "${command}" == "hdfs-httpfs" ]; then
  if is_hadoop2; then
    ${HADOOP_HOME}/sbin/httpfs.sh run
  else
    ${HADOOP_HOME}/bin/hdfs httpfs
  fi
  exit 0
elif [ "${command}" == "hdfs-path-ready" ]; then
  await_path $2
  exit 0
elif [ "${command}" == "hdfs-mkdir" ]; then
  await_path /
  ${HADOOP_HOME}/bin/hdfs dfs -mkdir -p hdfs:///tmp
  ${HADOOP_HOME}/bin/hdfs dfs -chmod 1777 hdfs:///tmp

  ${HADOOP_HOME}/bin/hdfs dfs -mkdir -p hdfs:///tmp/logs
  ${HADOOP_HOME}/bin/hdfs dfs -chown yarn:yarn hdfs:///tmp/logs
  ${HADOOP_HOME}/bin/hdfs dfs -chmod 1777 hdfs:///tmp/logs

  ${HADOOP_HOME}/bin/hdfs dfs -mkdir -p hdfs:///user

  ${HADOOP_HOME}/bin/hdfs dfs -mkdir -p hdfs:///user/sandbox
  ${HADOOP_HOME}/bin/hdfs dfs -chown sandbox:sandbox hdfs:///user/sandbox
  ${HADOOP_HOME}/bin/hdfs dfs -chmod 700 hdfs:///user/sandbox

  ${HADOOP_HOME}/bin/hdfs dfs -mkdir -p /user/history
  ${HADOOP_HOME}/bin/hdfs dfs -chown mapred:hadoop /user/history
  ${HADOOP_HOME}/bin/hdfs dfs -chmod -R 1777 /user/history

  ${HADOOP_HOME}/bin/hdfs dfs -mkdir -p hdfs:///user/hive
  ${HADOOP_HOME}/bin/hdfs dfs -chown hive:hive hdfs:///user/hive
  ${HADOOP_HOME}/bin/hdfs dfs -chmod 755 hdfs:///user/hive

  ${HADOOP_HOME}/bin/hdfs dfs -mkdir -p hdfs:///user/hive/warehouse
  ${HADOOP_HOME}/bin/hdfs dfs -chown hive:hive hdfs:///user/hive/warehouse
  ${HADOOP_HOME}/bin/hdfs dfs -chmod 1777 hdfs:///user/hive/warehouse
  exit 0
elif [ "${command}" == "yarn-resourcemanager" ]; then
  ${HADOOP_HOME}/bin/yarn resourcemanager
  exit 0
elif [ "${command}" == "yarn-nodemanager" ]; then
  ${HADOOP_HOME}/bin/yarn nodemanager
  exit 0
elif [ "${command}" == "yarn-timelineserver" ]; then
  ${HADOOP_HOME}/bin/yarn timelineserver
  exit 0
elif [ "${command}" == "mapreduce-historyserver" ]; then
  ${HADOOP_HOME}/bin/mapred historyserver
  exit 0
elif [ "${command}" == "hive-metastore-init-schema" ]; then
  rm -rf /mnt/hive/metastore
  ${HIVE_HOME}/bin/schematool -initSchema -dbType derby
  exit 0
elif [ "${command}" == "hive-metastore" ]; then
  ${HIVE_HOME}/bin/hive --service metastore
  exit 0
elif [ "${command}" == "hive-hiveserver2" ]; then
  ${HIVE_HOME}/bin/hiveserver2
  exit 0
elif [ "${command}" == "http-ready" ]; then
  await_http $2
  exit 0
fi

exec "$@"
