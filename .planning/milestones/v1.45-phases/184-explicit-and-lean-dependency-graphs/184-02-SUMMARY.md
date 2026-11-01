---
phase: 184-explicit-and-lean-dependency-graphs
plan: "02"
subsystem: dependency-management
tags: [elixir, mix, swoosh, phoenix]
requires: []
provides:
  - Removed direct Swoosh declarations from Ops and ecommerce manifests.
  - Deleted the unused ScrypathOps Mailer and its Swoosh-only test.
  - Removed mail adapter and API-client settings from all five Ops config files.
affects: [dependency-graphs, scrypath_ops, ecommerce-example, phase-184-lock-pruning]
actuals:
  tokens: 1998
  tasks: 2
  commits: 2
  plan_head_before: 5b628a0a1f73767d8258cf7aaca694a08f90724b
  plan_head_after: db05f9332a98ffdd8c6ff38bfd74ac5e3b87777d
tech-stack:
  added: []
  patterns:
    - Keep unused dependency implementation/config removal separate from later lock pruning and application startup verification.
key-files:
  created:
    - .planning/phases/184-explicit-and-lean-dependency-graphs/184-02-SUMMARY.md
  modified:
    - scrypath_ops/mix.exs
    - examples/scrypath_ecommerce/mix.exs
    - scrypath_ops/config/config.exs
    - scrypath_ops/config/dev.exs
    - scrypath_ops/config/test.exs
    - scrypath_ops/config/prod.exs
    - scrypath_ops/config/runtime.exs
  deleted:
    - scrypath_ops/lib/scrypath_ops/mailer.ex
    - scrypath_ops/test/scrypath_ops/swoosh_api_client_req_test.exs
key-decisions:
  - "Leave Ops and ecommerce lockfiles unchanged; Plan 184-07 owns scoped unused-lock pruning after dependency-boundary changes."
  - "Defer coherent Ops/ecommerce compile and startup until Plan 184-11 completes route and host configuration removal."
requirements-completed: [DEP-03]
coverage:
  - id: D1
    description: Ops and ecommerce no longer directly declare Swoosh; the unused Ops Mailer and Swoosh-only test are deleted.
    requirement: DEP-03
    verification:
      - kind: other
        ref: "Task 184-02-01 Python source predicate: mail-declarations-and-source-removed"
        status: pass
      - kind: other
        ref: "Elixir 1.17.3 / OTP 27: focused Mix format checks for both changed manifests"
        status: pass
    human_judgment: false
  - id: D2
    description: All five Ops config files are free of mail configuration while Repo, runtime secrets, asset versions, and environment imports remain unchanged.
    requirement: DEP-03
    verification:
      - kind: other
        ref: "Task 184-02-02 Python source predicate: five-mail-configs-cleared"
        status: pass
      - kind: other
        ref: "Filtered before/after config comparison and retained-setting assertions: retained-config-settings-unchanged"
        status: pass
      - kind: other
        ref: "Elixir 1.17.3 / OTP 27: mix format --check-formatted on the five changed Ops config files"
        status: pass
    human_judgment: false
duration: 9min
completed: 2026-10-29
status: complete
plan_head_before: 5b628a0a1f73767d8258cf7aaca694a08f90724b
plan_head_after: db05f9332a98ffdd8c6ff38bfd74ac5e3b87777d
---

# Phase 184 Plan 02: Explicit and Lean Dependency Graphs Summary

**Removed the unused Ops mail dependency slice while preserving host, Repo, asset, and runtime configuration boundaries.**

## Performance

- **Duration:** approximately 9 min
- **Started:** approximately 2026-10-29T20:35:31Z; exact start was not captured
- **Completed:** 2026-10-29T20:44:30Z
- **Tasks:** 2
- **Source files modified:** 9

## Accomplishments

- Removed direct Swoosh declarations from `scrypath_ops/mix.exs` and `examples/scrypath_ecommerce/mix.exs`.
- Deleted the unused `ScrypathOps.Mailer` module and its Swoosh-only Req client test.
- Removed mailer adapters, Swoosh API-client settings, and unused mail setup instructions from all five Ops config files. Preserved the Repo, runtime secret, asset version, and environment-import settings.
- Kept both lockfiles unchanged for scoped unused-dependency pruning in Plan 184-07. Full application compile/start remains with Plan 184-11-02 after route and host configuration removal.

## Task Commits

1. **Task 1: Remove unused mail declarations and implementation** - `3e02933e` (`chore`)
2. **Task 2: Remove every Ops mail configuration reference** - `db05f933` (`chore`)

Plan metadata is committed separately after this summary self-check.

## Files Created/Modified

- `scrypath_ops/mix.exs` - removed the direct Swoosh dependency.
- `examples/scrypath_ecommerce/mix.exs` - removed the duplicate direct Swoosh dependency.
- `scrypath_ops/lib/scrypath_ops/mailer.ex` - deleted the unused Mailer module.
- `scrypath_ops/test/scrypath_ops/swoosh_api_client_req_test.exs` - deleted the obsolete Swoosh-only test.
- `scrypath_ops/config/config.exs` - removed local mailer configuration.
- `scrypath_ops/config/dev.exs` - removed Swoosh configuration and updated the developer-route comment.
- `scrypath_ops/config/test.exs` - removed test mailer and Swoosh API-client settings.
- `scrypath_ops/config/prod.exs` - removed Swoosh API-client and local-storage settings.
- `scrypath_ops/config/runtime.exs` - removed obsolete production mail setup instructions.

## Decisions Made

- Did not edit either lockfile; later plan 184-07 owns dependency graph resolution and unused-lock pruning.
- Did not compile or start the intentionally incomplete Ops/ecommerce application slice; Plan 184-11-02 owns coherent application verification.
- `requirements.ready-ids` reported DEP-03 blocked by sibling Plans 184-06, 184-07, 184-10, and 184-11. The global requirement remains pending until those plans complete.

## Verification

- Task 184-02-01 Python source predicate - passed with `mail-declarations-and-source-removed`.
- Focused Ops manifest format check - passed using Elixir 1.17.3 / OTP 27.
- Focused ecommerce manifest format check - passed using a temporary dependency-free formatter config because the app formatter imports dependencies not installed in this worktree.
- Task 184-02-02 Python source predicate - passed with `five-mail-configs-cleared`.
- Filtered before/after comparison of executable config lines and retained-setting assertions - passed with `retained-config-settings-unchanged`.
- Focused format check for the five changed Ops config files - passed using Elixir 1.17.3 / OTP 27.
- `git diff --check` - passed; both lockfiles are unchanged from the plan base.
- No application compile/start or lock-pruning check was run, as those belong to Plans 184-11 and 184-07.

## Deviations from Plan

### Auto-fixed verification issue

**1. [Rule 3 - Blocking] Scoped formatter verification to changed files**

- **Found during:** Tasks 1 and 2
- **Issue:** App-local formatter commands could not load `:ecto_sql` from the formatter import list because app dependencies are not installed in this worktree. The repository-wide formatter check also reports six existing formatting differences in unrelated files.
- **Fix:** Used the installed supported Elixir 1.17.3 / OTP 27 toolchain, checked changed Ops files with the repository formatter, and checked the ecommerce manifest with a temporary formatter config that does not import absent dependencies. No dependencies were fetched and no unrelated files were changed.
- **Files modified:** None beyond the planned task files.
- **Verification:** All focused formatter commands listed above passed; the full repository formatter result remains limited by pre-existing unrelated differences.
- **Committed in:** `3e02933e`, `db05f933`

**Total deviations:** 1 verification adaptation (Rule 3 - blocking). **Impact:** Planned source scope was unchanged; all changed files passed focused formatting and source checks.

## Issues Encountered

- The named retained preview checkout is `/Users/jon/projects/scrypath/.claude/worktrees/ui-experience-reconciliation`, branch `ui/next`. The container bind mount and URL were verified (`/app` to that checkout, healthy at `127.0.0.1:4002`), but `npm run ui:preflight` refused because its HEAD does not include locally known `origin/main`. That checkout also contains unrelated pending edits in `scrypath_ops/priv/static/assets/css/app.css` and untracked `examples/scrypath_ecommerce/priv/playbooks/`. It was not changed, restarted, or reseeded; no UI capture or latest-preview claim is made. This dependency/configuration-only plan made no rendered UI change.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

This plan's source-removal slice is complete. DEP-03 remains globally pending until its sibling plans complete. Plan 184-07 owns lock pruning; Plan 184-11 owns remaining route/host configuration and coherent compile/start verification.

## Self-Check: PASSED

- Summary exists and every modified file exists; the two planned source deletions are absent.
- Task commits `3e02933e` and `db05f933` are ancestors of the current worktree HEAD.
- `evaluation-scope --plan 184-02 --commits-only` resolved both plan commits with no missing-on-disk or unreachable commits.
- Task acceptance predicates and focused formatting checks passed before summary creation; `git diff --check` passed.

---
*Phase: 184-explicit-and-lean-dependency-graphs*
*Completed: 2026-10-29*
