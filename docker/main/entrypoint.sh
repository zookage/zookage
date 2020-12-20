#!/bin/bash
set -eu

if [ $# -eq 0 ]; then
  exec /bin/bash
fi

function wait_for_job() {
  kubectl wait "job/$1" --for="condition=complete" --timeout=3600s
}

function wait_for_rollout() {
  kubectl rollout status "$1"
}

function hdfs_mkdir() {
  local -r directory=$1
  until gohdfs mkdir -p "hdfs://${directory}" 2> /dev/null; do
    echo "Failed to mkdir ${directory}. Retrying..."
    sleep 1
  done
  until gohdfs chown "$2" "hdfs://${directory}" 2> /dev/null; do
    echo "Failed to chown ${directory}. Retrying..."
    sleep 1
  done
  until gohdfs chmod "$3" "hdfs://${directory}" 2> /dev/null; do
    echo "Failed to chmod ${directory}. Retrying..."
    sleep 1
  done
}

function is_hadoop2() {
  local -r hadoop_version=$("${HADOOP_HOME}/bin/hdfs" version | head -n 1)
  if [[ ${hadoop_version} == "Hadoop 2."* ]]; then
    return 0
  else
    return 1
  fi
}

readonly command=$1

if [ "${command}" == "hdfs-httpfs-prepare" ]; then
  if is_hadoop2; then
    # Use the root user.
    cp -R "${HADOOP_HOME}/share/hadoop/httpfs/tomcat" "${CATALINA_BASE}"
    chown -R httpfs:httpfs "${CATALINA_BASE}"
  fi
  exit 0
elif [ "${command}" == "hdfs-httpfs" ]; then
  if is_hadoop2; then
    exec "${HADOOP_HOME}/sbin/httpfs.sh" run
  else
    exec "${HADOOP_HOME}/bin/hdfs" httpfs
  fi
elif [ "${command}" == "hdfs-setup" ]; then
  hdfs_mkdir /apps hdfs:supergroup 755
  hdfs_mkdir /apps/tez tez:tez 755

  hdfs_mkdir /tmp hdfs:supergroup 1777
  hdfs_mkdir /tmp/logs yarn:yarn 1777

  hdfs_mkdir /user hdfs:supergroup 755
  hdfs_mkdir /user/sandbox sandbox:sandbox 700
  hdfs_mkdir /user/history mapred:hadoop 755
  hdfs_mkdir /user/hive hive:hive 751
  hdfs_mkdir /user/hive/warehouse hive:hive 1777
  exit 0
elif [ "${command}" == "wait-for-job" ]; then
  wait_for_job "$2"
  exit 0
elif [ "${command}" == "wait-for-rollout" ]; then
  wait_for_rollout "$2"
  exit 0
fi

exec "$@"
