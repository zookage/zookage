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

check () {
  local -r url=$1
  local -r expected_responses=${2:-"200 307"}
  local -a curl_command=(curl)
  if [[ $# -gt 2 ]]; then
    shift 2
    curl_command=("$@")
  fi
  local response
  echo "Check ${url}"
  response=$("${curl_command[@]}" -o /dev/null -w '%{http_code}' -sS "${url}")
  echo "${url} returned ${response}"
  echo
  if [[ " ${expected_responses} " == *" ${response} "* ]]; then
    return 0
  else
    return 1
  fi
}

check "http://localhost:14000/webhdfs/v1/?op=liststatus&user.name=zookage"
check "http://localhost:3000/"
check "http://localhost:9870/dfshealth.html"
check "http://localhost:9874/#!/"
check "http://localhost:9876/#!/"
check "http://localhost:9888/#/Overview"
check "http://localhost:8088/cluster"
check "http://localhost:8088/ui2/"
if [[ ${ZOOKAGE_TEST_MODE:-} == "auth" ]]; then
  check "http://localhost:8188/applicationhistory" "401"
  check "http://yarn-timelineserver-0.yarn-timelineserver.zookage.svc.cluster.local:8188/applicationhistory" "200" \
    "${base_dir}/bin/kubectl" exec client-node-0 -- curl --negotiate -u :
else
  check "http://localhost:8188/applicationhistory"
fi
check "http://localhost:19888/jobhistory"
check "http://localhost:9999/tez-ui/"
check "http://localhost:10002/"
check "http://localhost:16010/master-status"
check "http://localhost:8090/ui/"
check "http://localhost:8080/admin/master/console/"
check "http://localhost:6080/login.jsp"
