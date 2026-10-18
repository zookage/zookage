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
  readonly private="/user/zookage/${test_name}"

  cleanup() {
    as_user hdfs -rm -r -f -skipTrash \
      "${shared}-hive" "${shared}-trino" "${shared}-zookage" "${shared}-denied" "${private}"
  }
  trap cleanup EXIT

  local user
  for user in hive trino zookage; do
    as_user "${user}" -mkdir "${shared}-${user}"
    as_user "${user}" -touchz "${shared}-${user}/${user}-file"
    printf '%s\n' "${user}" | as_user "${user}" -appendToFile - "${shared}-${user}/${user}-file"
    as_user "${user}" -cat "${shared}-${user}/${user}-file"
  done
  expect_permission_denied httpfs -ls /apps/hive-warehouse
  expect_permission_denied httpfs -cat "${shared}-zookage/zookage-file"
  expect_permission_denied httpfs -mkdir "${shared}-denied"

  local home_permissions
  home_permissions=$(as_user hdfs -stat '%u:%g %a' /user/zookage)
  if [[ "${home_permissions}" != 'zookage:zookage 700' ]]; then
    echo "Unexpected /user/zookage ownership or permissions: ${home_permissions}" >&2
    exit 1
  fi

  as_user zookage -mkdir "${private}"
  as_user zookage -touchz "${private}/zookage-file"
  for user in hive trino httpfs; do
    expect_permission_denied "${user}" -ls /user/zookage
    expect_permission_denied "${user}" -cat "${private}/zookage-file"
    expect_permission_denied "${user}" -mkdir "${private}/${user}-directory"
  done
}

"${integration_dir}/divider.sh" "Start checking HDFS permissions"
"${integration_dir}/run.sh" bash -eu -c "$(declare -f check_hdfs_permissions); check_hdfs_permissions"
"${integration_dir}/divider.sh" "Finished checking HDFS permissions"

echo "The HDFS permission checks succeeded."
echo
