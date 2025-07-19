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

export DOCKER_BUILDKIT=1
# shellcheck source=/mnt/docker/sample-build.env
source ./docker/build.env

readonly workspace=$(eval echo \$"${1}")
readonly branch_name=$(git -C "${workspace}" branch --show-current)
if [ -n "${branch_name}" ]; then
  readonly default_image_tag=${branch_name}
else
  readonly default_image_tag=$(git -C "${workspace}" rev-parse HEAD)
fi

read -r -p "Docker image tag [${default_image_tag}]: " image_tag
readonly image_tag=${image_tag:-${default_image_tag}}
