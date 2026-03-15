---
name: final-validation
description: Run the repository's full integration validation sweep by executing `./test/integration.sh <variant>` for each `test/kubernetes/*.yaml` variant. Use when a user asks for final validation before merge or release, wants all parameterized integration variants exercised, or needs failures from that sweep diagnosed and fixed with minimal repo-scoped changes.
---

# Final Validation

## Overview

Run the repo's expensive parameterized integration flow in a repeatable order, then use the failing variant to drive focused fixes. Keep changes minimal, rerun the narrowest failing case first, and finish with a clean confirmation pass.

## Inputs

- `repo`: repository root, usually `.`
- A running Docker and Kubernetes environment that can execute `./bin/up`, `./bin/down`, and `./test/integration.sh`
- Optional user guidance about whether to stop on the first failure or keep sweeping to collect multiple failures

## Quick Start

- List the sweep order:
  - `./.agents/skills/final-validation/scripts/run_all_variants.sh --list`
- Run the full sweep and stop on the first failure:
  - `./.agents/skills/final-validation/scripts/run_all_variants.sh`
- Run the full sweep and collect every failing variant:
  - `./.agents/skills/final-validation/scripts/run_all_variants.sh --continue-on-failure`
- Preview the commands without touching the cluster:
  - `./.agents/skills/final-validation/scripts/run_all_variants.sh --dry-run`

## Workflow

1. Inspect the repo state before starting.
   - Run `git status --short` so you can distinguish pre-existing changes from fixes you make during validation.
2. Discover the validation matrix.
   - Prefer `./.agents/skills/final-validation/scripts/run_all_variants.sh --list`.
   - Treat every file in `test/kubernetes/*.yaml` as a variant passed to `./test/integration.sh <stem>`.
3. Run the sweep.
   - Use the bundled script so each variant is exercised through `./test/integration.sh <variant>` and the checked-in `kubernetes/kustomization.yaml` is restored at exit.
   - Stop on the first failure unless the user explicitly wants a full failure inventory.
4. Diagnose the failing stage.
   - Read the failing section name from `./test/integration.sh` output.
   - Open the corresponding script in `test/integration/` when the failure already points to a specific subsystem.
   - Inspect cluster and container state with repo helpers such as `./bin/logs`, `kubectl`, and targeted integration scripts when you need more detail.
5. Fix the smallest thing that explains the failure.
   - Prefer repo-local changes over test-only workarounds unless the test is clearly wrong.
   - Avoid broad refactors during final validation.
6. Reproduce narrowly, then broaden.
   - Re-run the single failing variant first with `./test/integration.sh <variant>`.
   - Re-run `./test/lint.sh` once code changes settle.
   - Finish with another full sweep via `./.agents/skills/final-validation/scripts/run_all_variants.sh`.
7. Summarize the outcome.
   - Report which variant failed, what changed, what commands were rerun, and whether the final full sweep passed.

## Failure Handling

- Treat long-running full sweeps as the expensive confirmation step, not the first debugging loop.
- Use `--continue-on-failure` only when the user wants a failure inventory; otherwise preserve time by fixing the first real blocker.
- Restore confidence after a fix by rerunning the affected variant before spending time on the full matrix again.
- Call out when you could not complete the sweep because cluster startup, Docker, or infrastructure dependencies were unavailable.

## Bundled Resources

### scripts/run_all_variants.sh

Enumerate every `test/kubernetes/*.yaml` stem, execute `./test/integration.sh <variant>` for each one, and restore the original `kubernetes/kustomization.yaml` when finished.
