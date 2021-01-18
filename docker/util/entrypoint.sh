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
elif [ "${command}" == "wait-for-job" ]; then
  wait_for_job "$2"
  exit 0
elif [ "${command}" == "wait-for-rollout" ]; then
  wait_for_rollout "$2"
  exit 0
elif [ "${command}" == "hdfs-mkdir" ]; then
  readonly directory=$2
  readonly owner=$3
  readonly mode=$4
  until gohdfs mkdir -p "hdfs://${directory}" 2> /dev/null; do
    echo "Failed to mkdir ${directory}. Retrying..."
    sleep 1
  done
  until gohdfs chown "$owner" "hdfs://${directory}" 2> /dev/null; do
    echo "Failed to chown ${directory}. Retrying..."
    sleep 1
  done
  until gohdfs chmod "$mode" "hdfs://${directory}" 2> /dev/null; do
    echo "Failed to chmod ${directory}. Retrying..."
    sleep 1
  done
  exit 0
fi

exec "$@"
