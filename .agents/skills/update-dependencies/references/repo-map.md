# Repo Dependency Map

## Main touchpoints

| Surface | Source of truth | Coupled files | Notes |
| --- | --- | --- | --- |
| Base build images and digests | `docker/sample-build.env` | `docker/build-*.sh`, `docker/*/Dockerfile` | Contains the Ubuntu, Temurin, Maven, and Keycloak image pins used by the local build scripts. |
| Runtime Zookage image tags | `kubernetes/kustomization.yaml` | `test/kubernetes/all.yaml`, `test/kubernetes/ha.yaml`, `test/kubernetes/llap.yaml` | `test/integration.sh` can copy a test fixture over the main kustomization before bringing the cluster up. |
| Lint and check containers | `test/hadolint.sh`, `test/license.sh` | None | Versions live directly in the scripts rather than in a shared config file. |
| Manifest-local images | `kubernetes/base/**` | None unless the same image is reused elsewhere | Example: `kubernetes/base/tez/ui/deployment.yaml` pins `tomcat:11.0.18-jdk21-temurin` directly. |
| Dockerfile-local version args | `docker/*/Dockerfile` | Matching `docker/build-*.sh` inputs when applicable | Example: `docker/util/Dockerfile` defines `kubectl_version=v1.35.1`. |

## Useful commands

- `./.agents/skills/update-dependencies/scripts/find_dependency_refs.sh`
- `./.agents/skills/update-dependencies/scripts/find_dependency_refs.sh <pattern>`
- `rg -n "newTag:" kubernetes/kustomization.yaml test/kubernetes`
- `rg -n "ARG .*version|^FROM " docker/*/Dockerfile`
- `rg -n "^[A-Z0-9_]+_IMAGE=" docker/sample-build.env`

## Version selection policy

- Treat `latest` as "latest release on the current track", not "switch to a different distro or runtime family".
- Preserve qualifiers such as `noble`, `24.04`, `jdk21`, `temurin`, and `ubuntu-24.04` unless the user asks to change them.
- For digest pins in `docker/sample-build.env`, use the comment above each variable to identify the tag family that should stay stable while the digest moves forward.
- For mixed tags like `tomcat:11.0.18-jdk21-temurin`, update the application version while keeping the runtime suffix stable.

## Current direct pins worth checking first

- `hadolint/hadolint:v2.14.0` in `test/hadolint.sh`
- `apache/skywalking-eyes:0.8.0` in `test/license.sh`
- `tomcat:11.0.18-jdk21-temurin` in `kubernetes/base/tez/ui/deployment.yaml`
- `kubectl_version=v1.35.2` in `docker/util/Dockerfile`
