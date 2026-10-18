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

  assert_group() {
    local user=$1
    local group=$2
    local expected=$3
    local groups
    local actual=absent

    groups=$(hdfs groups "${user}")
    if [[ " ${groups#*:} " == *" ${group} "* ]]; then
      actual=present
    fi
    if [[ "${actual}" != "${expected}" ]]; then
      echo "Unexpected ${group} membership for ${user}: ${groups}" >&2
      exit 1
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

  for user in zookage hive trino; do
    assert_group "${user}" hadoop absent
  done
  for user in hdfs yarn mapred; do
    assert_group "${user}" hadoop present
  done
  assert_group zookage warehouse absent
  assert_group httpfs warehouse absent
  for user in hive trino; do
    assert_group "${user}" warehouse present
  done

  readonly test_name="permissions-$(date +%s)-$$-${RANDOM}"
  readonly shared_hive="/apps/hive-warehouse/${test_name}-hive"
  readonly shared_trino="/apps/hive-warehouse/${test_name}-trino"
  readonly shared_denied="/apps/hive-warehouse/${test_name}-denied"
  readonly dedicated="/apps/zookage-warehouse/${test_name}"

  cleanup() {
    as_user hdfs -rm -r -f -skipTrash \
      "${shared_hive}" "${shared_trino}" "${shared_denied}" "${dedicated}"
  }
  trap cleanup EXIT

  expect_permission_denied zookage -ls /apps/hive-warehouse
  expect_permission_denied zookage -mkdir "${shared_denied}"
  as_user hive -mkdir "${shared_hive}"
  as_user trino -mkdir "${shared_trino}"

  expect_permission_denied httpfs -ls /apps/zookage-warehouse
  expect_permission_denied httpfs -mkdir "${dedicated}"
  as_user zookage -mkdir "${dedicated}"
  as_user zookage -touchz "${dedicated}/zookage-file"
  as_user hive -touchz "${dedicated}/hive-file"
  as_user trino -touchz "${dedicated}/trino-file"

  # Each creator must inherit ACLs that let the other identities write below it.
  as_user hive -mkdir "${dedicated}/hive-directory"
  as_user zookage -touchz "${dedicated}/hive-directory/zookage-file"
  as_user trino -touchz "${dedicated}/hive-directory/trino-file"
  as_user zookage -mkdir "${dedicated}/zookage-directory"
  as_user hive -touchz "${dedicated}/zookage-directory/hive-file"
  as_user trino -touchz "${dedicated}/zookage-directory/trino-file"
}

"${integration_dir}/divider.sh" "Start checking HDFS permissions"
"${integration_dir}/run.sh" bash -eu -c "$(declare -f check_hdfs_permissions); check_hdfs_permissions"
"${integration_dir}/divider.sh" "Finished checking HDFS permissions"

echo "The HDFS permission checks succeeded."
echo
