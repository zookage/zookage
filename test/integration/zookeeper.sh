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
