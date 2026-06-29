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

readonly realm=${KRB5_REALM:?KRB5_REALM is required}
readonly master_password=${KRB5_MASTER_PASSWORD:?KRB5_MASTER_PASSWORD is required}
readonly principals_file=${KRB5_PRINCIPALS_FILE:?KRB5_PRINCIPALS_FILE is required}
readonly database=/var/lib/krb5kdc/principal

password_for_principal() {
  local principal=$1
  local service=${principal%%/*}

  echo "${service%%@*}"
}

read_principals() {
  jq -r '.principals[].principal' "${principals_file}"
}

if [[ ! -f "${database}" ]]; then
  kdb5_util create -s -r "${realm}" -P "${master_password}"

  while read -r principal; do
    kadmin.local -q "addprinc -pw $(password_for_principal "${principal}") ${principal}"
  done < <(read_principals)
fi

exec krb5kdc -n
