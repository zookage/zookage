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

"${integration_dir}/divider.sh" "Start running an HBase command"
"${integration_dir}/run.sh" hbase shell --noninteractive <<EOF
  if !exists('test')
    create 'test', 'cf'
  end
  desc 'test'
  put 'test', 'row-key-test', 'cf:value', 'value-test'
  get 'test', 'row-key-test'
EOF
"${integration_dir}/divider.sh" "Finished running an HBase command"

echo "The test command succeeded."
echo
