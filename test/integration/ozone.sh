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

"${integration_dir}/divider.sh" "Start running Ozone commands"

"${integration_dir}/run.sh" bash -c "ozone sh volume create zookage"
"${integration_dir}/run.sh" bash -c "ozone sh bucket create zookage/test"
"${integration_dir}/run.sh" bash -c "ozone sh key put zookage/test/hosts /etc/hosts"
"${integration_dir}/run.sh" bash -c "ozone sh key cat zookage/test/hosts"

"${integration_dir}/run.sh" bash -c "ozone sh bucket create s3v/test"
"${integration_dir}/run.sh" bash -c "aws s3 --endpoint http://ozone-s3g:9878 cp /etc/hosts s3://test/hosts"
"${integration_dir}/run.sh" bash -c "aws s3 --endpoint http://ozone-s3g:9878 cp s3://test/hosts /tmp/hosts"
"${integration_dir}/run.sh" bash -c "diff /etc/hosts /tmp/hosts"

"${integration_dir}/divider.sh" "Finished running Ozone commands"

echo "The test commands succeeded."
echo
