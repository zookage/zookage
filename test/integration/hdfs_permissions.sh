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

readonly integration_dir=$(cd "$(dirname "$0")"; pwd)

check_hdfs_permissions() {
  readonly authentication=$(hdfs getconf -confKey hadoop.security.authentication)
  readonly cache_dir=$(mktemp -d)
  unset HADOOP_TOKEN_FILE_LOCATION

  as_user() {
    local user=$1
    shift
    if [[ "${authentication}" == "kerberos" ]]; then
      local cache="${cache_dir}/${user}.ccache"
      if [[ ! -f "${cache}" ]]; then
        case "${user}" in
          hdfs|hive|trino)
            # These service accounts use their names as sample passwords.
            printf '%s\n' "${user}" | kinit -c "FILE:${cache}" "${user}@ZOOKAGE.LOCAL"
            ;;
          *) kinit -c "FILE:${cache}" -kt /etc/kerberos/secrets/client.keytab "${user}@ZOOKAGE.LOCAL" ;;
        esac
      fi
      KRB5CCNAME="FILE:${cache}" hdfs dfs "$@"
    else
      HADOOP_USER_NAME="${user}" hdfs dfs "$@"
    fi
  }

  expect_permission_denied() {
    local user=$1
    local output
    shift

    if output=$(as_user "${user}" "$@" 2>&1); then
      echo "Unexpected HDFS access for ${user}: $*" >&2
      exit 1
    fi
    if [[ "${output}" != *"Permission denied"* ]]; then
      echo "Expected Permission denied for ${user}: ${output}" >&2
      exit 1
    fi
  }

  check_read_write_access() {
    local path=$1
    local user=$2
    local test_file="${path}/${user}-file"

    as_user "${user}" -mkdir "${path}"
    printf '%s\n' "${user}" | as_user "${user}" -put - "${test_file}"
    as_user "${user}" -cat "${test_file}"
    expect_permission_denied alice -ls "${path}"
    expect_permission_denied alice -cat "${test_file}"
    expect_permission_denied alice -touchz "${path}/alice-file"
  }

  readonly test_name="permissions-$(date +%s)-$$-${RANDOM}"
  readonly shared="/apps/hive-warehouse/${test_name}"
  readonly private="/user/zookage/${test_name}"

  cleanup() {
    local status=$?
    as_user hdfs -rm -r -f -skipTrash \
      "${shared}-hive" "${shared}-trino" "${shared}-zookage" "${private}" || status=1
    rm -rf "${cache_dir}"
    exit "${status}"
  }
  trap cleanup EXIT

  local user
  for user in hive trino zookage; do
    check_read_write_access "${shared}-${user}" "${user}"
  done
  check_read_write_access "${private}" zookage
}

"${integration_dir}/divider.sh" "Start checking HDFS permissions"
"${integration_dir}/run.sh" bash -eu -c "$(declare -f check_hdfs_permissions); check_hdfs_permissions"
"${integration_dir}/divider.sh" "Finished checking HDFS permissions"

echo "The HDFS permission checks succeeded."
echo
