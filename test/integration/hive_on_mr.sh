#!/bin/bash
set -eu

readonly integration_dir=$(cd "$(dirname "$0")"; pwd)

"${integration_dir}/divider.sh" "Start running Hive on MR queries"
"${integration_dir}/run.sh" beeline -e "
  SET hive.execution.engine=mr;
  DROP TABLE IF EXISTS mofu_mr;
  CREATE TABLE mofu_mr (name string);
  INSERT INTO mofu_mr (name) VALUES ('12345');
  SELECT name, count(*) FROM mofu_mr GROUP BY name;
"
"${integration_dir}/divider.sh" "Finished running Hive on MR queries"

echo "The test queries succeeded."
echo

"${integration_dir}/mr_log.sh"
