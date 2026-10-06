---
phase: 173-shared-visual-foundation-and-operational-time
plan: 01
subsystem: ui
tags: [phoenix, liveview, operator-ui, theme-preference, playwright]

requires: []
provides:
  - Shared neutral Ops shell with System, Light, and Dark preference states.
  - Test-only mounted and standalone PostureLive routes backed by deterministic fixture sources.
  - Disposable Compose runner and browser proof for both Ops entrypoints.
affects: [scrypath_ops, operator-ui, phase-173]

actuals:
  tokens: 20314
  tasks: 3
  commits: 3
plan_head_before: 2993f5e663ea1e0ec5de7fca0bdeffcb01864950
plan_head_after: a80f979871318d7188576a6ee965a4d725cca33c

tech-stack:
  added: []
  patterns:
    - Test-only fixture sources dispatch into the production PostureLive and Status/State rendering path.
    - Browser verification uses an isolated Compose project with bounded teardown.
    - Theme selection derives from normalized preference, while effective appearance can follow OS media changes.

key-files:
  created:
    - examples/scrypath_ecommerce/e2e/phase173_shell.spec.ts
  modified:
    - scrypath_ops/assets/css/app.css
    - scrypath_ops/assets/css/DESIGN-TOKENS.md
    - scrypath_ops/lib/scrypath_ops_web/components/layouts/root.html.heex
    - scrypath_ops/lib/scrypath_ops_web/live/posture_live.ex
    - scrypath_ops/lib/scrypath_ops/posture.ex
    - examples/scrypath_ecommerce/assets/js/app.js
    - examples/scrypath_ecommerce/scripts/verify-phase173.sh
    - examples/scrypath_ecommerce/compose.phase173.yaml
    - examples/scrypath_ecommerce/test/support/phase173_fixture_source.ex

key-decisions:
  - "Preference selection is separate from effective appearance; System follows OS changes without changing the selected preference."
  - "Fixture routes and sources are test-only, app-local, and exercised on disposable services with no host port."
  - "Dark selected-state text and strong-primary colors were adjusted after the contrast check found AA failures."

requirements-completed: [OPUX-09, OPUX-12]
coverage:
  - id: D1
    description: Shared neutral shell and normalized, accessible System/Light/Dark preference behavior.
    requirement: OPUX-09
    verification:
      - kind: e2e
        ref: "bash examples/scrypath_ecommerce/scripts/verify-phase173.sh shell (4 Playwright cases)"
        status: pass
      - kind: integration
        ref: "make -C examples/scrypath_ecommerce contrast"
        status: pass
    human_judgment: true
    rationale: "Automated checks prove preference state, contrast, and geometry; visual adequacy still benefits from human review."
  - id: D2
    description: Disposable mounted and standalone routes render deterministic source rows through production PostureLive.
    requirement: OPUX-12
    verification:
      - kind: integration
        ref: "bash examples/scrypath_ecommerce/scripts/verify-phase173.sh shell --smoke"
        status: pass
      - kind: e2e
        ref: "bash examples/scrypath_ecommerce/scripts/verify-phase173.sh shell (both source-backed routes and entrypoint assets)"
        status: pass
    human_judgment: false
  - id: D3
    description: Inspected light/dark browser captures at mobile and desktop widths for both entrypoints.
    verification:
      - kind: automated_ui
        ref: "examples/scrypath_ecommerce/test-results/phase173-shell-9bd2141eba/test-results/phase173-captures/phase173-{mounted,standalone}-{390,1440}-{light,dark}.png"
        status: pass
    human_judgment: true
    rationale: "Captures were visually inspected for hierarchy, spacing, theme contrast, and responsive overflow; final product judgment belongs to a human reviewer."

duration: 1h 53m
completed: 2026-10-06
status: complete
---

# Phase 173 Plan 01: Shared Visual Foundation and Operational Time Summary

**A neutral Ops shell, guarded System/Light/Dark preferences, and deterministic mounted and standalone PostureLive fixtures with browser proof.**

## Performance

- **Duration:** 1h 53m
- **Started:** 2026-10-06T19:57:50Z
- **Completed:** 2026-10-06T21:50:32Z
- **Tasks:** 3
- **Files modified:** 23

## Accomplishments

- Replaced the rejected shell backdrop with flat warm-neutral light and neutral-dark surfaces; preference selection is visible and distinct from OS-resolved appearance.
- Added test-only fixture sources and routes that render deterministic Search health through the production PostureLive path for mounted and standalone Ops.
- Added a disposable Compose browser runner covering preference changes, keyboard activation, cross-tab storage, storage denial, contrast, long navigation labels, reconnect feedback, scroll cues, and 390/1279/1280/1440px layouts.

## Task Commits

1. **Task 1: Render one preference-selected neutral Search health shell** - `0cfd365` (feat)
2. **Task 2: Expose disposable standalone Ops and mounted browser targets** - `9bd2141` (feat)
3. **Task 3: Prove complete shell and preference behavior in both entrypoints** - `a80f979` (feat)

**Plan metadata:** committed after this summary was written.

## Files Created/Modified

- `scrypath_ops/assets/css/app.css` and `scrypath_ops/priv/static/assets/css/app.css` - neutral shell palette, responsive shell rules, theme preference controls, and contrast-corrected selected colors.
- `scrypath_ops/lib/scrypath_ops_web/components/layouts.ex` and `layouts/root.html.heex` - accessible preference labels and guarded pre-paint theme state.
- `scrypath_ops/lib/scrypath_ops_web/live/posture_live.ex` and `scrypath_ops/lib/scrypath_ops/posture.ex` - deterministic test-only fixture rendering through production posture assembly.
- `scrypath_ops/test/support/phase173_fixture_source.ex` and `examples/scrypath_ecommerce/test/support/phase173_fixture_source.ex` - paired app-local test fixtures.
- `examples/scrypath_ecommerce/compose.phase173.yaml` and `scripts/verify-phase173.sh` - isolated disposable stack, smoke checks, browser run, and cleanup.
- `examples/scrypath_ecommerce/e2e/phase173_shell.spec.ts` - browser tests for both entrypoints.
- `examples/scrypath_ecommerce/assets/js/app.js` - guarded preference persistence, cross-tab sync, OS changes, and page-loading synchronization.
- `scrypath_ops/assets/css/DESIGN-TOKENS.md` - documented shell palette and preference contract.

## Verification

- `cd scrypath_ops && mix test test/scrypath_ops_web/ops_shell_contract_test.exs` - passed (9 tests, 0 failures during Task 1).
- `cd scrypath_ops && mix test test/scrypath_ops_web/ops_shell_contract_test.exs test/scrypath_ops_web/live/posture_live_test.exs` - passed (15 tests, 0 failures after fixture routes).
- `bash examples/scrypath_ecommerce/scripts/verify-phase173.sh shell --smoke` - passed; both production fixture routes rendered source rows, entrypoint CSS/JS returned 200, and disposable containers/network/volume were removed.
- `bash examples/scrypath_ecommerce/scripts/verify-phase173.sh shell` - passed on the final run (4 Playwright cases, 0 failures). Both entrypoints passed pointer and Space activation, cross-tab preference updates, OS changes under System, invalid and denied storage behavior, source-row and asset checks, contrast, reconnect visibility, scroll cues, and the approved responsive widths.
- `make -C examples/scrypath_ecommerce contrast` - passed with 0 AA failures; 35 AAA findings remain advisory.
- `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.4.1 HEX_HOME=/private/tmp/scrypath-phase173-20261006-155750/hex-home mix assets.build` in `scrypath_ops` - passed and regenerated tracked CSS output.
- `git diff --check` - passed. `gsd-tools check evaluation-scope --plan 173-01 --commits-only --raw` resolved the three task commits on this branch.

## Browser Captures and Inspection

Final actual-page captures were saved and inspected at:

- `examples/scrypath_ecommerce/test-results/phase173-shell-9bd2141eba/test-results/phase173-captures/phase173-mounted-1440-light.png`
- `examples/scrypath_ecommerce/test-results/phase173-shell-9bd2141eba/test-results/phase173-captures/phase173-mounted-1440-dark.png`
- `examples/scrypath_ecommerce/test-results/phase173-shell-9bd2141eba/test-results/phase173-captures/phase173-mounted-390-light.png`
- `examples/scrypath_ecommerce/test-results/phase173-shell-9bd2141eba/test-results/phase173-captures/phase173-mounted-390-dark.png`
- `examples/scrypath_ecommerce/test-results/phase173-shell-9bd2141eba/test-results/phase173-captures/phase173-standalone-1440-light.png`
- `examples/scrypath_ecommerce/test-results/phase173-shell-9bd2141eba/test-results/phase173-captures/phase173-standalone-1440-dark.png`
- `examples/scrypath_ecommerce/test-results/phase173-shell-9bd2141eba/test-results/phase173-captures/phase173-standalone-390-light.png`
- `examples/scrypath_ecommerce/test-results/phase173-shell-9bd2141eba/test-results/phase173-captures/phase173-standalone-390-dark.png`

The 1440px captures show the fixed rail, visible preference labels, flat neutral canvas, and source-backed schema cards. At 390px the rail becomes a drawer, metrics and schema details stack, and the preference controls remain visible without horizontal page overflow. Dark selected navigation and theme pills retain readable contrast.

The retained `http://127.0.0.1:4012/admin/search/health` preview was inspected read-only before implementation and was not mutated or reseeded. Its baseline appearance was visible during the session, but a durable before-image file was not saved. The phase's `173-warm-*` PNGs are design comps, not before screenshots of the running application.

## Decisions Made

- Only normalized preference controls selected/pressed state; System appearance follows `prefers-color-scheme` without acquiring selection authority.
- Fixture providers and route registration remain test-only and app-local; the disposable standalone server uses an isolated network and no host port.
- Dark primary content and strong-primary values were tuned after the contrast gate found AA failures.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected selected-theme text contrast**
- **Found during:** Task 3 contrast verification.
- **Issue:** The dark selected foreground combinations measured 2.03:1 and 2.94:1, below AA.
- **Fix:** Changed dark `--color-primary-content` to `#111419` and `--color-primary-strong` to `#aaa0ff`.
- **Files modified:** `scrypath_ops/assets/css/app.css`, `scrypath_ops/priv/static/assets/css/app.css`.
- **Verification:** `make -C examples/scrypath_ecommerce contrast` passed with 0 AA failures.
- **Committed in:** `a80f979`.

**Total deviations:** 1 auto-fixed (contrast correctness). **Impact:** Required to meet the plan's AA contrast requirement; no dependency or CI changes.

## Issues Encountered

- An extra broad ecommerce `mix test` run had 5 integration failures because its configured local Meilisearch endpoint was unavailable. The planned focused Ops suites and disposable-stack checks passed.
- The Ops asset build printed an existing Dialyzer typing warning in `Scrypath.Sync.sync_related/3`; it did not fail the build and is unrelated to this plan.
- Several browser assertions initially assumed a particular responsive duplicate would be visible or that a simulated pending class would survive a LiveView refresh. They were narrowed to the accessible home-link contract and the shell controls that remain visible during reconnect; the final four-case browser run passed.

## Known Limitations

- The pre-change preview was visually inspected but no durable actual-page before images were captured. The final after images are present at the paths above; the design comps are not substitutes for actual before screenshots.
- Task-level `tdd="true"` markers were verified with passing focused and browser tests, but this execute-plan run has no recorded intentional RED evidence or separate `test(...)` commits.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 01 is implemented and its runnable shell contract passes. The rendered fixture routes and disposable runner are ready for the following Phase 173 plans. The missing durable baseline screenshots are documented for the reviewer.

## Self-Check: PASSED

- Key implementation files exist and all three task commits are ancestors of the plan head.
- Final browser verification passed 4/4 cases; the disposable Compose project left no containers, network, or volume.
- Contrast, focused Ops tests, asset build, and whitespace checks passed as recorded above.
- Shared `STATE.md`, `ROADMAP.md`, `state.json`, and `REQUIREMENTS.md` were not edited.

---
*Phase: 173-shared-visual-foundation-and-operational-time*
*Completed: 2026-10-06*
