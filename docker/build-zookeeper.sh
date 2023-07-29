#!/bin/bash
set -eu

# shellcheck source=/mnt/docker/prepare.sh
source ./docker/prepare.sh ZOOKEEPER_SOURCE_DIR
# shellcheck source=/mnt/docker/prepare-maven.sh
source ./docker/prepare-maven.sh

docker build \
  --tag "${DOCKER_IMAGE_NAME_PREFIX}/zookage-zookeeper:${image_tag}" \
  --build-arg "maven_image=${MAVEN_3_IMAGE}" \
  --build-arg "jdk_image=${JDK_8_IMAGE}" \
  --build-arg "clean=${clean}" \
  --file ./docker/zookeeper/Dockerfile \
  "${ZOOKEEPER_SOURCE_DIR}"
