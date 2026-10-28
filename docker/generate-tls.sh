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

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "Usage: $0 <service> [SAN]" >&2
  echo "When SAN is omitted, read docker/tls/<service>.san (optional for client certificates)." >&2
  echo "Set TLS_EXTENDED_KEY_USAGE=clientAuth for a client certificate." >&2
  echo "Example: $0 hive-metastore dns:hive-metastore,dns:localhost,ip:127.0.0.1" >&2
  exit 1
fi

readonly service=$1
if [[ ! ${service} =~ ^[a-z0-9]([a-z0-9-]*[a-z0-9])?$ || ${#service} -gt 63 || ${service} == zookage-ca ]]; then
  echo "Service must be a lowercase DNS label other than zookage-ca (at most 63 characters)." >&2
  exit 1
fi

readonly extended_key_usage=${TLS_EXTENDED_KEY_USAGE:-serverAuth}
if [[ ${extended_key_usage} != serverAuth && ${extended_key_usage} != clientAuth ]]; then
  echo "TLS_EXTENDED_KEY_USAGE must be serverAuth or clientAuth." >&2
  exit 1
fi

readonly base_dir=$(cd "$(dirname "$0")"; pwd)
if [[ $# -eq 2 ]]; then
  san=$2
else
  readonly san_file="${base_dir}/tls/${service}.san"
  if [[ -f "${san_file}" ]]; then
    san=$(awk 'NF && !/^#/ { printf "%s%s", separator, $0; separator = "," }' "${san_file}")
  elif [[ ${extended_key_usage} == clientAuth ]]; then
    san=
  else
    echo "Missing SAN file: ${san_file}. Supply SAN as the second argument." >&2
    exit 1
  fi
fi
if [[ -z "${san}" && ${extended_key_usage} == serverAuth ]]; then
  echo "At least one SAN is required for a server certificate." >&2
  exit 1
fi
readonly san

readonly repo_dir=$(cd "${base_dir}/.."; pwd)
readonly util_image=${ZOOKAGE_UTIL_IMAGE:-zookage/zookage-util:experimental}
readonly ca_store="${base_dir}/tls/zookage-ca.jks"
readonly public_dir="${repo_dir}/kubernetes/base/common/config/tls"
readonly secret_root="${repo_dir}/kubernetes/base/common/secret"
# Reissue existing certificates in place, including those in shared Secrets.
secret_dir=
for existing_jks in "${secret_root}"/*/"${service}.jks"; do
  if [[ ! -f ${existing_jks} ]]; then
    continue
  fi
  if [[ -n ${secret_dir} ]]; then
    echo "Multiple existing JKS files for ${service}." >&2
    exit 1
  fi
  secret_dir=${existing_jks%/*}
done
if [[ -z ${secret_dir} ]]; then
  secret_dir="${secret_root}/${service}"
fi
readonly secret_dir

for input in "${ca_store}" "${public_dir}/zookage-ca.crt" "${public_dir}/zookage-truststore.jks"; do
  if [[ ! -f "${input}" ]]; then
    echo "Missing ZooKage CA file: ${input}. Restore the checked-in CA files before issuing certificates." >&2
    exit 1
  fi
done

readonly temp_dir=$(mktemp -d)
trap 'rm -rf "${temp_dir}"' EXIT

# The CA key is mounted only in this offline issuer, never in the cluster.
docker run --rm -i --network=none --read-only --tmpfs /tmp \
  --user "$(id -u):$(id -g)" \
  --mount "type=bind,source=${temp_dir},target=/output" \
  --mount "type=bind,source=${ca_store},target=/ca/zookage-ca.jks,readonly" \
  --mount "type=bind,source=${public_dir}/zookage-ca.crt,target=/ca/zookage-ca.crt,readonly" \
  --env "TLS_SERVICE=${service}" --env "TLS_SAN=${san}" \
  --env "TLS_EXTENDED_KEY_USAGE=${extended_key_usage}" \
  "${util_image}" /bin/bash -eu <<'SCRIPT'
  keytool -genkeypair \
    -alias "${TLS_SERVICE}" -keyalg RSA -keysize 2048 -sigalg SHA256withRSA \
    -dname "CN=${TLS_SERVICE},O=ZooKage" -validity 3650 \
    -keystore /output/service.jks -storetype JKS \
    -storepass zookage -keypass zookage
  keytool -certreq -alias "${TLS_SERVICE}" \
    -keystore /output/service.jks -storepass zookage -keypass zookage \
    -file /output/service.csr
  san_extension=()
  if [[ -n ${TLS_SAN} ]]; then
    san_extension=(-ext "SAN=${TLS_SAN}")
  fi
  keytool -gencert -rfc -alias zookage-ca -sigalg SHA256withRSA \
    -keystore /ca/zookage-ca.jks -storepass zookage -keypass zookage \
    -infile /output/service.csr -outfile /output/service-reply.crt -validity 3650 \
    -ext "BC:critical=ca:false" -ext "KU:critical=digitalSignature,keyEncipherment" \
    -ext "EKU=${TLS_EXTENDED_KEY_USAGE}" "${san_extension[@]}"
  keytool -importcert -noprompt -alias zookage-ca \
    -file /ca/zookage-ca.crt \
    -keystore /output/service.jks -storepass zookage
  keytool -importcert -noprompt -alias "${TLS_SERVICE}" \
    -file /output/service-reply.crt \
    -keystore /output/service.jks -storepass zookage -keypass zookage
  keytool -exportcert -rfc -alias "${TLS_SERVICE}" \
    -keystore /output/service.jks -storepass zookage \
    -file /output/service.crt
  if [[ ${TLS_EXTENDED_KEY_USAGE} == clientAuth ]]; then
    keytool -importkeystore -noprompt \
      -srckeystore /output/service.jks -srcstorepass zookage \
      -destkeystore /output/service.p12 -deststoretype PKCS12 -deststorepass zookage
  fi
SCRIPT

tr -d '\r' < "${temp_dir}/service.crt" > "${temp_dir}/service.pem"
mkdir -p "${secret_dir}"
install -m 0600 "${temp_dir}/service.jks" "${secret_dir}/${service}.jks"
if [[ ${extended_key_usage} == clientAuth ]]; then
  install -m 0600 "${temp_dir}/service.p12" "${secret_dir}/${service}.p12"
fi
install -m 0644 "${temp_dir}/service.pem" "${public_dir}/${service}.crt"
