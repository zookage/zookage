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

run_wordcount_job() {
  local path_prefix=${1:-/user/zookage}
  local name="a MR job"
  local success_message="The test job succeeded."
  local input="${path_prefix}/mr-wordcount-input"
  local output="${path_prefix}/mr-wordcount-output"

  if [[ "${path_prefix}" != "/user/zookage" ]]; then
    name="${name} on ${path_prefix}"
    success_message="The S3 test job succeeded on ${path_prefix}."
  fi

  "${integration_dir}/divider.sh" "Start running ${name}"

  "${integration_dir}/run.sh" hadoop fs -rm -r -f "${input}"
  "${integration_dir}/run.sh" hadoop fs -rm -r -f "${output}"
  "${integration_dir}/run.sh" hadoop fs -put /etc/hosts "${input}"

  "${integration_dir}/run.sh" bash -c "
    hadoop \
    jar \
    /opt/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-*.jar \
    wordcount \
    -libjars \"\$(printf '%s,%s' /opt/hadoop/share/hadoop/tools/lib/hadoop-aws-*.jar /opt/hadoop/share/hadoop/tools/lib/bundle-*.jar)\" \
    ${input} \
    ${output}
  "
  "${integration_dir}/run.sh" hadoop fs -cat "${output}/part-r-00000"

  "${integration_dir}/divider.sh" "Finished running ${name}"
  echo "${success_message}"
  echo
}

run_wordcount_job

ensure_s3_bucket test
run_wordcount_job s3a://test

"${integration_dir}/mr_log.sh"
