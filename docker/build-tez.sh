#!/bin/bash
set -eu

source ./docker/prepare.sh TEZ_SOURCE_DIR
source ./docker/prepare-maven.sh

docker build \
  --tag ${DOCKER_IMAGE_NAME_PREFIX}/tez-build:${image_tag} \
  --file ${TEZ_SOURCE_DIR}/build-tools/docker/Dockerfile \
  ${TEZ_SOURCE_DIR}/build-tools/docker

docker build \
  --tag ${DOCKER_IMAGE_NAME_PREFIX}/hadoop-sandbox-tez:${image_tag} \
  --build-arg tez_build_image=${DOCKER_IMAGE_NAME_PREFIX}/tez-build:${image_tag} \
  --build-arg clean=${clean} \
  --file ./docker/tez/Dockerfile \
  ${TEZ_SOURCE_DIR}
