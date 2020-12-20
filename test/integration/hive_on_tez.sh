#!/bin/bash
set -eu

readonly integration_dir=$(cd "$(dirname "$0")"; pwd)

"${integration_dir}/divider.sh" "Start running Hive on Tez queries"
"${integration_dir}/run.sh" beeline -e "
  DROP TABLE IF EXISTS mofu_tez;
  CREATE TABLE mofu_tez (name string);
  INSERT INTO mofu_tez (name) VALUES ('12345');
  SELECT name, count(1) FROM mofu_tez GROUP BY name;
"
"${integration_dir}/divider.sh" "Finished running Hive on Tez queries"

echo "The test queries succeeded."
echo

"${integration_dir}/tez_log.sh"
