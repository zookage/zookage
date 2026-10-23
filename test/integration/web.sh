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

if [[ ${ZOOKAGE_TEST_MODE:-} == "auth" ]]; then
  check "http://localhost:14000/webhdfs/v1/?op=liststatus&user.name=zookage" "401"
  check "http://hdfs-httpfs.zookage.svc.cluster.local:14000/webhdfs/v1/?op=liststatus" "200" \
    "${base_dir}/bin/kubectl" exec client-node-0 -- curl --negotiate -u :
  readonly namenode_host=hdfs-namenode.zookage.svc.cluster.local
  check "https://${namenode_host}:9871/dfshealth.html" "401" \
    curl --noproxy "${namenode_host}" --resolve "${namenode_host}:9871:127.0.0.1" \
    --cacert "${base_dir}/kubernetes/base/common/config/tls/zookage-ca.crt"
  check "https://hdfs-namenode-0.hdfs-namenode.zookage.svc.cluster.local:9871/dfshealth.html" "200" \
    "${base_dir}/bin/kubectl" exec client-node-0 -- \
    curl --cacert /etc/hadoop/conf/zookage-ca.crt --negotiate -u :
else
  check "http://localhost:14000/webhdfs/v1/?op=liststatus&user.name=zookage"
  check "http://localhost:9870/dfshealth.html"
fi
check "http://localhost:3000/"
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
if [[ ${ZOOKAGE_TEST_MODE:-} == "auth" ]]; then
  check "http://localhost:19888/jobhistory" "401"
  check "http://mapreduce-historyserver-0.mapreduce-historyserver.zookage.svc.cluster.local:19888/jobhistory" "200" \
    "${base_dir}/bin/kubectl" exec client-node-0 -- curl --negotiate -u :
else
  check "http://localhost:19888/jobhistory"
fi
if [[ ${ZOOKAGE_TEST_MODE:-} == "auth" ]]; then
  check "http://localhost:9999/tez-ui/" "401"
  check "http://tez-ui.zookage.svc.cluster.local:9999/tez-ui/" "200" \
    "${base_dir}/bin/kubectl" exec client-node-0 -- curl --negotiate -u :
  readonly tez_ui_config_url=http://tez-ui.zookage.svc.cluster.local:9999/tez-ui/config/configs.js
  tez_ui_config=$("${base_dir}/bin/kubectl" exec client-node-0 -- \
    curl -fsS --negotiate -u : "${tez_ui_config_url}")
  readonly tez_ui_origin=http://tez-ui.zookage.svc.cluster.local:9999
  for endpoint in \
    yarn-timelineserver-0.yarn-timelineserver.zookage.svc.cluster.local:8188/applicationhistory \
    yarn-resourcemanager-0.yarn-resourcemanager.zookage.svc.cluster.local:8088/ws/v1/cluster/info; do
    echo "Check ${endpoint} allows the Tez UI origin"
    headers=$("${base_dir}/bin/kubectl" exec client-node-0 -- curl -fsS -D - -o /dev/null \
      --negotiate -u : -H "Origin: ${tez_ui_origin}" "http://${endpoint}")
    printf '%s\n' "${headers}" | grep -Fiq "Access-Control-Allow-Origin: ${tez_ui_origin}"
    printf '%s\n' "${headers}" | grep -Fiq "Access-Control-Allow-Credentials: true"
  done
  for origin in http://localhost:9999 http://tez-ui.zookage:9999; do
    for endpoint in \
      yarn-timelineserver-0.yarn-timelineserver.zookage.svc.cluster.local:8188/applicationhistory \
      yarn-resourcemanager-0.yarn-resourcemanager.zookage.svc.cluster.local:8088/ws/v1/cluster/info; do
      echo "Check ${endpoint} allows ${origin}"
      headers=$("${base_dir}/bin/kubectl" exec client-node-0 -- curl -fsS -D - -o /dev/null \
        --negotiate -u : -H "Origin: ${origin}" "http://${endpoint}")
      printf '%s\n' "${headers}" | grep -Fiq "Access-Control-Allow-Origin: ${origin}"
    done
  done
  for yarn_ui2_origin in \
    http://localhost:8088 \
    http://yarn-resourcemanager-0.yarn-resourcemanager.zookage.svc.cluster.local:8088; do
    echo "Check Timeline Server allows ${yarn_ui2_origin}"
    headers=$("${base_dir}/bin/kubectl" exec client-node-0 -- curl -fsS -D - -o /dev/null \
      --negotiate -u : -H "Origin: ${yarn_ui2_origin}" \
      "http://yarn-timelineserver-0.yarn-timelineserver.zookage.svc.cluster.local:8188/applicationhistory")
    printf '%s\n' "${headers}" | grep -Fiq "Access-Control-Allow-Origin: ${yarn_ui2_origin}"
  done
else
  check "http://localhost:9999/tez-ui/"
  tez_ui_config=$(curl -fsS http://localhost:9999/tez-ui/config/configs.js)
  echo "Check ResourceManager allows the Tez UI origin"
  rm_headers=$(curl -fsS -D - -o /dev/null -H "Origin: http://localhost:9999" \
    "http://localhost:8088/ws/v1/cluster/info")
  printf '%s\n' "${rm_headers}" | grep -Fiq "Access-Control-Allow-Origin: http://localhost:9999"
  for origin in \
    http://localhost:9999 \
    http://localhost:8088 \
    http://yarn-resourcemanager.zookage:8088; do
    echo "Check Timeline Server allows ${origin}"
    ats_headers=$(curl -fsS -D - -o /dev/null -H "Origin: ${origin}" \
      "http://localhost:8188/applicationhistory")
    printf '%s\n' "${ats_headers}" | grep -Fiq "Access-Control-Allow-Origin: ${origin}"
  done
fi
readonly tez_ui_config
echo "Check Tez UI backend hosts"
[[ ${tez_ui_config} == *'ENV.hosts.timeline = "http://yarn-timelineserver-0.yarn-timelineserver.zookage.svc.cluster.local:8188";'* ]]
[[ ${tez_ui_config} == *'ENV.hosts.rm = "http://yarn-resourcemanager-0.yarn-resourcemanager.zookage.svc.cluster.local:8088";'* ]]
check "http://localhost:10002/"
if [[ ${ZOOKAGE_TEST_MODE:-} == "auth" ]]; then
  check "http://localhost:16010/master-status" "401"
  for ordinal in 0 1; do
    for endpoint in \
      "hbase-master-${ordinal}.hbase-master.zookage.svc.cluster.local:16010/master-status" \
      "hbase-regionserver-${ordinal}.hbase-regionserver.zookage.svc.cluster.local:16030/rs-status"; do
      check "http://${endpoint}" "401" \
        "${base_dir}/bin/kubectl" exec client-node-0 -- curl
      check "http://${endpoint}" "200" \
        "${base_dir}/bin/kubectl" exec client-node-0 -- curl --negotiate -u :
    done
  done
else
  check "http://localhost:16010/master-status"
fi
check "http://localhost:8090/ui/"
check "http://localhost:8080/admin/master/console/"
check "http://localhost:6080/login.jsp"
