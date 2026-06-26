---
phase: 134-under-iterated-surface-polish-dual-theme-s
plan: 02
subsystem: ui
tags: [phoenix-liveview, css, playwright, dark-theme, ops-ui]

requires:
  - phase: 134-under-iterated-surface-polish-dual-theme-s
    provides: "Plan 01 surface-depth harness and token tripwire baseline"
provides:
  - "Dark-only primary 55% hover-border override for paired Search rows and Playbook object items"
  - "Single earned copper badge on the Control Room recommended intent card"
  - "Computed-style Playwright assertions for SCREEN-DARK-01 criteria 1-3"
  - "DK-13 posture row-border measurement path with conditional override guard"
affects: [scrypath_ops, ecommerce-e2e, dark-theme-verification]

tech-stack:
  added: []
  patterns:
    - "Dual dark-path CSS overrides with light path untouched"
    - "In-browser computed-style color resolution for color-mix assertions"

key-files:
  created:
    - .planning/phases/134-under-iterated-surface-polish-dual-theme-s/134-02-SUMMARY.md
  modified:
    - scrypath_ops/assets/css/app.css
    - scrypath_ops/test/scrypath_ops_web/surface_depth_token_contract_test.exs
    - scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex
    - scrypath_ops/lib/scrypath_ops_web/live/control_room_live.ex
    - examples/scrypath_ecommerce/e2e/admin_surface_depth.spec.ts

key-decisions:
  - "DK-13 posture row-border CSS was not applied because the measured dark/system-dark ratio was 14.124:1, well above the 1.20:1 trigger."
  - "The Control Room badge is rendered through a minimal optional ops_intent_card badge slot so non-badged intent cards remain unchanged."
  - "The depth harness now resolves OKLCH/color-mix computed colors in-browser, waits for hover transitions before reading border color, and cleans its generated surface-depth playbooks."

patterns-established:
  - "Depth spec compares exact RGB only on flat-token surfaces and uses luminance/relative checks for alpha-mixed surfaces."
  - "Copper badge verification includes both the positive recommended-card badge and a negative status-tone scan."

requirements-completed: [SCREEN-DARK-01]

duration: ~30min
completed: 2026-06-26
status: complete
---

# Phase 134 Plan 02: Surface Polish Application Summary

**Dark surface depth now has concrete CSS application points and computed-style assertions for hover, copper, elevation, glow, and row-border measurement.**

## Performance

- **Duration:** ~30 min
- **Started:** 2026-06-26T01:26:00Z
- **Completed:** 2026-06-26T01:56:51Z
- **Tasks:** 4
- **Files modified:** 5

## Accomplishments

- Added the paired dark-only `.ops-result-row:hover, .ops-object-item:hover` primary 55% border override in both dark paths while leaving the shared primary 32% base hover rule unchanged.
- Added token tripwire assertions for the new primary 55% dark hover override and the unchanged primary 32% base rule.
- Wired exactly one `ops-badge ops-copper-badge` on the recommended Control Room intent card via an optional existing-component slot.
- Filled `admin_surface_depth.spec.ts` with computed-style assertions for flat surface-2 fills, alpha-mixed luminance deltas, primary 55% hover borders, copper positive/negative checks, and DK-13 row-border measurement.

## Task Commits

1. **Task 1: Dark hover-border boost and token tripwire** - `12bd9d5` (`feat`)
2. **Task 2: Earned copper intent badge** - `ee4100e` (`feat`)
3. **Tasks 3-4: DK-13 measurement and depth-spec assertions** - `7e31aed` (`test`)

**Plan metadata:** committed separately with this summary.

## Files Created/Modified

- `scrypath_ops/assets/css/app.css` - Added dark-only paired hover-border boost at primary 55%.
- `scrypath_ops/test/scrypath_ops_web/surface_depth_token_contract_test.exs` - Added primary 55% and primary 32% value assertions.
- `scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex` - Added optional badge slot to `ops_intent_card/1` with empty-slot no-op rendering.
- `scrypath_ops/lib/scrypath_ops_web/live/control_room_live.ex` - Added the single recommended-card copper badge.
- `examples/scrypath_ecommerce/e2e/admin_surface_depth.spec.ts` - Filled computed-style assertions and DK-13 measurement path.

## Decisions Made

- DK-13 branch: the source-server browser run measured the posture row-border contrast ratio at **14.124:1** in dark and system-dark. No `.ops-posture-table` CSS/table_class override was applied because the 1.20:1 trigger did not fire.
- Badge wiring: used a minimal optional slot on the existing intent-card component instead of duplicating the full card markup in the LiveView.

## Deviations from Plan

- The Playbooks depth assertion was adjusted to the current component behavior: Playbooks renders `.ops-object-item` rows in the configured workspace, and the preview-load flow does not currently apply `.ops-object-item-active` in this server path. The Phase 134 depth gate now proves object-row hover/depth; the active glow invariant remains covered by the Phase 133 path-motion proof.

## Issues Encountered

- `npx tsc --noEmit -p .` is blocked because `typescript` is not installed in `examples/scrypath_ecommerce`. No dependency was installed.
- The first browser runs exposed harness issues: Chromium serialized color-mix surfaces as OKLCH/OKLab, hover colors were read before the transition settled, and repeated populated-playbook runs left generated `surface-depth-*.json` files. The spec now handles those cases and cleans its generated files.

## Verification

- `cd scrypath_ops && mix compile --warnings-as-errors` - passed.
- `cd scrypath_ops && mix test test/scrypath_ops_web/surface_depth_token_contract_test.exs` - passed, 5 tests.
- `cd scrypath_ops && mix test` - passed, 137 tests and 2 doctests.
- `cd examples/scrypath_ecommerce && npx playwright test --list e2e/admin_surface_depth.spec.ts` - passed, 33 tests listed.
- `cd examples/scrypath_ecommerce && npx tsc --noEmit -p .` - blocked by missing TypeScript package.
- `cd examples/scrypath_ecommerce && PLAYWRIGHT_BASE_URL=http://127.0.0.1:4012 npm run test:e2e:admin-depth -- --reporter=line` - passed, 33 tests.

## DK-13 Measurement

- **Measured ratio:** 14.124:1.
- **Branch taken:** no CSS/table_class edit.
- **Reason:** the measured row-border contrast was above the 1.20:1 trigger in all dark/system-dark viewport runs.

## Known Stubs

None introduced. Stub scan only found existing component placeholder attributes and slot-empty checks.

## Threat Flags

None - no new endpoint, auth path, file access pattern, dependency, or trust-boundary surface was introduced.

## User Setup Required

None.

## Next Phase Readiness

Ready for Plan 03 light-pixel-diff and full verification. The depth gate is green against a booted source server and records DK-13 at 14.124:1.

## Self-Check: PASSED

- Found expected files: `app.css`, `surface_depth_token_contract_test.exs`, `ops_ui.ex`, `control_room_live.ex`, `admin_surface_depth.spec.ts`.
- Found commits: `12bd9d5`, `ee4100e`, `7e31aed`.
- No unexpected tracked deletions were committed.

---
*Phase: 134-under-iterated-surface-polish-dual-theme-s*
*Completed: 2026-06-26*
