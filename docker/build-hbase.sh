#!/bin/bash
set -eu

# shellcheck source=/mnt/docker/prepare.sh
source ./docker/prepare.sh HBASE_SOURCE_DIR
# shellcheck source=/mnt/docker/prepare-maven.sh
source ./docker/prepare-maven.sh

read -r -p "Hadoop version: " hadoop_three_version

docker build \
  --tag "${DOCKER_IMAGE_NAME_PREFIX}/zookage-hbase:${image_tag}" \
  --build-arg "maven_image=${MAVEN_3_IMAGE}" \
  --build-arg "jdk_image=${JDK_8_IMAGE}" \
  --build-arg "clean=${clean}" \
  --build-arg "hadoop_three_version=${hadoop_three_version}" \
  --file ./docker/hbase/Dockerfile \
  "${HBASE_SOURCE_DIR}"
