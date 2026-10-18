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

retry_command() {
  description=$1
  shift
  until "$@" 2> /dev/null; do
    echo "Failed to ${description}. Retrying..."
    sleep 1
  done
}

webhdfs_request() {
  method=$1
  path=$2
  query=$3

  curl \
    --fail \
    --silent \
    --show-error \
    --output /dev/null \
    --request "${method}" \
    --header 'Content-Length: 0' \
    "http://hdfs-httpfs:14000/webhdfs/v1${path}?user.name=${HADOOP_USER_NAME:-hdfs}&${query}"
}

hdfs_mkdir_webhdfs() {
  directory=$1
  owner_group=$2
  mode=$3
  owner=${owner_group%%:*}
  group=${owner_group#*:}

  retry_command "mkdir ${directory}" \
    webhdfs_request PUT "${directory}" "op=MKDIRS&permission=${mode}"
  retry_command "set owner on ${directory}" \
    webhdfs_request PUT "${directory}" "op=SETOWNER&owner=${owner}&group=${group}"
  retry_command "set permission on ${directory}" \
    webhdfs_request PUT "${directory}" "op=SETPERMISSION&permission=${mode}"
}

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
  hdfs_mkdir_webhdfs "$2" "$3" "$4"
  exit 0
fi

exec "$@"
