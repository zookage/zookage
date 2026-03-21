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
- Run `./bin/ssh <pod name> [<container name>]` to log in to a container

## Guidance for Developers
- Primary quality gate: `./test/lint.sh`
- To auto-fix license headers: `./test/licensefix.sh`
- Integration test suite: `./test/integration.sh [all|auth|ha|llap]`
