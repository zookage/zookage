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

readonly test_dir=$(cd "$(dirname "$0")"; pwd)

"${test_dir}/integration/divider.sh" "Lint Dockerfiles"
"${test_dir}/hadolint.sh"
echo "All Dockerfiles look good!"

"${test_dir}/integration/divider.sh" "Lint shell scripts"
"${test_dir}/shellcheck.sh"
echo "All shell scripts look good!"

"${test_dir}/integration/divider.sh" "Lint YAML files"
"${test_dir}/yamllint.sh"
echo "All YAML files look good!"

"${test_dir}/integration/divider.sh" "Lint license headers"
"${test_dir}/license.sh"
echo "All license headers look good!"
