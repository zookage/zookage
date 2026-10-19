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
readonly repo_dir=$(cd "${integration_dir}/../.."; pwd)

check_datanode_user() {
  awk '
    /^Uid:/ {
      found = 1
      if ($2 != 1011 || $3 != 1011 || $4 != 1011 || $5 != 1011) exit 1
    }
    END { if (!found) exit 1 }
  ' /proc/1/status
}

check_hdfs_security() {
  readonly security_dir=$(mktemp -d)
  readonly test_name="security-$(date +%s)-$$-${RANDOM}"
  readonly test_path="/user/zookage/${test_name}"
  readonly ticket_cache="FILE:${security_dir}/user.ccache"
  readonly empty_cache="FILE:${security_dir}/missing.ccache"
  readonly token_file="${security_dir}/delegation.token"
  readonly httpfs="http://hdfs-httpfs.zookage.svc.cluster.local:14000/webhdfs/v1"
  readonly namenode="https://hdfs-namenode-0.hdfs-namenode.zookage.svc.cluster.local:9871/webhdfs/v1"
  readonly ca_certificate=/etc/hadoop/conf/hdfs-ca.crt
  export KRB5CCNAME="${ticket_cache}"
  unset HADOOP_TOKEN_FILE_LOCATION HADOOP_USER_NAME

  cleanup() {
    local status=$?
    hdfs dfs -rm -r -f -skipTrash "${test_path}" || status=1
    rm -rf "${security_dir}"
    exit "${status}"
  }
  trap cleanup EXIT

  expect_rejected() {
    local reason=$1
    local output
    shift
    if output=$("$@" 2>&1); then
      echo "Unexpected HDFS access: ${reason}" >&2
      exit 1
    fi
    case "${output}" in
      *Kerberos*|*kerberos*|*authenticate*|*authentication*|*SASL*|*token*|*Token*) ;;
      *)
        echo "Expected an authentication failure (${reason}): ${output}" >&2
        exit 1
        ;;
    esac
    echo "HDFS rejected ${reason}."
  }

  [[ "$(hdfs getconf -confKey hadoop.security.authentication)" == "kerberos" ]]
  kinit -kt /etc/kerberos/secrets/client.keytab zookage@ZOOKAGE.LOCAL
  hdfs dfs -mkdir "${test_path}"
  printf '%s\n' "${test_name}" > "${security_dir}/expected"
  hdfs dfs -put "${security_dir}/expected" "${test_path}/ticket-file"
  # Download before comparing, since HA retry logs can be written to stdout.
  hdfs dfs -get "${test_path}/ticket-file" "${security_dir}/ticket-file"
  cmp "${security_dir}/expected" "${security_dir}/ticket-file"

  expect_rejected "an RPC request without a ticket" \
    env KRB5CCNAME="${empty_cache}" hdfs dfs -ls /
  expect_rejected "a SIMPLE client impersonating hdfs" \
    env KRB5CCNAME="${empty_cache}" HADOOP_USER_NAME=hdfs \
    hdfs dfs -Dhadoop.security.authentication=simple -ls /

  hdfs fetchdt --renewer zookage "${token_file}"
  hdfs fetchdt --renew "${token_file}"
  KRB5CCNAME="${empty_cache}" HADOOP_TOKEN_FILE_LOCATION="${token_file}" \
    hdfs dfs -get "${test_path}/ticket-file" "${security_dir}/token-file"
  cmp "${security_dir}/expected" "${security_dir}/token-file"
  hdfs fetchdt --cancel "${token_file}"
  expect_rejected "a cancelled delegation token" \
    env KRB5CCNAME="${empty_cache}" HADOOP_TOKEN_FILE_LOCATION="${token_file}" \
    hdfs dfs -Dipc.client.connect.max.retries=0 -Dipc.client.connect.max.retries.on.sasl=0 \
    -cat "${test_path}/ticket-file"

  local endpoint
  for endpoint in "${httpfs}" "${namenode}"; do
    echo "Checking WebHDFS authentication and file reads at ${endpoint}."
    [[ "$(curl -sS --cacert "${ca_certificate}" -o /dev/null -w '%{http_code}' \
      "${endpoint}/?op=LISTSTATUS&user.name=hdfs")" == "401" ]]
    curl -fsS --cacert "${ca_certificate}" --negotiate -u : \
      "${endpoint}${test_path}/ticket-file?op=GETFILESTATUS"
    [[ "$(curl -fsSL --proto-redir =https --cacert "${ca_certificate}" --negotiate -u : \
      "${endpoint}${test_path}/ticket-file?op=OPEN")" == "${test_name}" ]]
  done

  # WebHDFS CREATE first authenticates to the NameNode, then uploads to the
  # HTTPS DataNode using the delegation token in the redirect URL.
  [[ "$(curl -sS --cacert "${ca_certificate}" --negotiate -u : \
    -X PUT -H 'X-XSRF-HEADER: 1' -H 'Content-Length: 0' -D "${security_dir}/create.headers" \
    -o /dev/null -w '%{http_code}' \
    "${namenode}${test_path}/webhdfs-file?op=CREATE&overwrite=true")" == "307" ]]
  local redirect
  redirect=$(awk 'tolower($1) == "location:" { sub(/\r$/, "", $2); print $2 }' \
    "${security_dir}/create.headers")
  [[ "${redirect}" == https://* ]]
  [[ "$(printf '%s\n' "${test_name}" | \
    curl -sS --cacert "${ca_certificate}" -X PUT -H 'X-XSRF-HEADER: 1' \
      -H 'Content-Type: application/octet-stream' \
      --data-binary @- -o /dev/null -w '%{http_code}' "${redirect}")" == "201" ]]
  hdfs dfs -get "${test_path}/webhdfs-file" "${security_dir}/webhdfs-file"
  cmp "${security_dir}/expected" "${security_dir}/webhdfs-file"
}

"${integration_dir}/divider.sh" "Start checking HDFS security"
pods=$("${repo_dir}/bin/kubectl" get pods -l component=hdfs,service=datanode -o name)
[[ -n "${pods}" ]]
while IFS= read -r pod; do
  "${repo_dir}/bin/kubectl" exec "${pod}" -c datanode -- \
    bash -eu -c "$(declare -f check_datanode_user); check_datanode_user"
done <<< "${pods}"
"${integration_dir}/run.sh" bash -eu -c "$(declare -f check_hdfs_security); check_hdfs_security"
"${integration_dir}/divider.sh" "Finished checking HDFS security"

echo "The HDFS security checks succeeded."
echo
