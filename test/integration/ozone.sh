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
# shellcheck source=/mnt/test/integration/s3.sh
source "${integration_dir}/s3.sh"

"${integration_dir}/divider.sh" "Start running Ozone commands"

"${integration_dir}/run.sh" bash -c "ozone sh volume info zookage > /dev/null 2>&1 || ozone sh volume create zookage"
"${integration_dir}/run.sh" bash -c "ozone sh bucket info zookage/test > /dev/null 2>&1 || ozone sh bucket create zookage/test"
"${integration_dir}/run.sh" bash -c "ozone sh key put zookage/test/hosts /etc/hosts"
"${integration_dir}/run.sh" bash -c "ozone sh key cat zookage/test/hosts"

if [[ ${ZOOKAGE_TEST_MODE:-} == "auth" ]]; then
  for pod_and_cert_dir in \
    "ozone-scm-0:/mnt/ozone/scm/sub-ca/certs" \
    "ozone-om-0:/mnt/ozone/om/certs" \
    "ozone-datanode-0:/mnt/ozone/dn/certs" \
    "ozone-datanode-1:/mnt/ozone/dn/certs" \
    "ozone-datanode-2:/mnt/ozone/dn/certs" \
    "ozone-recon-0:/mnt/ozone/recon/certs"; do
    pod=${pod_and_cert_dir%%:*}
    cert_dir=${pod_and_cert_dir#*:}
    echo "Check valid signed certificate in ${pod}"
    # shellcheck disable=SC2016
    "${base_dir}/bin/kubectl" exec "${pod}" -- sh -c \
      'for cert in "$1"/[0-9]*.crt; do
         if test -s "$cert" && openssl x509 -checkend 0 -noout -in "$cert"; then
           exit 0
         fi
       done
       exit 1' sh "${cert_dir}"
  done

  if "${integration_dir}/run.sh" env KRB5CCNAME=FILE:/dev/null \
    ozone sh volume info zookage; then
    echo "Ozone unexpectedly accepted a client without a Kerberos ticket" >&2
    exit 1
  fi
fi

ensure_s3_bucket test
"${integration_dir}/run.sh" bash -c "aws s3 --endpoint http://ozone-s3g:9878 cp /etc/hosts s3://test/hosts"
"${integration_dir}/run.sh" bash -c "aws s3 --endpoint http://ozone-s3g:9878 cp s3://test/hosts /tmp/hosts"
"${integration_dir}/run.sh" bash -c "diff /etc/hosts /tmp/hosts"

if [[ ${ZOOKAGE_TEST_MODE:-} == "auth" ]]; then
  if "${integration_dir}/run.sh" env AWS_SECRET_ACCESS_KEY=invalid-s3-secret \
    aws s3api --endpoint-url http://ozone-s3g:9878 head-bucket --bucket test; then
    echo "Ozone S3 unexpectedly accepted an invalid secret" >&2
    exit 1
  fi
fi

"${integration_dir}/divider.sh" "Finished running Ozone commands"

echo "The test commands succeeded."
echo
