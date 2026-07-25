# AGENTS.md

## Purpose
This document defines how AI coding agents should be used safely and consistently in this repository, covering both contributor workflows and end-user agent usage.

## Working Principles
- Keep changes minimal and scoped to the request.
- Prefer repository scripts and established conventions over custom workflows.
- Do not run destructive git/history actions unless explicitly requested.
- Preserve existing style and license-header expectations.

## Guidance for Repository Users
- Run `./bin/up` to spin up a Hadoop cluster
- Run `./bin/down` to shut down the cluster
- Run `./bin/kubectl <args...>` to run `kubectl` in the `zookage` namespace
- Run `./bin/logs [<pod name>]` to tail logs from all pods or a specific pod
- Run `./bin/ssh [<pod name>] [<container name>]` to log in to a container (defaults to `client-node-0`)

## Guidance for Developers
- Primary quality gate: `./test/lint.sh`
- Focused lint checks (same tools as `./test/lint.sh`): `./test/hadolint.sh`, `./test/shellcheck.sh`, `./test/yamllint.sh`, `./test/license.sh`
- To run the console module formatting checks and tests: `mvn -f console/pom.xml test`
- To auto-fix license headers: `./test/licensefix.sh`
- To configure local Docker image builds, copy `docker/sample-build.env` to `docker/build.env` and adjust source directories/image settings.
- To build a Docker image, run the matching `docker/build-<component>.sh` script (for example, `docker/build-console.sh` or `docker/build-hadoop.sh`).
- Before dependency bumps, run `./.agents/skills/update-dependencies/scripts/find_dependency_refs.sh [pattern]` to find repo-local pins and mirrored consumers.
- Integration test suite on the current Kubernetes profile: `./test/integration.sh`
- To switch Kubernetes profile and run the integration suite: `./test/integration.sh [all|auth|ha|llap]` (copies `test/kubernetes/<name>.yaml` to `kubernetes/kustomization.yaml` and restarts the cluster)
- For full pre-merge validation across every checked-in Kubernetes profile, use `./.agents/skills/final-validation/scripts/run_all_variants.sh` (`--list`, `--dry-run`, and `--continue-on-failure` are available).
- To run an individual integration check directly: `./test/integration/<name>.sh` (for example, `./test/integration/web.sh`, `./test/integration/spark_sql.sh`, or `./test/integration/container_warn.sh`)
- To execute a one-off command in `client-node-0` during integration/debugging: `./test/integration/run.sh <args...>`
- S3-backed coverage is embedded in the MR, Spark, Spark SQL, Hive on Tez, Ozone, and Trino integration checks through `test/integration/s3.sh`; run the relevant subsystem check rather than treating it as a standalone suite.
- To inspect or regenerate checked-in JCEKS secrets, use `./test/jceks show <jceks-file>` or `./test/jceks create <jceks-file>`; `create` reads key-value pairs from `<jceks-file>.properties`.
- After changing Ranger Kerberos principals or passwords in `kubernetes/base/common/config/openldap/bootstrap.ldif`, run `./docker/generate-keytabs.sh` to regenerate `kubernetes/base/common/secret/ranger/ranger.keytab`.
