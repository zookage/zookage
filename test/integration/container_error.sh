#!/bin/bash
set -eu

readonly integration_dir=$(cd "$(dirname "$0")"; pwd)
readonly base_dir=$(dirname "$(dirname "${integration_dir}")")

"${integration_dir}/divider.sh" "Start fetching errors of all containers"

# shellcheck disable=SC2016
! "${base_dir}/bin/logs" | grep ERROR \
  | grep -v 'pod/hive-hiveserver2-.* metadata.Hive: .*mofu_tez not found' \
  | grep -v 'pod/hive-hiveserver2-.* metadata.Hive: .*mofu_mr not found' \
  | grep -v 'pod/zookeeper-server-.* \[LeaderConnector-zookeeper-server-.*:Learner$LeaderConnector@.*\] - Unexpected exception' \
  | grep -v 'pod/zookeeper-server-.* \[LeaderConnector-zookeeper-server-.*:Learner$LeaderConnector@.*\] - Failed connect to' \
  | grep -v 'pod/ozone-scm-.* scm.SCMCommonPlacementPolicy: Unable to find enough nodes that meet the space requirement of'

"${integration_dir}/divider.sh" "Finished fetching errors of all containers"
echo "No error is found."
