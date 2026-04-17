---
phase: 18-release-parity-gate-node-20-ci-cleanup
plan: 05
subsystem: infra
tags: [ci, github-actions, workspace-clean, release-parity, publish-gate, yaml]

# Dependency graph
requires:
  - phase: 18-02
    provides: mix verify.workspace_clean task (INFRA-01 implementation consumed by this plan's YAML wiring)
  - phase: 18-04
    provides: ci.yml pin-swap state (checkout@v6 x4, cache@v5 x4) preserved under this plan's additive edit
provides:
  - ci.yml quality job gates every push on mix verify.workspace_clean (D-15)
  - release-please.yml publish-hex job gates canonical publish on mix verify.workspace_clean (D-16)
  - publish-hex.yml manual-recovery workflow gates on mix verify.workspace_clean at parity with canonical (D-17)
  - INFRA-01 D-14 cross-workflow symmetry invariant (3 tests GREEN)
affects:
  - 18-06 (release_parity wiring into verify-published-release.yml — parallel INFRA-02 axis)
  - 18-07 (phase validation consolidation)
  - v1.3 feature phases 19-22 (every feature PR now inherits workspace_clean gate on push)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "workspace_clean step wired additively into existing publish paths (no new workflow files)"
    - "Per-path step insertion positions per D-15/D-16/D-17 (after format or install-deps; before heavy verification step)"

key-files:
  created: []
  modified:
    - .github/workflows/ci.yml
    - .github/workflows/release-please.yml
    - .github/workflows/publish-hex.yml

key-decisions:
  - "D-14 cross-workflow symmetry enforced: the gate runs on all three publish paths; partial coverage would reproduce the v1.2 failure shape."
  - "Only three workflow files modified; verify-published-release.yml deliberately excluded because workspace_clean is meaningless post-publish (Plan 06 adds release_parity there instead)."
  - "No --allow-dirty or SCRYPATH_WORKSPACE_CLEAN_SKIP escape hatches (D-04 enforcement)."

patterns-established:
  - "Additive-only YAML step insertion pattern — each workflow edit is a contiguous 3-line step block, reviewable as pure diff."
  - "Consistent step naming ('Verify workspace is clean') across all three files for reviewer pattern-match."

requirements-completed: [INFRA-01]

# Metrics
duration: 1min
completed: 2026-04-17
---

# Phase 18 Plan 05: Wire verify.workspace_clean into all three publish paths Summary

**Additive YAML step insertions wire `mix verify.workspace_clean` into ci.yml quality (per-push), release-please.yml publish-hex (canonical publish), and publish-hex.yml (manual recovery) — completing D-14 cross-workflow symmetry and turning INFRA-01's 3 workflow-wiring tests GREEN.**

## Performance

- **Duration:** 1 min (execution), ~5 min wall-clock incl. `mix deps.get` compile
- **Started:** 2026-04-17T14:05:48Z
- **Completed:** 2026-04-17T14:11:XXZ
- **Tasks:** 4 (3 edits + 1 verification)
- **Files modified:** 3

## Accomplishments

- `mix verify.workspace_clean` now gates every push to `main` and every PR via ci.yml quality job (D-15).
- Canonical publish path (release-please.yml publish-hex) gates on workspace_clean before `verify.phase11` (D-16).
- Manual recovery workflow (publish-hex.yml) gates on workspace_clean at identical step position — no cross-path asymmetry (D-17).
- D-14 invariant verified mechanically: INFRA-01 describe block runs 3 tests, 0 failures.
- Pin-swap state from Plan 04 preserved (`actions/checkout@v6` x4, `actions/cache@v5` x4 in ci.yml); no regression.
- No new workflow files created (D-20); no escape-hatch tokens introduced (D-04); `verify-published-release.yml` untouched.

## Task Commits

Each task was committed atomically:

1. **Task 1: Insert verify.workspace_clean step in ci.yml quality job (D-15)** — `049fa57` (feat)
2. **Task 2: Insert verify.workspace_clean step in release-please.yml publish-hex job (D-16)** — `301e851` (feat)
3. **Task 3: Insert verify.workspace_clean step in publish-hex.yml manual-recovery workflow (D-17)** — `7b1332e` (feat)
4. **Task 4: Validate INFRA-01 cross-workflow symmetry (D-14)** — verification-only, no commit (no file changes per plan spec)

**Plan metadata:** committed together with this SUMMARY (see tail commit for hash).

## Files Created/Modified

- `.github/workflows/ci.yml` — Added `Verify workspace is clean` step in `quality` job between `Check formatting` and `Run Credo` (D-15). 3-line additive diff; pin-swap state intact.
- `.github/workflows/release-please.yml` — Added `Verify workspace is clean` step in `publish-hex` job between `Install dependencies` and `Verify release version` (D-16). Upstream `release-please` job untouched.
- `.github/workflows/publish-hex.yml` — Added `Verify workspace is clean` step between `Install dependencies` and `Run release contract gate` (D-17). Same position as canonical path — cross-path parity.

## Verification Output

**INFRA-01 describe block, scoped test run:**

```
$ mix test test/mix/tasks/workflow_wiring_test.exs --only describe:"INFRA-01 D-14: workspace_clean gate on all three publish paths"
...
Finished in 0.02 seconds (0.02s async, 0.00s sync)
3 tests, 0 failures (12 excluded)
```

**Manual grep counts (acceptance criteria):**

| File | Expected | Actual |
|------|----------|--------|
| `.github/workflows/ci.yml` | 1 | 1 |
| `.github/workflows/publish-hex.yml` | 1 | 1 |
| `.github/workflows/release-please.yml` | 1 | 1 |
| `.github/workflows/verify-published-release.yml` | 0 (Plan 06 adds `release_parity` here instead) | 0 |

**Ordering invariants (awk-verified):**

- ci.yml: `mix format --check-formatted` (L75) → `mix verify.workspace_clean` (L78) → `mix credo` (L81). Strict increase. PASS.
- release-please.yml: `mix deps.get` (L65) → `mix verify.workspace_clean` (L68) → `Verify release version` (L70). Strict increase. PASS.
- publish-hex.yml: `mix deps.get` (L42) → `mix verify.workspace_clean` (L45) → `Run release contract gate` (L47). Strict increase. PASS.

**Pin-swap invariants (Plan 04 preservation):**

- `grep -c "actions/checkout@v6" .github/workflows/ci.yml` = 4 (expected 4). PASS.
- `grep -c "actions/cache@v5" .github/workflows/ci.yml` = 4 (expected 4). PASS.
- No `actions/checkout@v4` or `actions/cache@v4` references. PASS.

**D-20 invariant (no new workflow files):**

- `.github/workflows/` contains exactly 4 files (ci.yml, publish-hex.yml, release-please.yml, verify-published-release.yml) — unchanged. PASS.

**D-04 invariant (no escape hatch):**

- `grep -E "(--allow-dirty|SCRYPATH_WORKSPACE_CLEAN_SKIP)" .github/workflows/publish-hex.yml` returns empty. PASS.

## Decisions Made

None beyond what the plan specified. Step insertion positions, step names, and edit anchors all followed D-14 through D-17 and the plan's action blocks exactly.

## Deviations from Plan

None — plan executed exactly as written. No bugs, missing functionality, or blocking issues encountered. YAML anchors matched cleanly on the first attempt; pre-existing tests (minus INFRA-01) remain in their prior state (INFRA-02, INFRA-03 cache checks, INFRA-04 continue to track their respective plans).

## Issues Encountered

- Initial `mix test` attempt failed with `Unchecked dependencies for environment test` (deps not yet fetched in the worktree). Resolved by running `mix deps.get` once — dependency fetch + compile is a worktree-setup cost, not an issue with the plan. Subsequent test runs clean.
- `mix test --only "<describe-string>"` with a free-form string did not match; used `--only describe:"..."` filter syntax to scope to the INFRA-01 describe block. Same 3 tests, same PASS result — just a command invocation refinement, not a change to the test file.

## User Setup Required

None — all changes are to CI configuration. No environment variables, dashboard steps, or secrets added.

## Next Phase Readiness

- D-14 invariant mechanized: every feature PR from this point forward is gated on `workspace_clean` via ci.yml quality job. Plans 18-06 and 18-07 can proceed without revisiting the workspace_clean axis.
- Plan 06 (release_parity on verify-published-release.yml) is unblocked: it operates on the only workflow file INFRA-01 intentionally did NOT touch.
- Release-contract integrity (INFRA-01) now backs every v1.3 feature PR — phases 19-22 inherit divergence prevention without additional CI wiring.

## Self-Check: PASSED

**File existence verified:**
- `.github/workflows/ci.yml` — FOUND
- `.github/workflows/release-please.yml` — FOUND
- `.github/workflows/publish-hex.yml` — FOUND
- `.planning/phases/18-release-parity-gate-node-20-ci-cleanup/18-05-SUMMARY.md` — FOUND

**Commit existence verified:**
- `049fa57` (Task 1: ci.yml D-15) — FOUND
- `301e851` (Task 2: release-please.yml D-16) — FOUND
- `7b1332e` (Task 3: publish-hex.yml D-17) — FOUND

---
*Phase: 18-release-parity-gate-node-20-ci-cleanup*
*Completed: 2026-04-17*
