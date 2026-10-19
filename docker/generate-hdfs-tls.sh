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

if [[ $# -ne 0 ]]; then
  echo "Usage: $0" >&2
  exit 1
fi

readonly base_dir=$(cd "$(dirname "$0")"; pwd)

# Keep the sample HDFS service and replica names on its service certificate.
san='dns:hdfs-namenode,dns:hdfs-namenode.zookage.svc.cluster.local,dns:localhost,ip:127.0.0.1'
for component in namenode datanode journalnode; do
  replicas=3
  if [[ ${component} == namenode ]]; then
    replicas=2
  fi
  for ((index = 0; index < replicas; index++)); do
    pod_name="hdfs-${component}-${index}"
    hostname="${pod_name}.hdfs-${component}"
    san+=",dns:${pod_name},dns:${hostname},dns:${hostname}.zookage.svc.cluster.local"
  done
done

exec "${base_dir}/generate-tls.sh" hdfs "${san}"
