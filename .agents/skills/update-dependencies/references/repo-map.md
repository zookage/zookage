# Repo Dependency Map

## Main touchpoints

| Surface | Source of truth | Coupled files | Notes |
| --- | --- | --- | --- |
| Base build images and digests | `docker/sample-build.env` | `docker/build-*.sh`, `docker/*/Dockerfile` | Contains the Ubuntu, Temurin, Maven, and Keycloak image pins used by the local build scripts. |
| Runtime Zookage image tags | `kubernetes/kustomization.yaml` | `test/kubernetes/all.yaml`, `test/kubernetes/ha.yaml`, `test/kubernetes/llap.yaml` | `test/integration.sh` can copy a test fixture over the main kustomization before bringing the cluster up. |
| Lint and check containers | `test/hadolint.sh`, `test/license.sh` | None | Versions live directly in the scripts rather than in a shared config file. |
| GitHub Actions workflow pins | `.github/workflows/ci.yaml` | None for action-only bumps; `console/pom.xml`, `docker/sample-build.env`, and `docker/build-console.sh` for console Java toolchain moves | Covers `uses:` pins and workflow-local Java/toolchain values such as `actions/setup-java` `java-version`. |
| Console Maven versions | `console/pom.xml` | `.github/workflows/ci.yaml` for Java level bumps; `docker/console/Dockerfile` consumes the same POM during image builds | Prefer property-backed versions such as `quarkus.platform.version`, plugin versions, and `maven.compiler.release` over repeated consumer edits. Do not treat the project artifact version as a dependency pin by default. |
| Manifest-local images | `kubernetes/base/**` | None unless the same image is reused elsewhere | Example: `kubernetes/base/tez/ui/deployment.yaml` pins `tomcat:11.0.18-jdk21-temurin` directly. |
| Dockerfile-local version args | `docker/*/Dockerfile` | Matching `docker/build-*.sh` inputs when applicable | Example: `docker/util/Dockerfile` defines `kubectl_version=v1.35.1`. |

## Useful commands

- `./.agents/skills/update-dependencies/scripts/find_dependency_refs.sh`
- `./.agents/skills/update-dependencies/scripts/find_dependency_refs.sh <pattern>`
- `rg -n "newTag:" kubernetes/kustomization.yaml test/kubernetes`
- `rg -n "ARG .*version|^FROM " docker/*/Dockerfile`
- `rg -n "^[A-Z0-9_]+_IMAGE=" docker/sample-build.env`
- `rg -n "uses:|java-version:" .github/workflows/ci.yaml`
- `rg -n "<[^/][^>]*version>|<maven.compiler.release>" console/pom.xml`

## Version selection policy

- Treat `latest` as "latest patch on the upstream LTS line" when the dependency publishes an LTS stream. If there is no designated LTS line, fall back to the latest release on the current track rather than switching distro or runtime family.
- Preserve qualifiers such as `noble`, `24.04`, `jdk21`, `temurin`, and `ubuntu-24.04` unless the user asks to change them.
- For digest pins in `docker/sample-build.env`, use the comment above each variable to identify the tag family that should stay stable while the digest moves forward.
- For mixed tags like `tomcat:11.0.18-jdk21-temurin`, update the application version while keeping the runtime suffix stable.
- For GitHub Actions refs like `actions/setup-java@v4`, preserve the owner and action name and only bump the version suffix unless the user asks to change tracks.
- For `console/pom.xml`, prefer updating a `<properties>` entry once instead of editing every plugin or dependency consumer, and ignore the module artifact version unless the request is explicitly about project versioning.
- When an upstream project has both LTS and non-LTS lines, prefer the newest released patch on the LTS line even if a newer non-LTS line exists. Example: use Quarkus `3.33.x` LTS instead of `3.34.x`.

## Current direct pins worth checking first

- `hadolint/hadolint:v2.14.0` in `test/hadolint.sh`
- `apache/skywalking-eyes:0.8.0` in `test/license.sh`
- `tomcat:11.0.18-jdk21-temurin` in `kubernetes/base/tez/ui/deployment.yaml`
- `kubectl_version=v1.35.2` in `docker/util/Dockerfile`
- `actions/setup-java@v4` and `java-version: '25'` in `.github/workflows/ci.yaml`
- `quarkus.platform.version`, `maven.compiler.release`, and plugin version properties in `console/pom.xml`
