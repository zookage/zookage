#!/bin/bash
set -eu

source ./docker/prepare.sh HADOOP_SOURCE_DIR

docker build \
  --tag ${DOCKER_IMAGE_NAME_PREFIX}/hadoop-build:${image_tag} \
  --file ${HADOOP_SOURCE_DIR}/dev-support/docker/Dockerfile \
  ${HADOOP_SOURCE_DIR}/dev-support/docker

active_profiles=dist
if [[ ${HADOOP_BUILD_NATIVE} == true ]]; then
  active_profiles=${active_profiles},native
fi
if [[ ${HADOOP_BUILD_YARN_UI_V2} == true ]]; then
  active_profiles=${active_profiles},yarn-ui
fi

docker build \
  --tag ${DOCKER_IMAGE_NAME_PREFIX}/hadoop-sandbox-hadoop:${image_tag} \
  --build-arg hadoop_build_image=hadoop-build:${image_tag} \
  --build-arg active_profiles=${active_profiles} \
  --file ./docker/hadoop/Dockerfile \
  ${HADOOP_SOURCE_DIR}
