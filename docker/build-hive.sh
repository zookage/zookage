#!/bin/bash
set -eu

source ./docker/prepare.sh HIVE_SOURCE_DIR
source ./docker/prepare-maven.sh

docker build \
  --tag ${DOCKER_IMAGE_NAME_PREFIX}/hadoop-sandbox-hive:${image_tag} \
  --build-arg clean=${clean} \
  --file ./docker/hive/Dockerfile \
  ${HIVE_SOURCE_DIR}
