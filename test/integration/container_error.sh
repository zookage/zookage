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
readonly base_dir=$(dirname "$(dirname "${integration_dir}")")

"${integration_dir}/divider.sh" "Start fetching errors of all containers"

# shellcheck disable=SC2016
! "${base_dir}/bin/logs" | grep ERROR \
  | grep -v 'pod/hive-hiveserver2-.* metadata.Hive: .*mofu_tez not found' \
  | grep -v 'pod/hive-hiveserver2-.* metadata.Hive: .*mofu_mr not found' \
  | grep -v 'pod/zookeeper-server-.* org.apache.zookeeper.server.quorum.Learner -- Unexpected exception, connectToLeader exceeded' \
  | grep -v 'pod/zookeeper-server-.* org.apache.zookeeper.server.quorum.Learner -- Failed connect to' \
  | grep -v 'pod/zookeeper-server-.* org.apache.zookeeper.server.quorum.QuorumCnxManager -- Exception while listening to address'

"${integration_dir}/divider.sh" "Finished fetching errors of all containers"
echo "No error is found."
