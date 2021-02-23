#!/bin/bash
set -eu

readonly integration_dir=$(cd "$(dirname "$0")"; pwd)

"${integration_dir}/divider.sh" "Start running an HBase command"
"${integration_dir}/run.sh" bash -c "echo list | hbase shell --noninteractive"
"${integration_dir}/divider.sh" "Finished running an HBase command"

echo "The test command succeeded."
echo
