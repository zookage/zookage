#!/bin/bash
set -eu

readonly integration_dir=$(cd "$(dirname "$0")"; pwd)

"${integration_dir}/divider.sh" "Start running Trino queries"
"${integration_dir}/run.sh" trino --execute="
  SELECT count(*) FROM tpcds.tiny.item;
"
"${integration_dir}/divider.sh" "Finished running Trino queries"

echo "The test queries succeeded."
echo
