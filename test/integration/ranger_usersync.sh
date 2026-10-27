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
readonly expected='Using principal: admin/ranger-admin@ZOOKAGE.LOCAL and keytab: /etc/secrets/ranger/ranger.keytab'

for ((attempt = 0; attempt < 60; attempt++)); do
  usersync_logs=$("${base_dir}/bin/kubectl" logs deployment/ranger-usersync --container=ranger-usersync)
  if [[ ${usersync_logs} == *"${expected}"* ]]; then
    echo "Ranger Usersync used its Kerberos principal and keytab."
    exit 0
  fi
  sleep 1
done

echo "Ranger Usersync did not log a Kerberos keytab login attempt" >&2
exit 1
