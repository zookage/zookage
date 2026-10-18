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

yarn_authentication=$("${integration_dir}/yarn_authentication.sh")
logs_file=$(mktemp)
hive_pod=
remote_dir=
cleanup() {
  if [[ -n ${remote_dir} ]]; then
    # shellcheck disable=SC2016
    "${base_dir}/bin/kubectl" exec "${hive_pod}" -c hiveserver2 -- /bin/sh -c \
      'rm -f -- "$1/YarnLogs.java"; rmdir -- "$1"' sh "${remote_dir}" || true
  fi
  rm -f "${logs_file}"
}
trap cleanup EXIT

if [[ ${yarn_authentication} == kerberos && ${app_owner} == hive ]]; then
  hive_pod=$("${base_dir}/bin/kubectl" get pods -l component=hive,service=hiveserver2 \
    -o 'jsonpath={.items[0].metadata.name}')
  remote_dir=$("${base_dir}/bin/kubectl" exec "${hive_pod}" -c hiveserver2 -- \
    mktemp -d /tmp/zookage-yarn-logs.XXXXXX)
  "${base_dir}/bin/kubectl" cp "${integration_dir}/YarnLogs.java" \
    "${hive_pod}:${remote_dir}/YarnLogs.java" -c hiveserver2
  # Authenticate as Hive inside HS2 without exposing its keytab to the client.
  # shellcheck disable=SC2016
  "${base_dir}/bin/kubectl" exec "${hive_pod}" -c hiveserver2 -- /bin/bash -eu -c '
    unset JAVA_TOOL_OPTIONS
    hadoop_classpath=$("${HADOOP_HOME}/bin/hadoop" classpath)
    exec "${JAVA_HOME}/bin/java" --class-path "${hadoop_classpath}" --source 11 "$@"
  ' bash "${remote_dir}/YarnLogs.java" -applicationId "${id}" -appOwner "${app_owner}" > "${logs_file}"
else
  "${integration_dir}/run.sh" env HADOOP_USER_NAME=hdfs \
    yarn logs -applicationId "${id}" -appOwner "${app_owner}" > "${logs_file}"
fi
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
    | grep -v '|retry.RetryInvocationHandler|: A failover has occurred since the start of call #.* ClientNamenodeProtocolTranslatorPB\.[A-Za-z0-9]* over hdfs-namenode-.*\.hdfs-namenode/.*:8020' \
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
    | grep -v '|util.LoggingUtils|: Cannot set log4j global MDC'; then
  exit 1
fi
"${integration_dir}/divider.sh" "Finished checking warnings of a Tez job"
echo "No warning is found."
