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

if [ $# -eq 0 ]; then
  exec /bin/bash
fi

readonly command=$1

if [ "${command}" == "wait-for-job" ]; then
  until kubectl wait "job/$2" --for="condition=complete" --timeout=1s; do :; done
  exit 0
elif [ "${command}" == "wait-for-rollout" ]; then
  until kubectl rollout status "$2" --timeout=1s; do :; done
  exit 0
elif [ "${command}" == "wait-for-dns" ]; then
  fqdn=$(hostname --fqdn)
  until host "${fqdn}"; do
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
