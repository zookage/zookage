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
readonly repo_dir=$(cd "${base_dir}/.."; pwd)
readonly util_image=${ZOOKAGE_UTIL_IMAGE:-zookage/zookage-util:experimental}
readonly ca_dir="${base_dir}/tls"
readonly public_dir="${repo_dir}/kubernetes/base/common/config/tls"

# Refuse partial output sets too: an existing trust anchor must never be replaced.
for output in "${ca_dir}/zookage-ca.jks" "${public_dir}/zookage-ca.crt" "${public_dir}/zookage-truststore.jks"; do
  if [[ -e "${output}" || -L "${output}" ]]; then
    echo "Refusing to replace the ZooKage CA: ${output} already exists." >&2
    exit 1
  fi
done

readonly temp_dir=$(mktemp -d)
trap 'rm -rf "${temp_dir}"' EXIT

docker run --rm -i --network=none --read-only --tmpfs /tmp \
  --user "$(id -u):$(id -g)" \
  --mount "type=bind,source=${temp_dir},target=/output" \
  "${util_image}" /bin/bash -eu <<'SCRIPT'
  keytool -genkeypair \
    -alias zookage-ca -keyalg RSA -keysize 3072 -sigalg SHA256withRSA \
    -dname "CN=ZooKage Private CA,O=ZooKage" -validity 7300 \
    -ext "BC:critical=ca:true,pathlen:0" -ext "KU:critical=keyCertSign,cRLSign" \
    -keystore /output/zookage-ca.jks -storetype JKS \
    -storepass zookage -keypass zookage
  keytool -exportcert -rfc -alias zookage-ca \
    -keystore /output/zookage-ca.jks -storepass zookage \
    -file /output/zookage-ca.crt
  keytool -importcert -noprompt -alias zookage-ca \
    -file /output/zookage-ca.crt \
    -keystore /output/zookage-truststore.jks -storetype JKS \
    -storepass zookage
SCRIPT

# keytool writes CRLF in PEM output; normalize checked-in certificates to LF.
tr -d '\r' < "${temp_dir}/zookage-ca.crt" > "${temp_dir}/zookage-ca.pem"
mkdir -p "${ca_dir}" "${public_dir}"
install -m 0600 "${temp_dir}/zookage-ca.jks" "${ca_dir}/zookage-ca.jks"
install -m 0644 "${temp_dir}/zookage-ca.pem" "${public_dir}/zookage-ca.crt"
install -m 0644 "${temp_dir}/zookage-truststore.jks" "${public_dir}/zookage-truststore.jks"
