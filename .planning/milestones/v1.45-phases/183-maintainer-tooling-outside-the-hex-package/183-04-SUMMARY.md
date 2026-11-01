---
phase: 183-maintainer-tooling-outside-the-hex-package
plan: "04"
subsystem: maintainer-tooling
tags: [mix-tasks, git-mv, package-boundary, preferred-envs, pkgh-01, pkgh-02]
requires: ["183-01", "183-02", "183-03"]
provides:
  - "52 maintainer verifiers moved to dev/mix/tasks as one pure-rename commit (53 files total with the 183-01 fence)"
  - "lib/mix/tasks holds only the 8 public scrypath.* task files"
  - "Tooling-boundary guard (D-17) and preferred_envs guard (D-04)"
affects: [183-05, 183-07]
tech-stack:
  added: []
  patterns:
    - "Maintainer tasks compile only under :test via env-keyed elixirc_paths"
    - "Behaviour-attribute classification of Mix tasks (not Mix.Task.task?/1)"
key-files:
  created:
    - test/release/package_contents_test.exs
  modified:
    - test/support/repo_tooling.ex
    - test/mix/tasks/verify_capability_test.exs
key-decisions:
  - "D-16: the move commit is 52 R100 renames plus the one-line @tasks_root flip, nothing else"
  - "D-17: boundary guard counts files only, so an empty leftover lib/mix/tasks/verify directory is not a false failure"
  - "D-04: guard classifies by Mix.Task behaviour attribute because Mix.Task.task?/1 counts the PhoenixExample.Package helper"
requirements-completed: [PKGH-01, PKGH-02]
status: complete
commits: 2
plan_head_before: ad31646ff0020c407b87b61b47cd7079774818e6
plan_head_after: 36e2cb125ef365a169985a06fd00845accc62223
actuals:
  tokens: 2500
  tasks: 2
  commits: 2
completed: 2026-10-28
---

# Phase 183 Plan 04: Move maintainer verifiers to dev/mix/tasks Summary

All 52 remaining verify* sources now live under `dev/mix/tasks`, the dev build carries only the 8 public Mix.Tasks beams, and two guard tests pin the boundary and the :test env routing.

## Commits

| Task | Commit | Message |
|------|--------|---------|
| 1 | a7546f8e | refactor(183-04): move maintainer verifiers to dev/mix/tasks |
| 2 | 36e2cb12 | test(183-04): guard the tooling boundary and verify preferred_envs routing |

## Moved paths (old -> new, for the orchestrator's deletion declaration)

Every path moved from `lib/mix/tasks/<rel>` to `dev/mix/tasks/<rel>`, preserving the relative layout:

- Top level (40): verify.ex, verify.adopter.ex, verify.all.ex, verify.coverage.ex, verify.meilisearch_smoke.ex, verify.no_optional_deps.ex, verify.ops_ui.ex, verify.postgres.ex, verify.release_parity.ex, verify.release_publish.ex, verify.workspace_clean.ex, verify.phase5.ex, verify.phase8.ex, verify.phase10.ex, verify.phase11.ex, verify.phase13.ex, verify.phase14.ex, verify.phase20.ex, verify.phase22.ex, verify.phase26.ex, verify.phase28.ex, verify.phase36.ex, verify.phase37.ex, verify.phase38.ex, verify.phase41.ex, verify.phase43.ex, verify.phase82.ex, verify.phase83.ex, verify.phase84.ex, verify.phase85.ex, verify.phase91.ex, verify.phase94.ex, verify.phase96.ex, verify.phase97.ex, verify.phase98.ex, verify.phase99.ex, verify.phase106.ex, verify.phase107.ex, verify.phase108.ex, verify.phase112.ex
- `verify/` (10): backend.ex, capability.ex, compatibility.ex, core.ex, deep_quality.ex, ecommerce_e2e.ex, ecommerce_mounted.ex, package.ex, phoenix_example.ex, repository_contracts.ex
- `verify/phoenix_example/` (2): lock_graph.ex, package.ex

Deleted source paths under lib/mix/tasks: all 52 above (e.g. `lib/mix/tasks/verify.phase11.ex`, `lib/mix/tasks/verify/phoenix_example/package.ex`). `git ls-files lib/mix/tasks` now prints exactly the 8 public files: scrypath.failed.ex, scrypath.reconcile.ex, scrypath.retry.ex, scrypath.settings.diff.ex, scrypath.settings.hot_apply.ex, scrypath.settings.read.ex, scrypath.status.ex, scrypath/index/contract_drift.ex. `git ls-files dev/mix/tasks` prints 53.

## Evidence

`git diff -M --name-status a7546f8e^ a7546f8e`: 52 `R100` lines plus `M test/support/repo_tooling.ex`, nothing else.

Dev ebin after `MIX_ENV=dev mix compile --warnings-as-errors` (cold dev build, compile clean): exactly 8 beams, zero `Elixir.Mix.Tasks.Verify*`:
Failed, Index.ContractDrift, Reconcile, Retry, Settings.Diff, Settings.HotApply, Settings.Read, Status.

`grep -rn 'lib/mix/tasks/verify' test` prints nothing.

### Nyquist named-exception wall times

| Gate | Wall time |
|------|-----------|
| D-16 full fast suite (`MIX_ENV=test mix do compile --warnings-as-errors + test --warnings-as-errors --exclude integration`, 5 properties, 1035 tests, 0 failures) | about 25 s |
| `MIX_ENV=dev mix compile --warnings-as-errors` plus ebin count (cold dev build) | 17 s |
| Documented commands `mix verify.adopter && mix verify.namespace_fence && mix test test/mix/tasks/verify_adopter_test.exs` (25 / fence passed / 15 tests, 0 failures) | 3 s |

All three finished inside the 30 s budget in this environment. The fast suite was run on the staged move before it was committed, so the commit itself was green.

### D-04 RED / GREEN

RED (temporarily deleted `"verify.namespace_fence": :test` from mix.exs):

```
1) test every maintainer Mix.Task has a :test preferred env and every verify key resolves (Mix.Tasks.Verify.CapabilityTest)
   verify.namespace_fence is a maintainer task without a :test entry in mix.exs preferred_envs
9 tests, 1 failure
```

GREEN after restoring mix.exs (`git diff --quiet -- mix.exs` clean): `MIX_ENV=test mix do compile --warnings-as-errors + test --warnings-as-errors test/release/package_contents_test.exs test/mix/tasks/verify_capability_test.exs` -> 10 tests, 0 failures.

### Phase verification

`MIX_ENV=test mix verify.repository_contracts` -> 98 tests, 0 failures. `mix verify.package` -> exit 0, tarball built.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Boundary guard false failure on empty leftover directories**
- **Found during:** Task 2 first GREEN run
- **Issue:** `git mv` leaves empty `lib/mix/tasks/verify/` and `verify/phoenix_example/` directories on disk (untracked, absent from a fresh clone). The plan's literal `Path.wildcard("lib/mix/tasks/verify*") == []` matched the empty directory and failed.
- **Fix:** Removed the two empty directories with `rmdir`, and made the guard reject directories so it counts files only (`verify*` plus `verify*/**`, filtered by `File.dir?/1`). The assertion still fails if any verify file returns to lib/mix/tasks.
- **Files modified:** test/release/package_contents_test.exs
- **Commit:** 36e2cb12

No other deviations. The execution_context toolchain note (Elixir 1.19.0 / OTP 28.5) was used instead of the plan's 1.19.5/28.1 values, per orchestrator instruction.

## Known Stubs

None.

## Threat Flags

None. No new network, auth or file surface. T-183-05 (maintainer automation in adopter builds) is mitigated and evidenced by the 8-beam dev ebin and the boundary guard; T-183-06 by the D-04 guard with the RED proof above; T-183-SC: no dependency changes, mix.lock untouched.

## Self-Check: PASSED

- dev/mix/tasks: 53 tracked files; lib/mix/tasks: 8 tracked files
- test/release/package_contents_test.exs: FOUND
- Commits a7546f8e and 36e2cb12: FOUND in HEAD ancestry
