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

"${test_dir}/integration/divider.sh" "Test Web"
"${test_dir}/integration/web.sh"

"${test_dir}/integration/divider.sh" "Test Tez"
"${test_dir}/integration/tez.sh"

"${test_dir}/integration/divider.sh" "Test Hive on Tez"
"${test_dir}/integration/hive_on_tez.sh"

"${test_dir}/integration/divider.sh" "Test MR"
"${test_dir}/integration/mr.sh"

"${test_dir}/integration/divider.sh" "Test Spark"
"${test_dir}/integration/spark.sh"

"${test_dir}/integration/divider.sh" "Test ZooKeeper"
"${test_dir}/integration/zookeeper.sh"

"${test_dir}/integration/divider.sh" "Test HBase"
"${test_dir}/integration/hbase.sh"

"${test_dir}/integration/divider.sh" "Test Ozone"
"${test_dir}/integration/ozone.sh"

"${test_dir}/integration/divider.sh" "Test Trino"
"${test_dir}/integration/trino.sh"

"${test_dir}/integration/divider.sh" "Test error logs"
"${test_dir}/integration/container_error.sh"

"${test_dir}/integration/divider.sh" "Test warning logs"
"${test_dir}/integration/container_warn.sh"

echo
echo "All integration tests have passed."
