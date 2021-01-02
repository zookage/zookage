#!/bin/bash
set -eu

readonly test_dir=$(cd "$(dirname "$0")"; pwd)

"${test_dir}/integration/divider.sh" "Lint Dockerfiles"
"${test_dir}/hadolint.sh"
echo "All Dockerfiles look good!"

"${test_dir}/integration/divider.sh" "Lint shell scripts"
"${test_dir}/shellcheck.sh"
echo "All shell scripts look good!"

"${test_dir}/integration/divider.sh" "Lint YAML files"
"${test_dir}/yamllint.sh"
echo "All YAML files look good!"
