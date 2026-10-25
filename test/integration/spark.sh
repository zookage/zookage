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
# shellcheck source=/mnt/test/integration/s3.sh
source "${integration_dir}/s3.sh"

if [[ ${ZOOKAGE_TEST_MODE:-} == "auth" ]]; then
  "${integration_dir}/divider.sh" "Check Spark authentication and RPC encryption settings"
  # Variables inside this script expand in the client container.
  # shellcheck disable=SC2016
  "${integration_dir}/run.sh" bash -c '
    conf="${SPARK_CONF_DIR:?}/spark-defaults.conf"
    settings=(
      "spark.authenticate true"
      "spark.network.crypto.enabled true"
      "spark.network.crypto.cipher AES/GCM/NoPadding"
      "spark.network.crypto.authEngineVersion 2"
      "spark.ui.filters org.apache.spark.ui.JWSFilter"
    )
    for setting in "${settings[@]}"; do
      if ! grep -Fxq -- "${setting}" "${conf}"; then
        echo "Missing Spark security setting: ${setting}" >&2
        exit 1
      fi
    done
  '
fi

run_wordcount_job() {
  local path_prefix=${1:-/user/zookage}
  local name="a Spark job"
  local success_message="The test job succeeded."
  local input="${path_prefix}/spark-wordcount-input"
  local -a spark_options=(--class org.apache.spark.examples.JavaWordCount)

  if [[ "${path_prefix}" != "/user/zookage" ]]; then
    name="${name} on ${path_prefix}"
    success_message="The S3 test job succeeded on ${path_prefix}."
  fi

  "${integration_dir}/divider.sh" "Start running ${name}"

  "${integration_dir}/run.sh" hadoop fs -rm -r -f "${input}"
  "${integration_dir}/run.sh" hadoop fs -put /etc/hosts "${input}"
  if [[ ${ZOOKAGE_TEST_MODE:-} == "auth" ]]; then
    spark_options=(
      --principal zookage@ZOOKAGE.LOCAL
      --keytab /etc/secrets/client/client.keytab
      "${spark_options[@]}"
    )
  fi
  # Variables inside this script expand in the client container.
  # shellcheck disable=SC2016
  "${integration_dir}/run.sh" bash -c '
    input=$1
    mode=$2
    shift 2
    if [[ ${mode} == "auth" ]]; then
      # The job must acquire Kerberos credentials from its keytab.
      export KRB5CCNAME="FILE:/tmp/zookage-spark-no-ticket-$$-${RANDOM}"
      test ! -e "${KRB5CCNAME#FILE:}" || exit 1
    fi
    spark-submit "$@" /opt/spark/examples/jars/spark-examples_*.jar "${input}"
  ' _ "${input}" "${ZOOKAGE_TEST_MODE:-}" "${spark_options[@]}"
  "${integration_dir}/divider.sh" "Finished running ${name}"
  echo "${success_message}"
  echo
}

run_wordcount_job

ensure_s3_bucket test
run_wordcount_job s3a://test

"${integration_dir}/spark_log.sh"
