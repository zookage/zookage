#!/bin/bash
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
