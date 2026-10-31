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

script_dir=$(cd "$(dirname "$0")" && pwd)
readonly script_dir
readonly images_file="${script_dir}/images.env"

usage() {
  echo "Usage: $0 [--dry-run] [IMAGE_VARIABLE ...]" >&2
  echo "Refresh the digest for each selected image's current tag. Omit variables to refresh all images." >&2
}

fail() {
  echo "Error: $*" >&2
  exit 1
}

lookup_image() {
  local image_variable=$1
  local line
  while IFS= read -r line; do
    case "$line" in
      "${image_variable}="*)
        printf '%s\n' "${line#*=}"
        return 0
        ;;
    esac
  done < "$2"
  return 1
}

dry_run=0
if [ "${1:-}" = "--dry-run" ]; then
  dry_run=1
  shift
fi
if [ "${1:-}" = "--help" ]; then
  usage
  exit 0
fi

selected=()
if [ "$#" -eq 0 ]; then
  while IFS='=' read -r image_variable image_reference; do
    if [[ "$image_variable" =~ ^[A-Z][A-Z0-9_]*_IMAGE$ ]]; then
      selected+=("$image_variable")
    fi
  done < "$images_file"
else
  for image_variable in "$@"; do
    if [[ ! "$image_variable" =~ ^[A-Z][A-Z0-9_]*_IMAGE$ ]]; then
      usage
      fail "Invalid image variable: ${image_variable}"
    fi
    if [ "${#selected[@]}" -gt 0 ]; then
      for existing in "${selected[@]}"; do
        if [ "$image_variable" = "$existing" ]; then
          fail "Duplicate image variable: ${image_variable}"
        fi
      done
    fi
    selected+=("$image_variable")
  done
fi

if [ "${#selected[@]}" -eq 0 ]; then
  fail "No image variables found in ${images_file}"
fi

temp_dir=$(mktemp -d "${images_file}.tmp.XXXXXX") || fail "Could not create a temporary directory"
readonly temp_dir
trap 'rm -rf "${temp_dir}"' EXIT
cp "$images_file" "${temp_dir}/original"
: > "${temp_dir}/replacements"
: > "${temp_dir}/summary"

changed=0
for image_variable in "${selected[@]}"; do
  image_reference=$(lookup_image "$image_variable" "${temp_dir}/original") || fail "Unknown image variable: ${image_variable}"
  if [[ ! "$image_reference" =~ ^[^@[:space:]]+:[A-Za-z0-9_][A-Za-z0-9_.-]*@sha256:[a-f0-9]{64}$ ]]; then
    fail "Invalid image reference for ${image_variable}: ${image_reference}"
  fi

  image_tag=${image_reference%@sha256:*}
  current_digest=${image_reference##*@}
  digest_json=$(docker buildx imagetools inspect --format '{{json .Manifest.Digest}}' "$image_tag") || fail "Could not inspect ${image_tag}"
  if [[ ! "$digest_json" =~ ^\"sha256:[a-f0-9]{64}\"$ ]]; then
    fail "Invalid digest returned for ${image_tag}: ${digest_json}"
  fi
  latest_digest=${digest_json#\"}
  latest_digest=${latest_digest%\"}

  if [ "$latest_digest" != "$current_digest" ]; then
    printf '%s %s\n' "$image_variable" "${image_tag}@${latest_digest}" >> "${temp_dir}/replacements"
    printf '%s: %s -> %s\n' "$image_variable" "$current_digest" "$latest_digest" >> "${temp_dir}/summary"
    changed=$((changed + 1))
  fi
done

if [ "$changed" -eq 0 ]; then
  echo "All selected image digests are current."
  exit 0
fi
if [ "$dry_run" -eq 1 ]; then
  cat "${temp_dir}/summary"
  echo "Dry run: ${changed} image digest(s) would be updated."
  exit 0
fi
if ! cmp -s "$images_file" "${temp_dir}/original"; then
  fail "${images_file} changed during the lookup; retry"
fi

awk 'NR == FNR { replacements[$1] = $2; next }
     { split($0, parts, "="); if (parts[1] in replacements) print parts[1] "=" replacements[parts[1]]; else print }' \
  "${temp_dir}/replacements" "${temp_dir}/original" > "${temp_dir}/updated"
chmod 644 "${temp_dir}/updated"
mv "${temp_dir}/updated" "$images_file"
cat "${temp_dir}/summary"
echo "Updated ${changed} image digest(s) in ${images_file}."
