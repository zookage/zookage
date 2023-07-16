#!/bin/bash
set -eu

readonly integration_dir=$(cd "$(dirname "$0")"; pwd)

"${integration_dir}/divider.sh" "Start running Trino queries"
"${integration_dir}/run.sh" trino --execute="
  CREATE SCHEMA IF NOT EXISTS hive.db_trino;
  DROP TABLE IF EXISTS hive.db_trino.mofu_trino;
  CREATE TABLE hive.db_trino.mofu_trino (name VARCHAR);
  INSERT INTO hive.db_trino.mofu_trino (name) VALUES ('12345');
  SELECT name, count(1) FROM hive.db_trino.mofu_trino GROUP BY name;
"
"${integration_dir}/divider.sh" "Finished running Trino queries"

echo "The test queries succeeded."
echo
