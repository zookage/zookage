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
source ./docker/prepare.sh HADOOP_SOURCE_DIR
# shellcheck source=/mnt/docker/prepare-maven.sh
source ./docker/prepare-maven.sh

active_profiles=dist

read -r -p "Build native libraries? [Y/n]: " native
case "$native" in
  y|Y|yes|"" ) active_profiles=${active_profiles},native;;
  n|N|no ) ;;
  * ) echo "Please input y or n"; exit 1;;
esac

read -r -p "Build YARN UI V2? [Y/n]: " yarn_ui_v2
case "$yarn_ui_v2" in
  y|Y|yes|"" ) active_profiles=${active_profiles},yarn-ui;;
  n|N|no ) ;;
  * ) echo "Please input y or n"; exit 1;;
esac

docker build \
  --tag "${DOCKER_IMAGE_NAME_PREFIX}/hadoop-build:${image_tag}" \
  --file "${HADOOP_SOURCE_DIR}/dev-support/docker/Dockerfile" \
  "${HADOOP_SOURCE_DIR}/dev-support/docker"

docker build \
  --tag "${DOCKER_IMAGE_NAME_PREFIX}/zookage-hadoop:${image_tag}" \
  --build-arg "hadoop_build_image=${DOCKER_IMAGE_NAME_PREFIX}/hadoop-build:${image_tag}" \
  --build-arg "jdk_image=${JDK_8_IMAGE}" \
  --build-arg "clean=${clean}" \
  --build-arg active_profiles=${active_profiles} \
  --file ./docker/hadoop/Dockerfile \
  "${HADOOP_SOURCE_DIR}"
