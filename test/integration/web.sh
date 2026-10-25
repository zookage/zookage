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

spark_jws () {
  python3 - "${base_dir}/bin/kubectl" "${1:-300}" <<'PY'
import base64
import hashlib
import hmac
import json
import subprocess
import sys
import time


def base64url(value):
    return base64.urlsafe_b64encode(value).rstrip(b"=").decode("ascii")


encoded_key = subprocess.check_output(
    [sys.argv[1], "exec", "client-node-0", "-c", "sleep", "--", "printenv", "SPARK_JWS_SECRET_KEY"],
    text=True,
).strip()
key = base64.urlsafe_b64decode(encoded_key + "=" * (-len(encoded_key) % 4))
header = base64url(b'{"alg":"HS256","typ":"JWT"}')
payload = base64url(json.dumps({"exp": int(time.time()) + int(sys.argv[2])}).encode())
signed = f"{header}.{payload}"
signature = base64url(hmac.new(key, signed.encode("ascii"), hashlib.sha256).digest())
print(f"{signed}.{signature}")
PY
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
if [[ ${ZOOKAGE_TEST_MODE:-} == "auth" ]]; then
  for endpoint in \
    "ozone-om-0.ozone-om.zookage.svc.cluster.local:9874" \
    "ozone-scm-0.ozone-scm.zookage.svc.cluster.local:9876" \
    "ozone-datanode-0.ozone-datanode.zookage.svc.cluster.local:9882" \
    "ozone-recon-0.ozone-recon.zookage.svc.cluster.local:9888"; do
    check "http://${endpoint}/index.html" "401" \
      "${base_dir}/bin/kubectl" exec client-node-0 -- curl
    check "http://${endpoint}/index.html" "200" \
      "${base_dir}/bin/kubectl" exec client-node-0 -- curl --negotiate -u :
  done
else
  check "http://localhost:9874/#!/"
  check "http://localhost:9876/#!/"
  check "http://localhost:9888/#/Overview"
fi
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
else
  check "http://localhost:9999/tez-ui/"
fi
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
if [[ ${ZOOKAGE_TEST_MODE:-} == "auth" ]]; then
  check "http://localhost:18080/" "403"
  check "http://localhost:18080/" "403" \
    curl --header "Authorization: Bearer invalid"
  readonly expired_spark_jws=$(spark_jws -300)
  check "http://localhost:18080/" "403" \
    curl --header "Authorization: Bearer ${expired_spark_jws}"
  readonly valid_spark_jws=$(spark_jws)
  check "http://localhost:18080/" "200" \
    curl --header "Authorization: Bearer ${valid_spark_jws}"
  if [[ "${valid_spark_jws: -1}" == A ]]; then
    tampered_spark_jws="${valid_spark_jws%?}Q"
  else
    tampered_spark_jws="${valid_spark_jws%?}A"
  fi
  check "http://localhost:18080/" "403" \
    curl --header "Authorization: Bearer ${tampered_spark_jws}"
else
  check "http://localhost:18080/"
fi
check "http://localhost:8090/ui/"
check "http://localhost:8080/admin/master/console/"
check "http://localhost:6080/login.jsp"
