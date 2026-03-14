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

run_test() {
  local name=$1
  local script=$2

  "${test_dir}/integration/divider.sh" "Test ${name}"
  "${script}"
}

if [[ $# -ge 1 ]]; then
  readonly kustomization_name="$1"
  readonly source_kustomization="${test_dir}/kubernetes/${kustomization_name}.yaml"
  readonly target_kustomization="${repo_dir}/kubernetes/kustomization.yaml"

  if [[ ! -f "${source_kustomization}" ]]; then
    echo "No such kustomization: ${source_kustomization}" >&2
    exit 1
  fi

  cp "${source_kustomization}" "${target_kustomization}"
  "${repo_dir}/bin/down"
  "${repo_dir}/bin/up"
fi

if [[ ${kustomization_name:-} != "llap" ]]; then
  run_test "Web" "${test_dir}/integration/web.sh"
  run_test "MR" "${test_dir}/integration/mr.sh"
  run_test "Spark" "${test_dir}/integration/spark.sh"
  run_test "ZooKeeper" "${test_dir}/integration/zookeeper.sh"
  run_test "HBase" "${test_dir}/integration/hbase.sh"
  run_test "Ozone" "${test_dir}/integration/ozone.sh"
  run_test "Trino" "${test_dir}/integration/trino.sh"
fi

run_test "Tez" "${test_dir}/integration/tez.sh"
run_test "Hive on Tez" "${test_dir}/integration/hive_on_tez.sh"

run_test "error logs" "${test_dir}/integration/container_error.sh"
run_test "warning logs" "${test_dir}/integration/container_warn.sh"

echo
echo "All integration tests have passed."
