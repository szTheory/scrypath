---
phase: 117-shared-ops-component-system
plan: 117
subsystem: ui
tags: [phoenix, liveview, scrypath_ops, opsui, accessibility]
requires:
  - phase: 116-opsui-asset-contract-and-design-tokens
    provides: OPSUI asset hooks, quiet operator tokens, and shell contract baseline
provides:
  - Shared `ScrypathOpsWeb.OpsUi` primitives for operator notices, metrics, empty states, schema selects, buttons, code blocks, panels, and modal wrappers
  - Reused component contracts across posture, failed sync, sync/drift, search/federation, and playbook screens
  - Safer allowlisted schema control handling that rejects unknown module strings without creating atoms or crashing LiveViews
affects: [opsui, scrypath_ops, admin-ui]
tech-stack:
  added: []
  patterns: [project-owned LiveView function components, allowlist-backed schema controls, quiet-ops reusable primitives]
key-files:
  created:
    - .planning/phases/117-shared-ops-component-system/117-SUMMARY.md
  modified:
    - scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex
    - scrypath_ops/lib/scrypath_ops_web/live/failed_sync_live.ex
    - scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex
    - scrypath_ops/lib/scrypath_ops_web/live/posture_live.ex
    - scrypath_ops/lib/scrypath_ops_web/live/search_live.ex
    - scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex
    - scrypath_ops/test/scrypath_ops_web/live/failed_sync_live_test.exs
    - scrypath_ops/test/scrypath_ops_web/live/posture_live_test.exs
    - scrypath_ops/test/scrypath_ops_web/live/sync_drift_live_test.exs
key-decisions:
  - "Keep OPSUI components as small Phoenix function components instead of introducing LiveComponents or a public component abstraction."
  - "Centralize visual primitives while keeping page-specific operator copy and data flow in each LiveView."
  - "Treat schema selectors and swap actions as allowlist-backed controls, not arbitrary module-name parsers."
patterns-established:
  - "Reusable OPSUI controls live in `ScrypathOpsWeb.OpsUi` and expose narrow attrs for LiveView event wiring."
  - "Operator screen empty/config states use `ops_empty_state/1`; warnings and honesty panels use `ops_notice/1`."
  - "Schema selection handlers compare against configured allowlists and reject unknown strings without atom creation."
requirements-completed: [COMP-01, A11Y-01]
duration: 33min
completed: 2026-06-01
---

# Phase 117 Plan 117: Shared Ops Component System Summary

**Shared Phoenix LiveView OPSUI primitives now drive stable operator notices, actions, metrics, empty states, schema controls, code blocks, and modal shells across the admin screens.**

## Performance

- **Duration:** 33 min
- **Started:** 2026-06-01T18:19:00Z
- **Completed:** 2026-06-01T18:52:00Z
- **Tasks:** 4
- **Files modified:** 9

## Accomplishments

- Extended `ScrypathOpsWeb.OpsUi` with shared panel, toolbar, button, notice, metric, empty state, schema select, code block, and modal primitives.
- Replaced repeated hand-rolled markup across posture, failed sync, sync/drift, search/federation, and saved playbooks where the component contract was stable.
- Added and aligned allowlist rejection coverage for schema controls so malicious or stale module strings do not create atoms or crash operator LiveViews.

## Task Commits

1. **Task 1: Shared OpsUi component primitives and screen replacements** - `122e2d8` (feat)
2. **Task 2: Allowlist-backed schema control hardening** - `122e2d8` (feat)
3. **Task 3: Component/a11y contract assertions** - `122e2d8` (feat)
4. **Task 4: Code review fixes for multi-schema forms, playbook reads, and modal keyboard semantics** - `11b0f7f` (fix)

## Files Created/Modified

- `scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex` - adds shared OPSUI function components for reusable admin UI primitives.
- `scrypath_ops/lib/scrypath_ops_web/live/failed_sync_live.ex` - replaces repeated buttons, schema select, metrics, and empty states; rejects unknown schema strings.
- `scrypath_ops/lib/scrypath_ops_web/live/posture_live.ex` - uses shared action/empty-state controls and rejects unknown swap schema strings.
- `scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex` - uses shared schema select, notices, and action controls with allowlist-backed schema handling.
- `scrypath_ops/lib/scrypath_ops_web/live/search_live.ex` - uses shared notices, empty states, action buttons, and code blocks.
- `scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex` - uses shared notices, action buttons, code blocks, and modal wrappers.
- `scrypath_ops/test/scrypath_ops_web/live/failed_sync_live_test.exs` - adds shared retry-copy and invalid schema selector contract coverage.
- `scrypath_ops/test/scrypath_ops_web/live/posture_live_test.exs` - adds next-check and invalid swap-schema contract coverage.
- `scrypath_ops/test/scrypath_ops_web/live/sync_drift_live_test.exs` - covers invalid schema selection without atom creation.

## Decisions Made

- Function components are enough for this phase; no LiveComponent state boundary was needed.
- Reuse is limited to stable visual/semantic primitives so each LiveView keeps its page-specific operator workflow and copy.
- Invalid schema strings should surface as operator feedback and preserve current state instead of raising.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Hardened schema controls against non-allowlisted module strings**
- **Found during:** Task 2 (replace stable schema/action controls)
- **Issue:** Failed-sync and posture controls still raised on unknown schema strings, which could crash the LiveView even though the UI presented an allowlisted selector/action.
- **Fix:** Reused allowlist comparison logic and added explicit flash feedback without atom creation.
- **Files modified:** `failed_sync_live.ex`, `posture_live.ex`, `failed_sync_live_test.exs`, `posture_live_test.exs`
- **Verification:** `mix compile --warnings-as-errors` passed; DB-backed LiveView tests were blocked by local Postgres startup/connection pressure.
- **Committed in:** `122e2d8`

---

**Total deviations:** 1 auto-fixed (1 missing critical)
**Impact on plan:** The fix strengthens the component contract and operator safety without expanding product scope.

### Code Review Fixes

- Fixed multi-index checkbox field naming so all selected schemas submit as `schemas[]`.
- Replaced example playbook read pattern matching with an error-returning flash path.
- Added shared modal close-button and Escape semantics through `cancel_event`.
- Re-review passed clean in `.planning/phases/117-shared-ops-component-system/117-REVIEW.md`.

## Issues Encountered

- Focused ScrypathOps LiveView tests could not run because local Postgres was unavailable/saturated:
  - First run failed with `Postgrex.Error FATAL 53300 too_many_connections`.
  - Subsequent focused runs failed with `Postgrex.Error FATAL 57P03 cannot_connect_now` while the database system was starting up.
- Compile-only verification passed, so the remaining blocker is DB-backed test execution rather than Elixir/template compilation.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Shared OPSUI primitives and screen replacements are implemented and compile-clean.
- Re-run the focused ScrypathOps LiveView tests after clearing local Postgres connection pressure.
- Phase 118 can continue screen-level polish on top of the component system, but final v1.32 verification should wait for DB-backed tests.

## Self-Check: PASSED

- Found summary file at `.planning/phases/117-shared-ops-component-system/117-SUMMARY.md`.
- Found task commit `122e2d8` in git history.
- Found review fix commit `11b0f7f` in git history.
- Found clean code review report at `.planning/phases/117-shared-ops-component-system/117-REVIEW.md`.
- Verified compile with `cd scrypath_ops && mix compile --warnings-as-errors`.
- DB-backed tests attempted and blocked by local Postgres availability, recorded above.
