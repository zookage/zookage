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

run_trino_queries() {
  local location_prefix=${1:-}
  local name="Trino queries"
  local success_message="The test queries succeeded."
  local hive_table_name="trino_hive_test"
  local hive_table="hive.default.${hive_table_name}"
  local hive_location=""
  local iceberg_table_name="trino_iceberg_test"
  local iceberg_table="iceberg.default.${iceberg_table_name}"
  local iceberg_location=""
  local sql

  if [[ -n "${location_prefix}" ]]; then
    name="${name} on ${location_prefix}"
    success_message="The S3 test queries succeeded on ${location_prefix}."
  fi

  "${integration_dir}/divider.sh" "Start running ${name}"

  if [[ -n "${location_prefix}" ]]; then
    hive_location="${location_prefix}/hive/${hive_table_name}"
    iceberg_location="${location_prefix}/iceberg/${iceberg_table_name}"
    "${integration_dir}/run.sh" hadoop fs -rm -r -f "${hive_location}"
    "${integration_dir}/run.sh" hadoop fs -rm -r -f "${iceberg_location}"
    sql="
      DROP TABLE IF EXISTS ${hive_table};
      CREATE TABLE ${hive_table} (id int)
      WITH (external_location = '${hive_location}');
      INSERT INTO ${hive_table} VALUES (1);
      SELECT * FROM ${hive_table};

      DROP TABLE IF EXISTS ${iceberg_table};
      CREATE TABLE ${iceberg_table} (id int)
      WITH (location = '${iceberg_location}');
      INSERT INTO ${iceberg_table} VALUES (1);
      SELECT * FROM ${iceberg_table};
    "
  else
    sql="
      DROP TABLE IF EXISTS ${hive_table};
      CREATE TABLE ${hive_table} (id int);
      INSERT INTO ${hive_table} VALUES (1);
      SELECT * FROM ${hive_table};

      DROP TABLE IF EXISTS ${iceberg_table};
      CREATE TABLE ${iceberg_table} (id int);
      INSERT INTO ${iceberg_table} VALUES (1);
      SELECT * FROM ${iceberg_table};
    "
  fi

  "${integration_dir}/run.sh" trino --execute="${sql}"
  "${integration_dir}/divider.sh" "Finished running ${name}"

  echo "${success_message}"
  echo
}

run_trino_queries

ensure_s3_bucket test
run_trino_queries s3a://test/trino
