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
readonly secret_dir="${repo_dir}/kubernetes/base/common/secret"
readonly principals_file="${repo_dir}/kubernetes/base/common/config/openldap/bootstrap.ldif"

keytab_principals() {
  local dn_pattern=$1

  awk -v dn_pattern="${dn_pattern}" '
    function emit() {
      if (dn ~ dn_pattern && principal != "" && password != "") {
        print principal "\t" password
      }
    }

    /^dn: / {
      emit()
      dn = $0
      sub(/^dn: /, "", dn)
      principal = ""
      password = ""
      next
    }
    /^userPassword: / {
      password = $0
      sub(/^userPassword: /, "", password)
      next
    }
    /^krbPrincipalName: / {
      principal = $0
      sub(/^krbPrincipalName: /, "", principal)
      next
    }
    END {
      emit()
    }
  ' "${principals_file}"
}

generate_keytab() {
  local keytab_file=$1
  local dn_pattern=$2

  mkdir -p "$(dirname "${keytab_file}")"
  rm -f "${keytab_file}"
  while IFS=$'\t' read -r principal password; do
    ktutil -k "${keytab_file}" add \
      -p "${principal}" \
      -w "${password}" \
      -e aes256-cts-hmac-sha1-96 \
      -V 1
  done < <(keytab_principals "${dn_pattern}")
}

if [[ $# -eq 0 ]]; then
  set -- client hive ranger yarn
fi

for service in "$@"; do
  case "${service}" in
    client) dn_pattern='^uid=zookage,ou=users,dc=example,dc=com$' ;;
    hive|ranger|yarn) dn_pattern="^uid=.*ou=${service},ou=kerberos,dc=example,dc=com$" ;;
    *) echo "Unknown keytab service: ${service}" >&2; exit 1 ;;
  esac
  generate_keytab "${secret_dir}/${service}/${service}.keytab" "${dn_pattern}"
done
