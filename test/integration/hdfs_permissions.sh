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
  as_user() {
    local user=$1
    shift
    HADOOP_USER_NAME="${user}" hdfs dfs "$@"
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

  readonly test_name="permissions-$(date +%s)-$$-${RANDOM}"
  readonly shared="/apps/hive-warehouse/${test_name}"

  cleanup() {
    as_user hdfs -rm -r -f -skipTrash \
      "${shared}-hive" "${shared}-trino" "${shared}-zookage" \
      "${shared}-alice-denied" \
      "/user/zookage/${test_name}" "/user/alice/${test_name}"
  }
  trap cleanup EXIT

  local user
  for user in hive trino zookage; do
    as_user "${user}" -mkdir "${shared}-${user}"
    as_user "${user}" -touchz "${shared}-${user}/${user}-file"
    printf '%s\n' "${user}" | as_user "${user}" -appendToFile - "${shared}-${user}/${user}-file"
    as_user "${user}" -cat "${shared}-${user}/${user}-file"
  done
  expect_permission_denied alice -ls /apps/hive-warehouse
  expect_permission_denied alice -cat "${shared}-zookage/zookage-file"
  expect_permission_denied alice -mkdir "${shared}-alice-denied"

  local owner user_home home_permissions private
  for owner in zookage alice; do
    user_home="/user/${owner}"
    private="${user_home}/${test_name}"
    home_permissions=$(as_user hdfs -stat '%u:%g %a' "${user_home}")
    if [[ "${home_permissions}" != "${owner}:${owner} 700" ]]; then
      echo "Unexpected ${user_home} ownership or permissions: ${home_permissions}" >&2
      exit 1
    fi

    as_user "${owner}" -mkdir "${private}"
    as_user "${owner}" -touchz "${private}/${owner}-file"
    printf '%s\n' "${owner}" | as_user "${owner}" -appendToFile - "${private}/${owner}-file"
    as_user "${owner}" -cat "${private}/${owner}-file"
    for user in zookage alice hive trino httpfs; do
      if [[ "${user}" == "${owner}" ]]; then
        continue
      fi
      expect_permission_denied "${user}" -ls "${user_home}"
      expect_permission_denied "${user}" -cat "${private}/${owner}-file"
      expect_permission_denied "${user}" -mkdir "${private}/${user}-directory"
    done
  done
}

"${integration_dir}/divider.sh" "Start checking HDFS permissions"
"${integration_dir}/run.sh" bash -eu -c "$(declare -f check_hdfs_permissions); check_hdfs_permissions"
"${integration_dir}/divider.sh" "Finished checking HDFS permissions"

echo "The HDFS permission checks succeeded."
echo
