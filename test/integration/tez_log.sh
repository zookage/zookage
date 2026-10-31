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
readonly app_owner=${1:-zookage}
sleep 5

applications=$("${integration_dir}/run.sh" yarn application -list -appStates FINISHED -appTypes TEZ)
id=$(printf '%s\n' "${applications}" | awk -v owner="${app_owner}" '$1 ~ /^application_/ && $4 == owner { print $1 }' | sort | tail -n 1)
if [[ -z ${id} ]]; then
  echo "No finished Tez application found for ${app_owner}." >&2
  exit 1
fi
readonly id
echo "Check errors and warnings of ${id}"

logs_file=$(mktemp)
cleanup() {
  rm -f "${logs_file}"
}
trap cleanup EXIT

"${integration_dir}/run.sh" yarn logs \
  -applicationId "${id}" -appOwner "${app_owner}" > "${logs_file}"
if ! grep -q '^LogContents:' "${logs_file}"; then
  echo "No container logs were retrieved for ${id}." >&2
  exit 1
fi

"${integration_dir}/divider.sh" "Start checking errors of a Tez job"
if grep '\[ERROR\]' "${logs_file}" \
  | grep -v '|yarn.YarnUncaughtExceptionHandler|: Thread .* threw an Exception'; then
  exit 1
fi
"${integration_dir}/divider.sh" "Finished checking errors of a Tez job"
echo "No error is found."

"${integration_dir}/divider.sh" "Start checking warnings of a Tez job"
if grep '\[WARN\]' "${logs_file}" \
    | grep -v '|retry.RetryInvocationHandler|: A failover has occurred since the start of call #.* ClientNamenodeProtocolTranslatorPB\.[A-Za-z0-9]* over hdfs-namenode-.*\.hdfs-namenode\.zookage\.svc\.cluster\.local/.*:8020' \
    | grep -v 'Could not post history event to ATS, atsPutError=6' \
    | grep -v 'Exiting TaskReporter thread with pending queue size=' \
    | grep -v '|common.AsyncDispatcher|: AsyncDispatcher thread interrupted' \
    | grep -v '|impl.MetricsConfig|: Cannot locate configuration: tried hadoop-metrics2-llaptaskscheduler.properties,hadoop-metrics2.properties' \
    | grep -v '|launcher.TezContainerLauncherImpl|:.*: org.apache.hadoop.yarn.exceptions.YarnRuntimeException: java.lang.InterruptedException' \
    | grep -v '|llap.AsyncResponseHandler|: Async response handler was interrupted' \
    | grep -v '|recovery.RecoveryService|: Ignoring error while closing summary stream' \
    | grep -v '|app.DAGAppMaster|: Failed to delete tez scratch data dir' \
    | grep -v '|objectinspector.StandardStructObjectInspector|: Trying to access' \
    | grep -v '|objectinspector.StandardStructObjectInspector|: ignoring similar errors' \
    | grep -v '|rm.YarnTaskSchedulerService|: Held container expected to be not null for a non-AM-released container' \
    | grep -v 'does not have description. Please annotate the class with' \
    | grep -v '|exec.FunctionRegistry|: iceberg_bucket function could not be registered' \
    | grep -v '|util.LoggingUtils|: Cannot set log4j global MDC' \
    | awk -v auth="${ZOOKAGE_AUTH_TEST:-}" '
      auth == "1" {
        if (/\|ipc\.Client\|: Exception encountered while connecting to the server hive-llap-[0-9]+\.hive-llap\.zookage\.svc\.cluster\.local\/.*:15004$/ && ++ignored["rpc"] == 1) next
        if (/\|security\.LlapTokenClient\|: Exception while getting delegation token, trying with kerberos login$/ && ++ignored["token"] == 1) next
        if (/\|zookeeper\.Login\|: TGT renewal thread has been interrupted and will exit\.$/ && ++ignored["renewal"] <= 2) next
      }
      { print; found = 1 }
      END { if (!found) exit 1 }
    '; then
  exit 1
fi
"${integration_dir}/divider.sh" "Finished checking warnings of a Tez job"
echo "No warning is found."
