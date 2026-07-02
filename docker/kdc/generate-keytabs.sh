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
readonly repo_dir=$(cd "${base_dir}/../.."; pwd)
readonly keytab_dir="${repo_dir}/kubernetes/base/kerberos/kdc/keytabs"
readonly principals_file="${repo_dir}/kubernetes/base/common/config/kerberos/principals.json"

rm -f "${keytab_dir}"/*.keytab

read_keytab_principals() {
  jq -r '.principals[]
    | select(.keytab != null)
    | [.principal, .password, .keytab]
    | @tsv' "${principals_file}"
}

while IFS=$'\t' read -r principal password keytab; do
  ktutil -k "${keytab_dir}/${keytab}" add \
    -p "${principal}" \
    -w "${password}" \
    -e aes256-cts-hmac-sha1-96 \
    -V 1
  ktutil -k "${keytab_dir}/${keytab}" add \
    -p "${principal}" \
    -w "${password}" \
    -e aes128-cts-hmac-sha1-96 \
    -V 1
done < <(read_keytab_principals)
