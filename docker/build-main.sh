#!/bin/bash
set -eu

# shellcheck disable=SC2034
ZOOKAGE_DIR=./
# shellcheck source=/mnt/docker/prepare.sh
source ./docker/prepare.sh ZOOKAGE_DIR

docker build \
  --tag "${DOCKER_IMAGE_NAME_PREFIX}/zookage-main:${image_tag}" \
  --build-arg "openjdk_image=${OPENJDK_8_IMAGE}" \
  --file ./docker/main/Dockerfile \
  ./docker/main
