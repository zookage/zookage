#!/bin/bash
set -eu

# shellcheck source=/mnt/docker/prepare.sh
source ./docker/prepare.sh HIVE_SOURCE_DIR
# shellcheck source=/mnt/docker/prepare-maven.sh
source ./docker/prepare-maven.sh

docker build \
  --tag "${DOCKER_IMAGE_NAME_PREFIX}/hadoop-sandbox-hive:${image_tag}" \
  --build-arg "maven_image=${MAVEN_3_IMAGE}" \
  --build-arg "openjdk_image=${OPENJDK_8_IMAGE}" \
  --build-arg "clean=${clean}" \
  --file ./docker/hive/Dockerfile \
  "${HIVE_SOURCE_DIR}"
