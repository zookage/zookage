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

readonly command=$1

if [ "${command}" == "wait-for-job" ]; then
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
