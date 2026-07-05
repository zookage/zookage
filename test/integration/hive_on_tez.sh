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
# shellcheck source=/mnt/test/integration/s3.sh
source "${integration_dir}/s3.sh"

run_beeline() {
  local sql=$1

  "${integration_dir}/run.sh" /bin/bash -lc "TERM=dumb JAVA_TOOL_OPTIONS=\"-Djline.terminal=dumb -Dorg.jline.terminal.dumb=true\" beeline -e \"${sql}\""
}

run_hive_on_tez_queries() {
  local location_prefix=${1:-}
  local name="Hive on Tez queries"
  local success_message="The test queries succeeded."
  local table="mofu_tez"
  local location=""
  local sql

  if [[ -n "${location_prefix}" ]]; then
    name="${name} on ${location_prefix}"
    success_message="The S3 test queries succeeded on ${location_prefix}."
  fi

  "${integration_dir}/divider.sh" "Start running ${name}"

  if [[ -n "${location_prefix}" ]]; then
    location="${location_prefix}/${table}"
    "${integration_dir}/run.sh" hadoop fs -rm -r -f "${location}"
    sql="
      DROP TABLE IF EXISTS ${table};
      CREATE EXTERNAL TABLE ${table} (name string)
      LOCATION '${location}';
      INSERT INTO ${table} (name) VALUES ('12345');
      SELECT name, count(1) FROM ${table} GROUP BY name;
    "
  else
    sql="
      DROP TABLE IF EXISTS ${table};
      CREATE TABLE ${table} (name string);
      INSERT INTO ${table} (name) VALUES ('12345');
      SELECT name, count(1) FROM ${table} GROUP BY name;
    "
  fi

  run_beeline "${sql}"
  "${integration_dir}/divider.sh" "Finished running ${name}"

  echo "${success_message}"
  echo
}

run_hive_on_tez_queries

# ensure_s3_bucket test
# run_hive_on_tez_queries s3a://test/hive-on-tez

"${integration_dir}/tez_log.sh"
