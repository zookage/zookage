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

"${integration_dir}/divider.sh" "HiveServer2 rejects Beeline without a Kerberos ticket"
if "${integration_dir}/run.sh" env KRB5CCNAME="FILE:/tmp/zookage-no-ticket-$$" \
  beeline -e 'SHOW DATABASES'; then
  echo "Beeline connected to HiveServer2 without a Kerberos ticket." >&2
  exit 1
fi

"${integration_dir}/divider.sh" "HiveServer2 accepts Beeline with a Kerberos ticket"
"${integration_dir}/run.sh" beeline -e 'SHOW DATABASES'

echo "HiveServer2 Kerberos authentication checks succeeded."
echo
