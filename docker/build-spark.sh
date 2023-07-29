#!/bin/bash
set -eu

# shellcheck source=/mnt/docker/prepare.sh
source ./docker/prepare.sh SPARK_SOURCE_DIR

docker build \
  --tag "${DOCKER_IMAGE_NAME_PREFIX}/spark-rm:${image_tag}" \
  --build-arg UID=999 \
  --file "${SPARK_SOURCE_DIR}/dev/create-release/spark-rm/Dockerfile" \
  "${SPARK_SOURCE_DIR}/dev/create-release/spark-rm"

docker build \
  --tag "${DOCKER_IMAGE_NAME_PREFIX}/zookage-spark:${image_tag}" \
  --build-arg "spark_rm_image=${DOCKER_IMAGE_NAME_PREFIX}/spark-rm:${image_tag}" \
  --build-arg "jdk_image=${JDK_8_IMAGE}" \
  --file ./docker/spark/Dockerfile \
  "${SPARK_SOURCE_DIR}"
