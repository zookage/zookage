#!/bin/bash
set -eu

while IFS= read -r -d '' dockerfile
do
  echo "$dockerfile"
  docker run --rm -i hadolint/hadolint:v2.12.0 < "$dockerfile"
done < <(find . -name Dockerfile -print0)
