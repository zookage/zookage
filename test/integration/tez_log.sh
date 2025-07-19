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

"${integration_dir}/divider.sh" "Start checking errors of a Tez job"
"${integration_dir}/run.sh" bash -c "
  ! yarn logs -applicationId '${id}' | grep '\[ERROR\]' \
    | grep -v '|yarn.YarnUncaughtExceptionHandler|: Thread .* threw an Exception'
"
"${integration_dir}/divider.sh" "Finished checking errors of a Tez job"
echo "No error is found."

"${integration_dir}/divider.sh" "Start checking warnings of a Tez job"
"${integration_dir}/run.sh" bash -c "
  ! yarn logs -applicationId '${id}' | grep '\[WARN\]' \
    | grep -v 'Could not post history event to ATS, atsPutError=6' \
    | grep -v 'Exiting TaskReporter thread with pending queue size=' \
    | grep -v '|common.AsyncDispatcher|: AsyncDispatcher thread interrupted' \
    | grep -v '|launcher.TezContainerLauncherImpl|:.*: org.apache.hadoop.yarn.exceptions.YarnRuntimeException: java.lang.InterruptedException' \
    | grep -v '|recovery.RecoveryService|: Ignoring error while closing summary stream' \
    | grep -v '|app.DAGAppMaster|: Failed to delete tez scratch data dir' \
    | grep -v '|objectinspector.StandardStructObjectInspector|: Trying to access' \
    | grep -v '|objectinspector.StandardStructObjectInspector|: ignoring similar errors' \
    | grep -v '|rm.YarnTaskSchedulerService|: Held container expected to be not null for a non-AM-released container' \
    | grep -v 'does not have description. Please annotate the class with' \
    | grep -v '|exec.FunctionRegistry|: iceberg_bucket function could not be registered'
"
"${integration_dir}/divider.sh" "Finished checking warnings of a Tez job"
echo "No warning is found."
