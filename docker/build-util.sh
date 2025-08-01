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

# shellcheck disable=SC2034
ZOOKAGE_DIR=./
# shellcheck source=/mnt/docker/prepare.sh
source ./docker/prepare.sh ZOOKAGE_DIR

docker build \
  --tag "${DOCKER_IMAGE_NAME_PREFIX}/zookage-util:${image_tag}" \
  --build-arg "jdk_image=${JDK_8_IMAGE}" \
  --file ./docker/util/Dockerfile \
  ./docker/util
