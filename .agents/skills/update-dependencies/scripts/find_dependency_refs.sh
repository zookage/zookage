#!/bin/bash
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -eu

usage() {
  echo "Usage: $0 [pattern]" >&2
  echo "Without a pattern, print the common dependency pin locations in this repository." >&2
  echo "With a pattern, search Docker, Kubernetes, test, CI, and console Maven files for matching refs." >&2
}

if [ "$#" -gt 1 ]; then
  usage
  exit 1
fi

readonly skill_dir=$(cd "$(dirname "$0")/.."; pwd)
readonly repo_root=$(git -C "${skill_dir}" rev-parse --show-toplevel)

cd "${repo_root}"

if [ "$#" -eq 1 ]; then
  readonly matches_file=$(mktemp)
  trap 'rm -f "${matches_file}"' EXIT

  if ! rg -n "$1" docker kubernetes test .github/workflows/ci.yaml console/pom.xml > "${matches_file}"; then
    exit 1
  fi

  readonly likely_pin_pattern='docker run|image:|newTag:|newName:|_IMAGE=|ARG .*version|FROM |--build-arg|uses:|java-version:|<[A-Za-z0-9_.-]+version>|<maven.compiler.release>'
  if grep -Eq "${likely_pin_pattern}" "${matches_file}"; then
    echo "Likely version pins"
    grep -E "${likely_pin_pattern}" "${matches_file}"
  fi

  if grep -Evq "${likely_pin_pattern}" "${matches_file}"; then
    if grep -Eq "${likely_pin_pattern}" "${matches_file}"; then
      echo
    fi
    echo "Other matches"
    grep -Ev "${likely_pin_pattern}" "${matches_file}"
  fi

  exit 0
fi

echo "Base build image pins"
rg -n "^(DOCKER_IMAGE_NAME_PREFIX|[A-Z0-9_]+_IMAGE)=" docker/sample-build.env || true
echo

echo "Dockerfile-local version arguments and base images"
rg -n "ARG .*version|^FROM " docker/*/Dockerfile || true
echo

echo "Kustomize-managed runtime image tags"
rg -n "newTag:" kubernetes/kustomization.yaml test/kubernetes || true
echo

echo "Direct tool and manifest image pins"
rg -n "hadolint/hadolint|skywalking-eyes|tomcat:" test kubernetes/base || true
echo

echo "GitHub Actions workflow pins"
rg -n "uses:|java-version:" .github/workflows/ci.yaml || true
echo

echo "Console Maven versions"
rg -n "<[A-Za-z0-9_.-]+version>|<maven.compiler.release>" console/pom.xml || true
