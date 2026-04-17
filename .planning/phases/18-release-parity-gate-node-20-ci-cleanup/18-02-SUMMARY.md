---
phase: 18-release-parity-gate-node-20-ci-cleanup
plan: 02
subsystem: infra
tags: [elixir, mix-task, git, release-parity, workspace-clean, infra-01]

# Dependency graph
requires:
  - phase: 18-01
    provides: "red-state test scaffolding — test/mix/tasks/verify_workspace_clean_test.exs (3 tests) defining the INFRA-01 contract"
provides:
  - "Mix.Tasks.Verify.WorkspaceClean module implementing INFRA-01"
  - "Public build_pathspecs/0 deriving pathspecs from Mix.Project.config()[:package][:files] ++ [\"test\"]"
  - "D-04 no-escape-hatch enforcement (grep-verified: no --allow-dirty / SCRYPATH_WORKSPACE_CLEAN_SKIP / OptionParser.parse)"
  - "Mix.raise dirty-tree message with git add / git stash -u / git checkout -- remediation hints plus v1.2 audit backref"
affects:
  - 18-04 (workflow wiring — release-please.yml, release-recovery-publish.yml, CI consume this task)
  - 18-03 (verify.release_parity may compose this task)
  - 23 (VALIDATION.md closure references release-parity gate)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Mix.Project.config() package.files as D-01 source of truth for pathspec derivation"
    - "System.cmd(\"git\", [...], stderr_to_stdout: true) with args-as-list (Pitfall 2, no shell invocation)"
    - "ensure_no_args!/1 guard copied verbatim from verify.phase11 for no-flag Mix tasks"
    - "Exposed-for-testability public helper (build_pathspecs/0) alongside @impl true run/1"

key-files:
  created:
    - "lib/mix/tasks/verify.workspace_clean.ex - Mix.Tasks.Verify.WorkspaceClean module (INFRA-01)"
  modified: []

key-decisions:
  - "D-01 enforced: build_pathspecs/0 reads Mix.Project.config()[:package][:files] (no hardcoded list) so future mix.exs package.files additions automatically extend the gate"
  - "D-04 enforced: no escape hatch flag, env var, or OptionParser — grep-verified at acceptance time"
  - "D-05 enforced: test/** appended to pathspecs even though not packaged (uncommitted tests mean 'the lib/ state being published was not tested as it will ship')"
  - "Mix.raise message shape matches v1.2-MILESTONE-AUDIT backref requirement (D-02 context link preserved)"

patterns-established:
  - "Pattern: INFRA verify task shape — `use Mix.Task` + @shortdoc + @impl true run/1 + ensure_no_args!/1 guard + System.cmd/3 with args list + Mix.raise/1 surface (mirrors verify.phase11)"
  - "Pattern: Public testability helper — helper functions that compute derived state from project config are exposed publicly with @spec and @doc so tests can assert on derivation without re-running the full Mix task"

requirements-completed: [INFRA-01]

# Metrics
duration: 2min
completed: 2026-04-17
---

# Phase 18 Plan 02: workspace-clean Mix task Summary

**`Mix.Tasks.Verify.WorkspaceClean` ships the INFRA-01 divergence-prevention gate — fails the publish pipeline with a structured remediation message when any packaged path has uncommitted or untracked files, with no escape-hatch flag (D-04).**

## Performance

- **Duration:** 2 min
- **Started:** 2026-04-17T13:56:32Z
- **Completed:** 2026-04-17T13:58:00Z (approx)
- **Tasks:** 1
- **Files modified:** 1 (created)

## Accomplishments
- Created `lib/mix/tasks/verify.workspace_clean.ex` implementing INFRA-01 end-to-end (97 lines).
- Turned all 3 red-state tests from Plan 01 Task 2 (`test/mix/tasks/verify_workspace_clean_test.exs`) green.
- Public `build_pathspecs/0` derives pathspecs from `Mix.Project.config()[:package][:files]` plus `"test"`, producing `["lib", ".formatter.exs", "mix.exs", "README.md", "ARCHITECTURE.md", "CHANGELOG.md", "guides", "docs", "test"]` — 9 pathspecs matching the mix.exs D-01 source of truth.
- Verified D-04 grep-enforcement: no `--allow-dirty`, no `SCRYPATH_WORKSPACE_CLEAN_SKIP`, no `allow_dirty`, no `OptionParser.parse`, no env-var skip in the source.
- Manual smoke tests pass for clean tree (exit 0), dirty tree (exit 1 + structured remediation message), and arg-guard (exit 1 + `does not accept arguments` message).

## Task Commits

Each task was committed atomically:

1. **Task 1: Implement lib/mix/tasks/verify.workspace_clean.ex (INFRA-01 Mix task)** — `0df164c` (feat)

_Note: The TDD RED phase commit lives in Plan 01 (`102322d` — `test(18-01): add red-state YAML-grep contract tests for INFRA-01/02/03/04 wiring` and the companion test file commit). Plan 18-02 is the GREEN phase of that TDD cycle, so only the single `feat` commit is landed here; no additional `test` commit was needed._

## Files Created/Modified
- `lib/mix/tasks/verify.workspace_clean.ex` — New `Mix.Tasks.Verify.WorkspaceClean` module with `run/1` (Mix task entry, raises on dirty tree or args), `build_pathspecs/0` (public helper deriving pathspecs from `Mix.Project.config()`), `ensure_no_args!/1`, and `raise_dirty!/1` private helpers.

## Decisions Made
None beyond the plan-level D-01 through D-05 (Context.md). Implementation copied the plan's action block verbatim.

## Deviations from Plan

None - plan executed exactly as written.

**Total deviations:** 0
**Impact on plan:** N/A

## Issues Encountered

- **First test run after implementation showed 1 failure** — the clean-path test failed because the newly-created `.ex` file was still untracked at test time (the file being tested flagged itself). This was **expected behavior**, not a defect: the test is tagged `@tag :requires_clean_workspace` per Plan 01 Task 2's tolerant-design directive. Re-running after `git commit` reports 3/3 green, confirming the task is doing its job correctly.
- No other issues encountered.

## TDD Gate Compliance

- RED gate: Plan 01's `102322d` commit (`test(18-01): add red-state YAML-grep contract tests for INFRA-01/02/03/04 wiring`) plus the companion `test/mix/tasks/verify_workspace_clean_test.exs` file established the failing test contract for INFRA-01.
- Confirmed 3-failure baseline locally before implementing (`mix test test/mix/tasks/verify_workspace_clean_test.exs` → `3 tests, 3 failures`).
- GREEN gate: `0df164c` (`feat(18-02): implement Mix.Tasks.Verify.WorkspaceClean (INFRA-01)`) turns the RED tests green — final local run reports `3 tests, 0 failures`.
- REFACTOR gate: not needed; implementation landed clean against the contract.

## User Setup Required

None — no external service configuration required. This is a local Mix task that shells out to `git status`.

## Verification Evidence

1. `mix compile --warnings-as-errors` — passed with no warnings.
2. `mix test test/mix/tasks/verify_workspace_clean_test.exs --exclude integration` — `3 tests, 0 failures` (after implementation file committed).
3. Manual clean-tree invocation: `MIX_ENV=test mix verify.workspace_clean` → `==> Checking workspace cleanliness for packaged paths` + `Workspace clean across 9 pathspecs` + exit 0.
4. Manual dirty-tree invocation: `touch lib/scrypath/_tmp_dirty.ex && MIX_ENV=test mix verify.workspace_clean` → `Workspace is not clean.` + offending path + `git add / git stash -u / git checkout --` hints + `.planning/milestones/v1.2-MILESTONE-AUDIT.md` backref + exit 1.
5. Manual arg-guard: `MIX_ENV=test mix verify.workspace_clean --allow-dirty` → `verify.workspace_clean does not accept arguments, got: --allow-dirty` + exit 1.
6. D-04 grep: `grep -E "(--allow-dirty|SCRYPATH_WORKSPACE_CLEAN_SKIP|allow_dirty|:skip_check|OptionParser\.parse|if System\.get_env\()" lib/mix/tasks/verify.workspace_clean.ex` → no matches.

## Next Phase Readiness

- INFRA-01 now fully implemented and covered by 3 green tests.
- Plan 18-03 (verify.release_parity composer) can safely call / depend on `mix verify.workspace_clean`.
- Plan 18-04 (workflow wiring) can reference `mix verify.workspace_clean` as the first step in `release-please.yml`, `release-recovery-publish.yml`, and the per-push CI workflow.
- No blockers for downstream plans.

## Self-Check: PASSED

- FOUND: lib/mix/tasks/verify.workspace_clean.ex
- FOUND commit: 0df164c (feat(18-02): implement Mix.Tasks.Verify.WorkspaceClean)

---
*Phase: 18-release-parity-gate-node-20-ci-cleanup*
*Plan: 02*
*Completed: 2026-04-17*
