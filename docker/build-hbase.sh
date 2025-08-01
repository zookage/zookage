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

# shellcheck source=/mnt/docker/prepare.sh
source ./docker/prepare.sh HBASE_SOURCE_DIR
# shellcheck source=/mnt/docker/prepare-maven.sh
source ./docker/prepare-maven.sh

read -r -p "Hadoop version: " hadoop_three_version

docker build \
  --tag "${DOCKER_IMAGE_NAME_PREFIX}/zookage-hbase:${image_tag}" \
  --build-arg "maven_image=${MAVEN_3_IMAGE}" \
  --build-arg "jdk_image=${JDK_8_IMAGE}" \
  --build-arg "clean=${clean}" \
  --build-arg "hadoop_three_version=${hadoop_three_version}" \
  --file ./docker/hbase/Dockerfile \
  "${HBASE_SOURCE_DIR}"
