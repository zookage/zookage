#!/bin/bash
set -eu

# shellcheck source=/mnt/docker/prepare.sh
source ./docker/prepare.sh TRINO_SOURCE_DIR
# shellcheck source=/mnt/docker/prepare-maven.sh
source ./docker/prepare-maven.sh

docker build \
  --tag "${DOCKER_IMAGE_NAME_PREFIX}/zookage-trino:${image_tag}" \
  --build-arg "jdk_image=${JDK_17_IMAGE}" \
  --build-arg "clean=${clean}" \
  --file ./docker/trino/Dockerfile \
  "${TRINO_SOURCE_DIR}"
