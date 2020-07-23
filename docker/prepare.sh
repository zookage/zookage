#!/bin/bash
set -eu

export DOCKER_BUILDKIT=1
source ./docker/build.env

readonly workspace=$(eval echo \$${1})
readonly branch_name=$(git -C "${workspace}" branch --show-current)
if [ -n "${branch_name}" ]; then
  readonly default_image_tag=${branch_name}
else
  readonly default_image_tag=$(git -C ${workspace} rev-parse HEAD)
fi

read -p "Docker image tag [${default_image_tag}]: " image_tag
readonly image_tag=${image_tag:-${default_image_tag}}
