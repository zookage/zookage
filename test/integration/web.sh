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

check () {
  local -r url=$1
  echo "Check ${url}"
  local -r response=$(curl -o /dev/null -w '%{http_code}' -s "${url}")
  echo "${url} returned ${response}"
  echo
  if [ "$response" = 200 ] || [ "$response" = 307 ]; then
    return 0
  else
    return 1
  fi
}

check_kerberos () {
  local -r url=$1
  echo "Check ${url} with Kerberos"
  "${integration_dir}/run.sh" curl \
    --fail \
    --insecure \
    --negotiate \
    --output /dev/null \
    --silent \
    --user : \
    "${url}"
  echo
}

if [[ ${ZOOKAGE_PROFILE:-} == auth ]]; then
  check_kerberos "http://hdfs-httpfs.zookage.svc.cluster.local:14000/webhdfs/v1/?op=liststatus"
else
  check "http://localhost:14000/webhdfs/v1/?op=liststatus&user.name=zookage"
fi
check "http://localhost:3000/"
if [[ ${ZOOKAGE_PROFILE:-} == auth ]]; then
  check_kerberos "https://hdfs-namenode-0.hdfs-namenode.zookage.svc.cluster.local:9871/dfshealth.html"
else
  check "http://localhost:9870/dfshealth.html"
fi
check "http://localhost:9874/#!/"
check "http://localhost:9876/#!/"
check "http://localhost:9888/#/Overview"
if [[ ${ZOOKAGE_PROFILE:-} == auth ]]; then
  check_kerberos "http://yarn-resourcemanager-0.yarn-resourcemanager.zookage.svc.cluster.local:8088/cluster"
  check_kerberos "http://yarn-resourcemanager-0.yarn-resourcemanager.zookage.svc.cluster.local:8088/ui2/"
  check_kerberos "http://yarn-timelineserver-0.yarn-timelineserver.zookage.svc.cluster.local:8188/applicationhistory"
else
  check "http://localhost:8088/cluster"
  check "http://localhost:8088/ui2/"
  check "http://localhost:8188/applicationhistory"
fi
check "http://localhost:19888/jobhistory"
check "http://localhost:9999/tez-ui/"
check "http://localhost:10002/"
check "http://localhost:16010/master-status"
check "http://localhost:8090/ui/"
check "http://localhost:8080/admin/master/console/"
check "http://localhost:6080/login.jsp"
