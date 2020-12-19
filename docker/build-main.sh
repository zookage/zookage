#!/bin/bash
set -eu

# shellcheck disable=SC2034
HADOOP_SANDBOX_DIR=./
# shellcheck source=/mnt/docker/prepare.sh
source ./docker/prepare.sh HADOOP_SANDBOX_DIR

docker build \
  --tag "${DOCKER_IMAGE_NAME_PREFIX}/hadoop-sandbox-main:${image_tag}" \
  --build-arg "openjdk_image=${OPENJDK_8_IMAGE}" \
  --file ./docker/main/Dockerfile \
  ./docker/main
