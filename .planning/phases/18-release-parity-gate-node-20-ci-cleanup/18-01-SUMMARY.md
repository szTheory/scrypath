---
phase: 18-release-parity-gate-node-20-ci-cleanup
plan: 01
subsystem: testing
tags: [elixir, mix-task, test-scaffolding, ci, release-parity, tdd-red, wave-0]

# Dependency graph
requires: []
provides:
  - "test/mix/tasks/verify_workspace_clean_test.exs — red-state INFRA-01 unit tests (build_pathspecs/0, arg-guard, clean-path)"
  - "test/mix/tasks/verify_release_parity_test.exs — red-state INFRA-02 unit + @tag :integration canary (compute/2, render_json/4, retry_until!/4, parse_version!/1)"
  - "test/mix/tasks/workflow_wiring_test.exs — red-state YAML-grep contract tests for INFRA-01/02/03/04 cross-workflow wiring"
  - "mix.exs cli.preferred_envs registration for verify.workspace_clean and verify.release_parity (prevents Pitfall 10)"
affects: [18-02, 18-03, 18-04, 18-05, 18-06, 18-07]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Wave 0 test scaffolding: red-state tests created BEFORE implementation so downstream plans anchor acceptance criteria"
    - "YAML-grep contract tests via File.read!/1 on constant-path module attributes (no injection surface)"
    - "cli.preferred_envs registration for new Mix.Tasks.Verify.* tasks to avoid compile-time env mismatch"

key-files:
  created:
    - "test/mix/tasks/verify_workspace_clean_test.exs"
    - "test/mix/tasks/verify_release_parity_test.exs"
    - "test/mix/tasks/workflow_wiring_test.exs"
  modified:
    - "mix.exs"

key-decisions:
  - "[Phase 18]: Wave 0 creates test surfaces BEFORE implementation (TDD-lite) so Plans 02/03/04/05/06 turn tests green incrementally rather than writing tests and implementation in the same commit."
  - "[Phase 18]: Mix.Task.reenable/1 + Mix.Task.run/2 idiom requires async: false because the task registry is global mutable state."
  - "[Phase 18]: cli.preferred_envs entries for new verify.* tasks inserted between verify.release_publish and credo/dialyzer to preserve ordering convention."
  - "[Phase 18]: YAML contract tests live in test/mix/tasks/workflow_wiring_test.exs (not a separate tests/workflows/ tree) so all cross-workflow assertions sit with the Mix task unit tests, centralizing phase 18 validation surface."

patterns-established:
  - "Mix task red-state test pattern: defmodule Mix.Tasks.Verify.*Test + use ExUnit.Case, async: false + import ExUnit.CaptureIO + Mix.Task.reenable + Mix.Task.run + assert_raise Mix.Error"
  - "Pure-function testability seam: Mix task modules expose public helpers (build_pathspecs/0, compute/2, render_json/4, retry_until!/4, parse_version!/1) that bypass System.halt and I/O, making unit tests deterministic without integration tags"
  - "YAML-wiring contract tests: module attributes @*_yml hold workflow paths, File.read!/1 + =~ regex / refute asserts both presence (required wiring) and absence (no legacy pins)"

requirements-completed: []

# Metrics
duration: 4min
completed: 2026-04-17
---

# Phase 18 Plan 01: Wave 0 Test Scaffolding Summary

**Three red-state test files (31 tests total, 28 failing red as intended) + mix.exs cli.preferred_envs registration — the load-bearing test scaffolding every Phase 18 implementation plan anchors acceptance criteria against.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-04-17T13:46:57Z
- **Completed:** 2026-04-17T13:51:19Z
- **Tasks:** 4
- **Files created:** 3
- **Files modified:** 1

## Accomplishments

- Registered `:"verify.workspace_clean": :test` and `:"verify.release_parity": :test` in `Scrypath.MixProject.cli/0` preferred_envs (prevents Pitfall 10 compile-time env mismatch on first task invocation).
- Created `test/mix/tasks/verify_workspace_clean_test.exs` with 3 tests across 3 describe blocks (build_pathspecs/0, arg-guard, clean-path) — all 3 tests fail red awaiting `Mix.Tasks.Verify.WorkspaceClean` implementation in Plan 02.
- Created `test/mix/tasks/verify_release_parity_test.exs` with 15 tests across 5 describe blocks (compute/2 path-diff, render_json/4 stable-field-order, retry_until!/4 CDN retry, parse_version!/1 Security V5 injection guard, integration canary) — 14 unit tests fail red + 1 @tag :integration subprocess canary awaiting `Mix.Tasks.Verify.ReleaseParity` implementation in Plan 03.
- Created `test/mix/tasks/workflow_wiring_test.exs` with 15 tests across 5 describe blocks (INFRA-01 3-publish-path workspace_clean gate, INFRA-02 release_parity step, INFRA-03 checkout@v6/cache@v5 pins with v4 refute, INFRA-04 scheduled drift-issue wiring, mix.exs cli.preferred_envs) — 3 tests green (2 cli.preferred_envs + 1 pre-existing cron trigger) + 12 tests red awaiting YAML edits in Plans 04/05/06.
- Established the public testability seam for both upcoming Mix tasks: plan documents required public signatures (build_pathspecs/0, compute/2, render_json/4, retry_until!/4, parse_version!/1) so Plans 02/03 can implement without re-designing the API.

## Task Commits

Each task was committed atomically:

1. **Task 1: Register verify.workspace_clean and verify.release_parity in mix.exs cli.preferred_envs** — `020548b` (feat)
2. **Task 2: Create test/mix/tasks/verify_workspace_clean_test.exs (red-state INFRA-01 unit tests)** — `fe46d60` (test)
3. **Task 3: Create test/mix/tasks/verify_release_parity_test.exs (red-state INFRA-02 unit + integration canary)** — `705fd44` (test)
4. **Task 4: Create test/mix/tasks/workflow_wiring_test.exs (red-state YAML-grep contract tests)** — `102322d` (test)

_Note: All 4 tasks are TDD RED commits — no implementation shipped. Plans 02/03 will add the corresponding GREEN (feat) commits._

## Files Created/Modified

- `mix.exs` — Added two `cli.preferred_envs` entries (`"verify.workspace_clean": :test`, `"verify.release_parity": :test`) between `verify.release_publish` and `credo`.
- `test/mix/tasks/verify_workspace_clean_test.exs` — 3 tests covering INFRA-01 unit behavior for `Mix.Tasks.Verify.WorkspaceClean.build_pathspecs/0`, arg-guard `Mix.Error` on stray args, and a tolerant progress-marker match on the clean path (tagged `:requires_clean_workspace`).
- `test/mix/tasks/verify_release_parity_test.exs` — 15 tests covering INFRA-02 compute/2 (3 parity/drift cases), render_json/4 (2 shapes), retry_until!/4 (2 CDN-retry paths), parse_version!/1 (6 Security V5 cases: shell-meta, partial, v-prefix, canonical, pre-release, missing arg), and 1 `@tag :integration` subprocess canary asserting `exit 0` for `0.3.0` (D-21 known-good).
- `test/mix/tasks/workflow_wiring_test.exs` — 15 tests covering INFRA-01 three-publish-path symmetry (3 tests), INFRA-02 release_parity step (1), INFRA-03 action pins (4 — checkout@v6/cache@v5 assert + v4 refute + minimum 4 refs each), INFRA-04 scheduled drift-issue wiring (5 — failure+schedule guard, JasonEtco/create-an-issue@v2, update_existing:true, issues:write permission, cron trigger), and mix.exs cli.preferred_envs (2).

## Decisions Made

None beyond what the plan specified. All four tasks executed exactly as written.

## Deviations from Plan

None — plan executed exactly as written.

One observation worth recording (not a deviation): the plan anticipated 2 of 15 `workflow_wiring_test.exs` tests would be green after Task 1 (the two cli.preferred_envs tests). In practice 3 of 15 are green because the pre-existing `verify-published-release.yml` already carries the `schedule:\n  - cron:` trigger this plan's INFRA-04 test asserts must be present. The test is correctly designed — it asserts the cron trigger stays present as a guard against accidental removal when Plans 06 edits the workflow. The expected 10 "YAML-wiring" tests (workspace_clean gate ×3, release_parity step ×1, action pins ×4, INFRA-04 NEW wiring ×4) remain red exactly as planned, awaiting Plans 04/05/06.

## Issues Encountered

- **Dependencies not installed** (encountered during Task 1 verification): `mix compile --warnings-as-errors` initially failed with "Unchecked dependencies for environment dev". Resolved by running `mix deps.get` to fetch the Hex packages. Not a code-level issue — the fresh worktree didn't have a `deps/` directory yet. This is expected in a fresh worktree checkout, not a plan deviation.

## Verification Results

Per plan `<verification>` section:

1. `mix compile --warnings-as-errors` — PASSES clean (no warnings).
2. `mix test test/mix/tasks/ --exclude integration` — 31 tests total, 28 failures, 1 excluded:
   - `verify_workspace_clean_test.exs`: 3/3 red (module missing, `UndefinedFunctionError`/`Mix.NoTaskError`)
   - `verify_release_parity_test.exs`: 13/13 red unit (module missing), 1 integration excluded
   - `workflow_wiring_test.exs`: 12/15 red (YAML not yet wired), 3/15 green (2 cli.preferred_envs + 1 pre-existing cron trigger)
3. `grep -c '"verify' mix.exs` returns **9** (7 original verify.* + 2 new) ✓

All three verification gates satisfied. Wave 0 red-state signal intact for Plans 02/03/04/05/06 to turn tests green incrementally.

## Self-Check: PASSED

Files created (verified present):
- `test/mix/tasks/verify_workspace_clean_test.exs` — FOUND
- `test/mix/tasks/verify_release_parity_test.exs` — FOUND
- `test/mix/tasks/workflow_wiring_test.exs` — FOUND

File modified (verified change present):
- `mix.exs` — FOUND (`"verify.workspace_clean": :test` and `"verify.release_parity": :test` at lines 46-47)

Commits (verified in `git log`):
- `020548b` — FOUND (Task 1: feat(18-01) cli.preferred_envs)
- `fe46d60` — FOUND (Task 2: test(18-01) verify_workspace_clean_test)
- `705fd44` — FOUND (Task 3: test(18-01) verify_release_parity_test)
- `102322d` — FOUND (Task 4: test(18-01) workflow_wiring_test)

## User Setup Required

None — no external service configuration required. All changes are in-repo test scaffolding and one `mix.exs` config line.

## Next Phase Readiness

- **Plan 02 (implement Mix.Tasks.Verify.WorkspaceClean)** can now anchor acceptance criteria against `test/mix/tasks/verify_workspace_clean_test.exs` — all 3 tests go green when the module is implemented with `build_pathspecs/0`, `run/1` arg-guard, and the progress-marker output.
- **Plan 03 (implement Mix.Tasks.Verify.ReleaseParity)** can anchor acceptance criteria against `test/mix/tasks/verify_release_parity_test.exs` — 14 unit tests go green when the public API (`compute/2`, `render_json/4`, `retry_until!/4`, `parse_version!/1`) is implemented per documented signatures; the `@tag :integration` canary runs separately and asserts exit 0 for the 0.3.0 known-good version.
- **Plan 04 (workspace_clean wiring)** turns INFRA-01 D-14 three-publish-path tests green (ci.yml, publish-hex.yml, release-please.yml).
- **Plan 05 (ci.yml Node pins)** turns INFRA-03 D-13 checkout@v6 / cache@v5 tests green with v4-refute guard.
- **Plan 06 (verify-published-release.yml release_parity + create-an-issue)** turns INFRA-02 D-18 and INFRA-04 D-19 tests green.
- No blockers. The Wave 0 scaffold is complete, committed, and the downstream plans have precise green-state targets.

---
*Phase: 18-release-parity-gate-node-20-ci-cleanup*
*Plan: 01*
*Completed: 2026-04-17*
