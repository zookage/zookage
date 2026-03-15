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

readonly script_dir=$(cd "$(dirname "$0")"; pwd)
readonly skill_dir=$(cd "${script_dir}/.."; pwd)
readonly repo_dir=$(cd "${skill_dir}/../../.."; pwd)
readonly test_dir="${repo_dir}/test"
readonly variant_dir="${test_dir}/kubernetes"
readonly target_kustomization="${repo_dir}/kubernetes/kustomization.yaml"

continue_on_failure=0
dry_run=0
list_only=0
restore_cluster=1
original_kustomization=""

usage() {
  cat <<'EOF'
Usage: run_all_variants.sh [--continue-on-failure] [--dry-run] [--list] [--no-restore-cluster]

Run ./test/integration.sh <variant> for every test/kubernetes/*.yaml variant.

Options:
  --continue-on-failure  Keep running after a failure and report all failing variants
  --dry-run              Print the commands that would run without changing the cluster
  --list                 Print the discovered variant order and exit
  --no-restore-cluster   Restore kubernetes/kustomization.yaml but skip the final down/up
  --help                 Show this message
EOF
}

collect_variants() {
  local variant_file

  shopt -s nullglob
  for variant_file in "${variant_dir}"/*.yaml; do
    variants+=("$(basename "${variant_file}" .yaml)")
  done
  shopt -u nullglob
}

print_command() {
  printf '+ '
  printf '%q ' "$@"
  printf '\n'
}

run_cmd() {
  print_command "$@"

  if [[ "${dry_run}" -eq 1 ]]; then
    return 0
  fi

  "$@"
}

run_variant() {
  local variant="$1"

  run_cmd "${test_dir}/integration.sh" "${variant}"
}

run_step() {
  local label="$1"
  shift

  echo
  echo "=== ${label} ==="

  set +e
  "$@"
  local status=$?
  set -e

  if [[ "${status}" -eq 0 ]]; then
    echo "PASS: ${label}"
  else
    echo "FAIL: ${label}"
  fi

  return "${status}"
}

cleanup() {
  local status=$?
  local cleanup_failed=0

  if [[ -z "${original_kustomization}" ]]; then
    exit "${status}"
  fi

  set +e

  if ! cmp -s "${original_kustomization}" "${target_kustomization}"; then
    cp "${original_kustomization}" "${target_kustomization}" || cleanup_failed=1

    if [[ "${dry_run}" -eq 0 && "${restore_cluster}" -eq 1 ]]; then
      echo
      echo "=== Restoring original cluster configuration ==="
      "${repo_dir}/bin/down" || cleanup_failed=1
      "${repo_dir}/bin/up" || cleanup_failed=1
    fi
  fi

  rm -f "${original_kustomization}" || cleanup_failed=1

  if [[ "${cleanup_failed}" -ne 0 && "${status}" -eq 0 ]]; then
    status=1
  fi

  exit "${status}"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --continue-on-failure)
      continue_on_failure=1
      ;;
    --dry-run)
      dry_run=1
      ;;
    --list)
      list_only=1
      ;;
    --no-restore-cluster)
      restore_cluster=0
      ;;
    --help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
  shift
done

collect_variants

if [[ "${#variants[@]}" -eq 0 ]]; then
  echo "No integration variants found in ${variant_dir}" >&2
  exit 1
fi

if [[ "${list_only}" -eq 1 ]]; then
  printf '%s\n' "${variants[@]}"
  exit 0
fi

original_kustomization=$(mktemp "${TMPDIR:-/tmp}/final-validation.XXXXXX")
cp "${target_kustomization}" "${original_kustomization}"
trap cleanup EXIT INT TERM

echo "Discovered variants:"
printf ' - %s\n' "${variants[@]}"

failures=()

for variant in "${variants[@]}"; do
  if ! run_step "variant ${variant}" run_variant "${variant}"; then
    failures+=("${variant}")
    if [[ "${continue_on_failure}" -ne 1 ]]; then
      exit 1
    fi
  fi
done

if [[ "${#failures[@]}" -ne 0 ]]; then
  echo
  echo "Failing variants:"
  printf ' - %s\n' "${failures[@]}"
  exit 1
fi

echo
echo "All integration variants completed successfully."
