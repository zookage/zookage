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

"${integration_dir}/divider.sh" "Start running Trino queries"
"${integration_dir}/run.sh" trino --execute="
  CREATE TABLE IF NOT EXISTS hive.default.trino_hive_test (id int);
  INSERT INTO hive.default.trino_hive_test VALUES (1);
  SELECT * FROM hive.default.trino_hive_test;

  CREATE TABLE IF NOT EXISTS iceberg.default.trino_iceberg_test (id int);
  INSERT INTO iceberg.default.trino_iceberg_test VALUES (1);
  SELECT * FROM iceberg.default.trino_iceberg_test;
"
"${integration_dir}/divider.sh" "Finished running Trino queries"

echo "The test queries succeeded."
echo
