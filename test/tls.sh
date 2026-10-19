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

readonly test_dir=$(cd "$(dirname "$0")"; pwd)
readonly repo_dir=$(cd "${test_dir}/.."; pwd)
readonly util_image=${ZOOKAGE_UTIL_IMAGE:-zookage/zookage-util:experimental}
readonly temp_dir=$(mktemp -d)
readonly fixture_dir="${temp_dir}/repo"
trap 'rm -rf "${temp_dir}"' EXIT

mkdir -p "${fixture_dir}/docker/tls" "${temp_dir}/original"
cp "${repo_dir}/docker/generate-tls.sh" "${fixture_dir}/docker/"
cp "${repo_dir}/docker/tls/hdfs.san" "${fixture_dir}/docker/tls/"

readonly ca_files=(docker/tls/zookage-ca.jks \
  kubernetes/base/common/config/tls/zookage-ca.crt \
  kubernetes/base/common/config/tls/zookage-truststore.jks)

assert_ca_unchanged() {
  local path
  for path in "${ca_files[@]}"; do
    cmp "${temp_dir}/original/$(basename "${path}")" "${fixture_dir}/${path}"
  done
}

expect_failure() {
  if "$@" > "${temp_dir}/rejected.log" 2>&1; then
    echo "Unexpected success: $*" >&2
    exit 1
  fi
}

verify_certificates() {
  local test_hostname=$1
  docker run --rm -i --network=none --read-only --tmpfs /tmp \
    --user "$(id -u):$(id -g)" --env LC_ALL=C \
    --mount "type=bind,source=${fixture_dir},target=/repo,readonly" \
    "${util_image}" /bin/bash -eu -o pipefail -s -- "${test_hostname}" <<'SCRIPT'
  public=/repo/kubernetes/base/common/config/tls
  secret=/repo/kubernetes/base/common/secret
  openssl x509 -in "${public}/zookage-ca.crt" -outform DER > /tmp/ca.der
  openssl verify -CAfile "${public}/zookage-ca.crt" "${public}/zookage-ca.crt"
  openssl x509 -in "${public}/zookage-ca.crt" -noout -text | grep -q 'CA:TRUE'

  # Runtime trust contains one public CA certificate and no signing key.
  keytool -list -v -keystore "${public}/zookage-truststore.jks" -storepass zookage > /tmp/trust.txt
  grep -q 'Your keystore contains 1 entry' /tmp/trust.txt
  grep -q '^Entry type: trustedCertEntry$' /tmp/trust.txt
  ! grep -q 'PrivateKeyEntry' /tmp/trust.txt
  keytool -exportcert -alias zookage-ca -keystore "${public}/zookage-truststore.jks" \
    -storepass zookage > /tmp/trust-ca.der
  cmp /tmp/ca.der /tmp/trust-ca.der

  for service in hdfs tls-test; do
    keystore="${secret}/${service}/${service}.jks"
    certificate="${public}/${service}.crt"
    keytool -list -v -keystore "${keystore}" -storepass "${service}" > /tmp/keystore.txt
    [[ "$(grep -c '^Entry type: PrivateKeyEntry$' /tmp/keystore.txt)" == 1 ]]
    # Creating a CSR also verifies that the private key uses the service password.
    keytool -certreq -alias "${service}" -keystore "${keystore}" \
      -storepass "${service}" -keypass "${service}" -file /tmp/service.csr
    keytool -list -v -alias "${service}" -keystore "${keystore}" -storepass "${service}" > /tmp/leaf.txt
    grep -q '^Entry type: PrivateKeyEntry$' /tmp/leaf.txt
    grep -q '^Certificate chain length: 2$' /tmp/leaf.txt
    keytool -exportcert -alias "${service}" -keystore "${keystore}" -storepass "${service}" > /tmp/leaf.der
    openssl x509 -in "${certificate}" -outform DER > /tmp/public-leaf.der
    cmp /tmp/leaf.der /tmp/public-leaf.der
    keytool -list -rfc -alias "${service}" -keystore "${keystore}" -storepass "${service}" \
      | awk '/BEGIN CERTIFICATE/ { certificate++ } certificate == 2 { print }' > /tmp/chain-ca.crt
    openssl x509 -in /tmp/chain-ca.crt -outform DER > /tmp/chain-ca.der
    cmp /tmp/ca.der /tmp/chain-ca.der
    openssl verify -purpose sslserver -CAfile "${public}/zookage-ca.crt" "${certificate}"
    openssl x509 -in "${certificate}" -noout -text > /tmp/leaf.txt
    grep -q 'CA:FALSE' /tmp/leaf.txt
    grep -q 'TLS Web Server Authentication' /tmp/leaf.txt
  done

  for hostname in hdfs-namenode hdfs-namenode.zookage.svc.cluster.local; do
    openssl verify -CAfile "${public}/zookage-ca.crt" -verify_hostname "${hostname}" "${public}/hdfs.crt"
  done
  for component in namenode datanode journalnode; do
    replicas=3
    [[ ${component} != namenode ]] || replicas=2
    for ((index = 0; index < replicas; index++)); do
      pod="hdfs-${component}-${index}"
      for hostname in "${pod}" "${pod}.hdfs-${component}" "${pod}.hdfs-${component}.zookage.svc.cluster.local"; do
        openssl verify -CAfile "${public}/zookage-ca.crt" -verify_hostname "${hostname}" "${public}/hdfs.crt"
      done
    done
  done
  if openssl verify -CAfile "${public}/zookage-ca.crt" \
    -verify_hostname localhost "${public}/hdfs.crt" > /tmp/loopback-san.log 2>&1 || \
    openssl verify -CAfile "${public}/zookage-ca.crt" \
      -verify_ip 127.0.0.1 "${public}/hdfs.crt" >> /tmp/loopback-san.log 2>&1; then
    echo 'HDFS certificate still accepts a loopback hostname or IP address.' >&2
    exit 1
  fi
  openssl verify -CAfile "${public}/zookage-ca.crt" -verify_hostname "$1" "${public}/tls-test.crt"
  openssl verify -CAfile "${public}/zookage-ca.crt" -verify_ip 127.0.0.2 "${public}/tls-test.crt"
  if [[ $1 == tls-renewed.zookage.svc.cluster.local ]] && \
    openssl verify -CAfile "${public}/zookage-ca.crt" \
      -verify_hostname tls-test.zookage.svc.cluster.local "${public}/tls-test.crt" > /tmp/old-san.log 2>&1; then
    echo 'Reissued certificate still accepts the removed hostname.' >&2
    exit 1
  fi
SCRIPT
}

# Test service issuance using a temporary copy of the checked-in sample CA.
for path in "${ca_files[@]}"; do
  mkdir -p "$(dirname "${fixture_dir}/${path}")"
  cp "${repo_dir}/${path}" "${fixture_dir}/${path}"
  cp "${repo_dir}/${path}" "${temp_dir}/original/"
done

expect_failure "${fixture_dir}/docker/generate-tls.sh" zookage-ca 'dns:zookage-ca'
expect_failure "${fixture_dir}/docker/generate-tls.sh" tls-test
: > "${fixture_dir}/docker/tls/tls-test.san"
expect_failure "${fixture_dir}/docker/generate-tls.sh" tls-test
expect_failure "${fixture_dir}/docker/generate-tls.sh" hdfs ''
assert_ca_unchanged

"${fixture_dir}/docker/generate-tls.sh" hdfs
"${fixture_dir}/docker/generate-tls.sh" tls-test 'dns:tls-test.zookage.svc.cluster.local,ip:127.0.0.2'
assert_ca_unchanged
verify_certificates tls-test.zookage.svc.cluster.local

cp "${fixture_dir}/kubernetes/base/common/config/tls/tls-test.crt" "${temp_dir}/original/tls-test.crt"
"${fixture_dir}/docker/generate-tls.sh" tls-test 'dns:tls-renewed.zookage.svc.cluster.local,ip:127.0.0.2'
assert_ca_unchanged
if cmp -s "${temp_dir}/original/tls-test.crt" "${fixture_dir}/kubernetes/base/common/config/tls/tls-test.crt"; then
  echo 'Service certificate was not reissued.' >&2
  exit 1
fi
verify_certificates tls-renewed.zookage.svc.cluster.local

# Service issuance requires all CA files and must never create a new trust root.
for path in "${ca_files[@]}"; do
  mv "${fixture_dir}/${path}" "${temp_dir}/missing-ca-file"
  expect_failure "${fixture_dir}/docker/generate-tls.sh" hdfs
  [[ ! -e "${fixture_dir}/${path}" ]]
  mv "${temp_dir}/missing-ca-file" "${fixture_dir}/${path}"
  assert_ca_unchanged
done

echo 'The TLS certificate checks succeeded.'
