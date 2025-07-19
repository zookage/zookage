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

check_errors () {
  ! "${integration_dir}/run.sh" yarn logs -applicationId "${id}" | grep ERROR \
    | grep -v 'IO_ERROR=0' \
    | grep -v 'DESERIALIZE_ERRORS:0' \
    | grep -v 'DESERIALIZE_ERRORS=0'
}

check_warnings () {
  ! "${integration_dir}/run.sh" yarn logs -applicationId "${id}" | grep WARN \
    | grep -v -- '-Dhadoop.metrics.log.level=WARN' \
    | grep -v 'log4j:WARN' \
    | grep -v 'org.apache.hadoop.metrics2.impl.MetricsSystemImpl: ReduceTask metrics system already initialized'
}

"${integration_dir}/divider.sh" "Start fetching errors of a MR job"
check_errors
"${integration_dir}/divider.sh" "Finished fetching errors of a MR job"
echo "No error is found."

"${integration_dir}/divider.sh" "Start fetching warnings of a MR job"
check_warnings
"${integration_dir}/divider.sh" "Finished fetching warnings of a MR job"
echo "No warning is found."
