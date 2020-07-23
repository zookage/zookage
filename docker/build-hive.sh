#!/bin/bash
set -eu

source ./docker/prepare.sh HIVE_SOURCE_DIR

docker build \
  --tag ${DOCKER_IMAGE_NAME_PREFIX}/hadoop-sandbox-hive:${image_tag} \
  --file ./docker/hive/Dockerfile \
  ${HIVE_SOURCE_DIR}
