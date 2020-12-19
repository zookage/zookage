#!/bin/bash
set -eu

readonly SHELLCHECK_VERSION=v0.7.1
readonly base_dir=$(dirname "$(cd "$(dirname "$0")" || exit; pwd)")

docker \
  run \
  --rm \
  -v "${base_dir}:/mnt" "koalaman/shellcheck-alpine:${SHELLCHECK_VERSION}" \
  sh -c "shellcheck -x /mnt/bin/*"

docker \
  run \
  --rm \
  -v "${base_dir}:/mnt" "koalaman/shellcheck-alpine:${SHELLCHECK_VERSION}" \
  sh -c "shellcheck -x /mnt/**/*.sh"
