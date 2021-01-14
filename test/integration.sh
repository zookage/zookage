#!/bin/bash
set -eu

readonly test_dir=$(cd "$(dirname "$0")"; pwd)

"${test_dir}/integration/divider.sh" "Test Web"
"${test_dir}/integration/web.sh"

"${test_dir}/integration/divider.sh" "Test Tez"
"${test_dir}/integration/tez.sh"

"${test_dir}/integration/divider.sh" "Test Hive on Tez"
"${test_dir}/integration/hive_on_tez.sh"

"${test_dir}/integration/divider.sh" "Test MR"
"${test_dir}/integration/mr.sh"

"${test_dir}/integration/divider.sh" "Test Hive on MR"
"${test_dir}/integration/hive_on_mr.sh"

"${test_dir}/integration/divider.sh" "Test ZooKeeper"
"${test_dir}/integration/zookeeper.sh"

"${test_dir}/integration/divider.sh" "Test servers"
"${test_dir}/integration/container_log.sh"

echo
echo "All integration tests have passed."
