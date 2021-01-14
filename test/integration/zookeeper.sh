#!/bin/bash
set -eu

readonly integration_dir=$(cd "$(dirname "$0")"; pwd)
readonly base_dir=$(dirname "$(dirname "$(cd "$(dirname "$0")" || exit; pwd)")")

"${integration_dir}/divider.sh" "Start checking ZooKeeper"

for i in {0..2}; do
  "${base_dir}/bin/kubectl" exec -it \
    "zookeeper-server-${i}" \
    -- \
    /opt/zookeeper/bin/zkServer.sh \
    status
done

"${integration_dir}/divider.sh" "Finished checking ZooKeeper"
echo "The test command succeeded."
echo
