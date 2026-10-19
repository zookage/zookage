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

readonly base_dir=$(cd "$(dirname "$0")"; pwd)
readonly repo_dir=$(cd "${base_dir}/.."; pwd)
readonly util_image=${ZOOKAGE_UTIL_IMAGE:-zookage/zookage-util:experimental}
readonly temp_dir=$(mktemp -d)
trap 'rm -rf "${temp_dir}"' EXIT

# A shared self-signed certificate and password for the sample cluster.
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

docker run --rm -i --network=none --read-only --tmpfs /tmp \
  --user "$(id -u):$(id -g)" \
  --mount "type=bind,source=${temp_dir},target=/output" \
  --env "HDFS_TLS_SAN=${san}" \
  "${util_image}" /bin/bash -eu <<'SCRIPT'
  keytool -genkeypair \
    -alias hdfs -keyalg RSA -keysize 2048 -sigalg SHA256withRSA \
    -dname "CN=hdfs-namenode,O=ZooKage" -validity 3650 \
    -ext "SAN=${HDFS_TLS_SAN}" -ext "EKU=serverAuth" \
    -keystore /output/hdfs.jks -storetype JKS \
    -storepass zookage -keypass zookage
  keytool -exportcert -rfc -alias hdfs \
    -keystore /output/hdfs.jks -storepass zookage \
    -file /output/hdfs-ca.crt
  keytool -importcert -noprompt -alias hdfs \
    -file /output/hdfs-ca.crt \
    -keystore /output/hdfs-truststore.jks -storetype JKS \
    -storepass zookage
SCRIPT

# keytool wraps PEM data with CRLF; keep the checked-in certificate using LF.
tr -d '\r' < "${temp_dir}/hdfs-ca.crt" > "${temp_dir}/hdfs-ca.pem"
install -m 0600 "${temp_dir}/hdfs.jks" "${repo_dir}/kubernetes/base/common/secret/hdfs/hdfs.jks"
install -m 0644 "${temp_dir}/hdfs-truststore.jks" "${repo_dir}/kubernetes/base/common/config/hdfs/hdfs-truststore.jks"
install -m 0644 "${temp_dir}/hdfs-ca.pem" "${repo_dir}/kubernetes/base/common/config/hdfs/hdfs-ca.crt"
