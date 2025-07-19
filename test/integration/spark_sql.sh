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

"${integration_dir}/divider.sh" "Start running Spark SQL queries"
"${integration_dir}/run.sh" spark-sql -e "
  DROP TABLE IF EXISTS mofu_spark;
  CREATE TABLE mofu_spark (name string);
  INSERT INTO mofu_spark (name) VALUES ('12345');
  SELECT name, count(1) FROM mofu_spark GROUP BY name;
"
"${integration_dir}/divider.sh" "Finished running Spark SQL queries"

echo "The test queries succeeded."
echo

"${integration_dir}/spark_log.sh"
