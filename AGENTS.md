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
- Run `./bin/ssh <pod name> [<container name>]` to log in to a container

## Guidance for Developers
- Primary quality gate: `./test/lint.sh`
