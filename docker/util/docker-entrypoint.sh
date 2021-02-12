#!/bin/bash
set -eu

if [ $# -eq 0 ]; then
  exec /bin/bash
fi

readonly command=$1

if [ "${command}" == "wait-for-job" ]; then
  exec kubectl wait "job/$2" --for="condition=complete" --timeout=3600s
elif [ "${command}" == "wait-for-rollout" ]; then
  exec kubectl rollout status "$2"
elif [ "${command}" == "wait-for-dns" ]; then
  hostname=$2
  until nslookup "${hostname}"; do
    echo "Failed to resolve ${hostname}"
    sleep 1
  done
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
