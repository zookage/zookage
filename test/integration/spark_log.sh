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
sleep 5

readonly id=$("${integration_dir}/run.sh" yarn application -list -appStates FINISHED 2> /dev/null | cut -f 1 | sort | tail -n 1)
echo "Check errors and warnings of ${id}"

"${integration_dir}/divider.sh" "Start checking errors of a Spark job"
"${integration_dir}/run.sh" bash -c "
  ! yarn logs -applicationId '${id}' | grep 'ERROR'
"
"${integration_dir}/divider.sh" "Finished checking errors of a Spark job"
echo "No error is found."

"${integration_dir}/divider.sh" "Start checking warnings of a Spark job"
"${integration_dir}/run.sh" bash -c "
  ! yarn logs -applicationId '${id}' | grep 'WARN'
"
"${integration_dir}/divider.sh" "Finished checking warnings of a Spark job"
echo "No warning is found."
