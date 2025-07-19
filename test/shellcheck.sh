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

readonly SHELLCHECK_VERSION=v0.7.1
readonly base_dir=$(dirname "$(cd "$(dirname "$0")" || exit; pwd)")

docker \
  run \
  --rm \
  -v "${base_dir}:/mnt" "koalaman/shellcheck-alpine:${SHELLCHECK_VERSION}" \
  sh -c "shellcheck -x /mnt/bin/*"

docker \
  run \
  --rm \
  -v "${base_dir}:/mnt" "koalaman/shellcheck-alpine:${SHELLCHECK_VERSION}" \
  sh -c "find /mnt -name '*.sh' | xargs shellcheck -x"
