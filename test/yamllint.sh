#!/bin/bash
set -eu

readonly base_dir=$(dirname "$(cd "$(dirname "$0")" || exit; pwd)")

docker run --rm -v "${base_dir}:/data" cytopia/yamllint:1.23 --strict .
