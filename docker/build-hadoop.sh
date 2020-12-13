#!/bin/bash
set -eu

source ./docker/prepare.sh HADOOP_SOURCE_DIR
source ./docker/prepare-maven.sh

active_profiles=dist

read -p "Build native libraries? [Y/n]: " native
case "$native" in
  y|Y|yes|"" ) active_profiles=${active_profiles},native;;
  n|N|no ) ;;
  * ) echo "Please input y or n"; exit 1;;
esac

read -p "Build YARN UI V2? [Y/n]: " yarn_ui_v2
case "$yarn_ui_v2" in
  y|Y|yes|"" ) active_profiles=${active_profiles},yarn-ui;;
  n|N|no ) ;;
  * ) echo "Please input y or n"; exit 1;;
esac

docker build \
  --tag ${DOCKER_IMAGE_NAME_PREFIX}/hadoop-build:${image_tag} \
  --file ${HADOOP_SOURCE_DIR}/dev-support/docker/Dockerfile \
  ${HADOOP_SOURCE_DIR}/dev-support/docker

docker build \
  --tag ${DOCKER_IMAGE_NAME_PREFIX}/hadoop-sandbox-hadoop:${image_tag} \
  --build-arg hadoop_build_image=${DOCKER_IMAGE_NAME_PREFIX}/hadoop-build:${image_tag} \
  --build-arg openjdk_image=${OPENJDK_8_IMAGE} \
  --build-arg clean=${clean} \
  --build-arg active_profiles=${active_profiles} \
  --file ./docker/hadoop/Dockerfile \
  ${HADOOP_SOURCE_DIR}
