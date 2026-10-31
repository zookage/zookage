---
name: final-validation
description: Run the repository's integration validation across every test/kubernetes/*.yaml variant, resuming from a repaired variant and completing one circular pass without duplicate runs. Use for final validation before merge or release, full integration coverage, or diagnosing and fixing failures from that validation with minimal repo-scoped changes.
---

# Final Validation

## Overview

Run the repo's expensive parameterized integration flow in a circular order, using failures to drive focused fixes. After a fix, start with the failing variant and continue around the matrix once; do not restart from the first alphabetical variant or repeat the starting variant at the end.

## Inputs

- `repo`: repository root, usually `.`
- A running Docker and Kubernetes environment that can execute `./bin/up`, `./bin/down`, and `./test/integration.sh`
- Optional user guidance about whether to stop on the first failure or keep sweeping to collect multiple failures

## Quick Start

- List the sweep order:
  - `./.agents/skills/final-validation/scripts/run_all_variants.sh --list`
- Run the full sweep and stop on the first failure:
  - `./.agents/skills/final-validation/scripts/run_all_variants.sh`
- Start a confirmation cycle at the repaired variant:
  - `./.agents/skills/final-validation/scripts/run_all_variants.sh --start-at auth`
  - With the current matrix, this runs `auth → ha → llap-auth → llap → all`, then stops.
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
   - Track the current cycle's starting variant and successful variants, including results from earlier commands in the same validation task. Honor the user's requested order.
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
6. Resume from the failure and complete one cycle.
   - A focused subsystem check may help diagnose the fix, but it does not count as a full variant pass.
   - Use `./.agents/skills/final-validation/scripts/run_all_variants.sh --start-at <failing-variant>` to confirm the repaired variant first, then continue through the remaining variants in circular order.
   - Do not run the repaired variant separately and then repeat it in the wrapper. If it has already passed after the fix, count that result and execute only the remaining variants with `./test/integration.sh <variant>`; preserve and restore the original kustomization and cluster as the wrapper does.
   - If another variant fails, fix it and make that variant the start of the new confirmation cycle. Results from before the latest functional fix do not complete that new cycle.
   - Stop when every variant has passed once in the current cycle. For example: `all` passes, `auth` fails, fix, then `auth → ha → llap-auth → llap → all` passes: validation is complete, without another `auth` run or full sweep.
   - Re-run `./test/lint.sh` once code changes settle.
7. Summarize the outcome.
   - Report which variant failed, what changed, and the successful confirmation cycle, including passes collected across separate commands.

## Failure Handling

- Treat one successful cycle after the latest fix as confirmation; do not append another full sweep.
- Use `--continue-on-failure` only when the user wants a failure inventory; otherwise preserve time by fixing the first real blocker.
- Resume at the repaired variant so another failure there is caught before spending time on other variants.
- Call out when you could not complete the sweep because cluster startup, Docker, or infrastructure dependencies were unavailable.

## Bundled Resources

### scripts/run_all_variants.sh

Enumerate every `test/kubernetes/*.yaml` stem, optionally rotate the order with `--start-at <variant>`, execute `./test/integration.sh <variant>` once per variant, and restore the original `kubernetes/kustomization.yaml` when finished.
