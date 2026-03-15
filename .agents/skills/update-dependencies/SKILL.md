---
name: update-dependencies
description: Update pinned dependency versions in this repository. Use when Codex needs to bump Docker base-image digests, lint/test container images, Kubernetes image tags, or version arguments in `docker/sample-build.env`, `docker/*/Dockerfile`, `docker/build-*.sh`, `kubernetes/kustomization.yaml`, `test/kubernetes/*.yaml`, or `test/*.sh`. Prefer the latest upstream version that stays on the current OS or image variant unless the user asks to change tracks.
---

# Update Dependencies

Use this skill to make small, consistent dependency bumps in this repository. Trace the dependency to its source of truth first, then update every mirrored consumer that must stay aligned, and validate with the repository lint gate.

## Workflow

1. Identify the dependency surface.
   - Run `./.agents/skills/update-dependencies/scripts/find_dependency_refs.sh <pattern>` from the repository root when the requested package, image, or version string is known.
   - Read [references/repo-map.md](references/repo-map.md) when the request is broad, such as "update lint images" or "refresh the JDK digests".
   - Prefer the narrowest source of truth instead of editing every match blindly.

2. Update the source of truth.
   - Edit `docker/sample-build.env` for pinned base-image digests and upstream builder images.
   - Edit `kubernetes/kustomization.yaml` for runtime image tags resolved through Kustomize.
   - Edit `test/hadolint.sh`, `test/license.sh`, or similar test scripts for tooling containers used only in checks.
   - Edit a manifest directly for images not routed through Kustomize, such as `kubernetes/base/tez/ui/deployment.yaml`.
   - Edit a Dockerfile only when the version is declared there, such as `ARG kubectl_version` in `docker/util/Dockerfile`.

3. Choose the target version conservatively.
   - Prefer the newest available upstream release that stays on the current track or variant.
   - Keep distro and runtime qualifiers unless the user asks to change them. Examples: keep `noble`, `24.04`, `jdk21-temurin`, `ubuntu-24.04`, or similar suffixes and prefixes.
   - For digest-pinned images in `docker/sample-build.env`, keep the human-readable tag family shown in the preceding comment and refresh only the digest.
   - For tags that combine multiple dimensions, move only the version component that is clearly intended to float. Example: `tomcat:11.0.18-jdk21-temurin` should usually become a newer Tomcat release that still uses `jdk21-temurin`.
   - Call out any case where "latest" is ambiguous or would require changing OS family, major runtime, or image flavor.

4. Propagate coupled changes.
   - Keep `test/kubernetes/all.yaml`, `test/kubernetes/ha.yaml`, and `test/kubernetes/llap.yaml` aligned with `kubernetes/kustomization.yaml`; `test/integration.sh` can copy those fixtures over the main kustomization during test runs.
   - When changing a value in `docker/sample-build.env`, verify which `docker/build-*.sh` passes it into which Dockerfile before deciding the bump is complete.
   - Preserve quoting and the existing tag-or-digest style unless the user explicitly asks to change it.

5. Validate the bump.
   - Run `./test/lint.sh`.
   - If the change clearly needs deeper validation, call that out and recommend the next build or integration test.
   - Summarize which files changed, which mirrors were kept in sync, and any related refs you intentionally left untouched.

## Repo Map

- Base build images: `docker/sample-build.env`
- Build-arg wiring: `docker/build-*.sh`
- Direct Dockerfile version args: `docker/*/Dockerfile`
- Runtime image tags: `kubernetes/kustomization.yaml`
- Test kustomization fixtures: `test/kubernetes/*.yaml`
- Tooling containers used in tests: `test/*.sh`
- Direct manifest pins outside Kustomize: `kubernetes/base/**`

## Search Shortcuts

- Run `./.agents/skills/update-dependencies/scripts/find_dependency_refs.sh` to print the common pin locations.
- Run `./.agents/skills/update-dependencies/scripts/find_dependency_refs.sh hadolint` to find a named dependency quickly.
- Use `rg -n "newTag:" kubernetes/kustomization.yaml test/kubernetes` when aligning runtime tags.
- Use `rg -n "^[A-Z0-9_]+_IMAGE=" docker/sample-build.env` when auditing base-image digests.

## Guardrails

- Keep changes minimal and scoped to the requested dependency.
- Treat mirrored test fixtures as part of the same change unless the user explicitly wants divergence.
- Do not edit unrelated component tags just because they appear nearby.
- Keep the current OS, distro, and runtime track unless the user explicitly asks to move it.
- Call out when a requested bump likely needs follow-up build or integration testing beyond lint.
