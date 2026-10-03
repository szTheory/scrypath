---
phase: 172-consistent-operator-ui-and-verified-recovery
plan: "01"
subsystem: ui
tags: [phoenix, liveview, ops-ui, css, accessibility]
requires: []
provides:
  - One shell shortcut, a cause-specific Control Room status, and readable shared actions.
  - A token catalog and regression checks for all 48 OpsUi exports.
affects: [Phase 172 Plans 02-08, operator-ui, design-tokens]
actuals:
  tokens: 7139
  tasks: 2
  commits: 3
tech-stack:
  added: []
  patterns: [OpsUi shared role authority, synchronized tracked CSS output]
key-files:
  created: []
  modified: [scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex, scrypath_ops/assets/css/app.css, scrypath_ops/lib/scrypath_ops_web/components/layouts.ex, scrypath_ops/lib/scrypath_ops_web/live/control_room_live.ex, scrypath_ops/priv/static/assets/css/app.css, scrypath_ops/test/scrypath_ops_web/live/control_room_live_test.exs, scrypath_ops/test/scrypath_ops_web/ops_shell_contract_test.exs, scrypath_ops/assets/css/DESIGN-TOKENS.md, scrypath_ops/test/scrypath_ops_web/design_tokens_contract_test.exs, scrypath_ops/assets/css/contrast-pairs.mjs]
key-decisions:
  - One accessible “Jump to surface” keycap control lives in the shared header.
  - Retain cause-specific degraded evidence; remove the unsupported federation claim.
  - Commit generated CSS served by the app; discard unrelated generated JavaScript.
patterns-established:
  - Action labels are 14px; standard targets are 40px and prominent/icon targets are 44px.
  - Panels use 16/20px responsive padding; Control Room sections use the named 24px gap.
requirements-completed: [OPUX-01, OPUX-03, OPUX-07]
coverage:
  - id: D1
    description: One shortcut, Posture recovery handoff, and cause-specific degraded status render in Control Room.
    requirement: OPUX-01
    verification: [{kind: unit, ref: "control_room_live_test.exs (6 tests) and ops_shell_contract_test.exs", status: pass}]
    human_judgment: false
  - id: D2
    description: All 48 OpsUi exports and shared roles are cataloged and checked.
    requirement: OPUX-03
    verification: [{kind: unit, ref: "design_tokens_contract_test.exs (4 tests)", status: pass}, {kind: other, ref: "make -C examples/scrypath_ecommerce contrast", status: pass}]
    human_judgment: false
duration: 32min
completed: 2026-10-03
status: complete
plan_head_before: 5c00eb994ff0f6dc0dd66f26e4441a55d1dd30e8
plan_head_after: ecfb2e23983b9f6fcf1fc254648252523fc48ce1
---

# Phase 172 Plan 01: Consistent Operator UI Summary

**Control Room now has one surface-jump shortcut, a truthful recovery handoff, readable shared actions, and token contracts for all 48 OpsUi exports.**

## Performance

- **Duration:** 32 minutes; **started:** 2026-10-03T16:05:21Z; **completed:** 2026-10-03T16:37:25Z
- **Tasks:** 2; **files modified:** 10

## Accomplishments

- Consolidated three shortcut hints into one clickable header action; removed the unearned “Federated” badge and retained the real failed-sync evidence and Posture route.
- Set shared action labels to 14px, standard controls to 40px, recovery/icon targets to 44px, responsive panel padding to 16/20px, and Control Room section spacing to 24px.
- Cataloged all 48 OpsUi exports, added focused role checks, updated the contrast manifest, and regenerated served CSS.

## Task Commits

1. **Task 1 RED assertions:** `01f79f7` — test
2. **Task 1 GREEN implementation:** `0778769` — feat
3. **Task 2 token catalog/contracts:** `ecfb2e2` — test

## Deviations from Plan

- **Rule 1 — Existing shell tests:** Four route tests expected at least two shortcut controls. Updated the shared assertion to require exactly one; full suite passed. Included in `0778769`.
- **Rule 2 — Shipped CSS parity:** The app serves `priv/static/assets/css/app.css`; regenerated and committed it so shipped styles match source. Restored unrelated generated JS. Included in `0778769`.

## Verification

- Focused Control Room LiveView: 6 tests, 0 failures.
- Focused token contract: 4 tests, 0 failures.
- `mix precommit --exclude integration --exclude docs_contract`: 2 doctests, 157 tests, 0 failures.
- Contrast: PASS, 0 AA failures; 36 AAA advisory findings.
- `MIX_ENV=dev mix assets.build`: completed; tracked CSS synchronized.

## TDD Evidence and Issues

- RED run: 6 tests, 2 assertion failures, including the target shortcut assertion (rendered 3 controls instead of 1); GREEN run passed all 6.
- `gsd_run check tdd-red-evidence` classified ExUnit output as `INVALID_RED` because the checker parses Node TAP/Surefire XML. Actual output is preserved at `/private/tmp/phase172-01-red.log`; no synthetic output was used.
- Locked dependencies were hydrated under a task-local Hex cache; `mix.lock` stayed unchanged. Compile output includes an unrelated existing typing warning in `scrypath/lib/scrypath/sync.ex:61`.

## Next Phase Readiness

The Control Room/shared-control slice is committed. Browser-computed sizing remains in the later Phase 172 sizing verification plan.

## Self-Check: PASSED

- Summary exists at the expected phase path; task commits `01f79f7`, `0778769`, and `ecfb2e2` are present.
- Working tree was clean before summary creation.

---
*Phase: 172-consistent-operator-ui-and-verified-recovery*
*Completed: 2026-10-03*
