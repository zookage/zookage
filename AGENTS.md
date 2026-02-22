# AGENTS.md

## Purpose
This document defines how AI coding agents should be used safely and consistently in this repository, covering both contributor workflows and end-user agent usage.

## Working Principles
- Keep changes minimal and scoped to the request.
- Prefer repository scripts and established conventions over custom workflows.
- Do not run destructive git/history actions unless explicitly requested.
- Preserve existing style and license-header expectations.

## Guidance for Repository Users
- State clear intent in prompts (for example: setup, config changes, debugging, or component enablement).
- Ask agents to show exact commands before execution when commands may affect your local environment.
- Prefer reproducible workflows and repo scripts over one-off shell commands.
- Ask for a short handoff summary that includes changed files, commands run, and any follow-up steps.

## Repository Facts
- Primary quality gate: `./test/lint.sh`.
- Lint coverage includes Dockerfiles, shell scripts, YAML files, and license headers.

## Validation Requirements
- For non-trivial changes, run `./test/lint.sh` before handoff.
- If validation cannot run due to environment or tooling constraints, report the exact blocker and which checks were not executed.
- For trivial docs-only changes, lint may be skipped if explicitly noted in handoff (running it is still preferred).

## Change Hygiene
- Keep edits focused and avoid unrelated refactors.
- State assumptions and limitations in the handoff summary.
- If scripts or configuration are added/changed, include update notes and verification steps.

## Handoff Checklist
- What changed.
- What was validated (or blocked), including `./test/lint.sh` status.
- Any risks or follow-up work.
