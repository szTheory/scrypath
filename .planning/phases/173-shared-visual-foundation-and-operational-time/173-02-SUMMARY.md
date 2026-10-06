---
phase: 173-shared-visual-foundation-and-operational-time
plan: 02
subsystem: operator-ui
tags: [elixir, ecto, phoenix-liveview, operational-time, playwright, accessibility]

# Dependency graph
requires:
  - phase: 173-01
    provides: production PostureLive fixture routes and paired mounted/standalone test sources
provides:
  - Validated backend and queue timestamp provenance with stable source-local observation references
  - Accessible exact ISO and UTC disclosure with explicit absent and unavailable states
  - Responsive browser coverage for mounted and standalone Ops entrypoints
affects: [173-03, 173-04, operator-ui, observability]

# Actuals (#2632)
actuals:
  tokens: 44261
  tasks: 3
  commits: 9
plan_head_before: 21deaec9169eeb2241e04e0c67638fe4fee13ac5
plan_head_after: 48fa8419ecd13d42fd8687e1000c9d09a76038b3

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Machine-readable TAP evidence for actual ExUnit RED runs
    - Native details/summary disclosure for exact operational timestamp evidence
key-files:
  created:
    - scrypath_ops/test/scrypath_ops_web/components/ops_ui_test.exs
    - scrypath_ops/test/support/tap_formatter.ex
    - examples/scrypath_ecommerce/e2e/phase173_time.spec.ts
  modified:
    - lib/scrypath/operator/state.ex
    - test/scrypath/operator/status_test.exs
    - scrypath_ops/lib/scrypath_ops/posture.ex
    - scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex
    - scrypath_ops/lib/scrypath_ops_web/live/posture_live.ex
    - scrypath_ops/assets/css/app.css
    - scrypath_ops/priv/static/assets/css/app.css
    - examples/scrypath_ecommerce/docker-playwright.sh
    - examples/scrypath_ecommerce/test/support/phase173_fixture_source.ex
    - scrypath_ops/test/scrypath_ops_web/live/posture_live_test.exs
    - scrypath_ops/test/support/phase173_fixture_source.ex
    - scrypath_ops/test/test_helper.exs
key-decisions:
  - Preserve validated source ISO only when parsing yields the same instant as the normalized timestamp.
  - Keep backend and queue last-success references source-local so a failed refresh cannot make old evidence appear new.
  - Use native disclosure controls and responsive wrapping without adding a date/time dependency or a public API field.
patterns-established:
  - Operational time displays pair snapshot-relative age with selectable source ISO and UTC explanation.
  - Failed, missing, invalid, and unused evidence retain distinct operator-facing meanings.
requirements-completed: [OPUX-14]

# Coverage metadata
coverage:
  - id: D1
    description: Stable source-derived operational time, full precision and offset, correct thresholds, and distinct absent/retained source states.
    requirement: OPUX-14
    verification:
      - kind: unit
        ref: "mix test test/scrypath/operator/status_test.exs"
        status: pass
      - kind: integration
        ref: "cd scrypath_ops && mix test test/scrypath_ops_web/live/posture_live_test.exs"
        status: pass
      - kind: unit
        ref: "cd scrypath_ops && mix test test/scrypath_ops_web/components/ops_ui_test.exs"
        status: pass
    human_judgment: false
  - id: D2
    description: Responsive exact timestamp disclosure in mounted and standalone Ops at mobile, breakpoint-adjacent, and desktop widths.
    requirement: OPUX-14
    verification:
      - kind: e2e
        ref: "bash examples/scrypath_ecommerce/scripts/verify-phase173.sh time (2 Playwright tests; 16 screenshots; final post-merge source 236443e2f67fc5a3f8487ec431557baa9520e2b3)"
        status: pass
      - kind: automated_ui
        ref: "/private/tmp/scrypath-phase173-20261006-155750/evidence/173-02/after/phase173-time-captures/"
        status: pass
      - kind: other
        ref: "make -C examples/scrypath_ecommerce contrast (0 AA failures)"
        status: pass
    human_judgment: false
    rationale: The approved UI contract resolves the design; executable layout/connection/patch assertions and actual-pixel inspection cover implementation without routine human UAT.

# Metrics
duration: 55min
completed: 2026-10-06
status: complete
---

# Phase 173 Plan 02: Stable Operational Time Summary

**Search health now shows snapshot-stable last-success ages with lossless backend and queue timestamps, explicit unknown states, and responsive exact-time disclosures.**

## Performance

- **Duration:** 55 min
- **Started:** 2026-10-06T22:08:25Z
- **Completed:** 2026-10-06T23:03:14Z
- **Tasks:** 3
- **Files modified:** 23 before this summary

## Accomplishments

- Preserved validated source ISO timestamp precision and offsets alongside parsed instants without changing public structs or completion selection.
- Carried source-local successful observation references across failed refreshes, preserving the previous evidence and distinguishing it from the latest Checked time.
- Added shared accessible exact-time disclosure with UTC explanation, precise threshold and future-time labels, and distinct no-success, missing-time, unavailable, and unused-queue states.
- Verified both production LiveView entrypoints with keyboard, pointer, and touch interaction, wrapping and no-overflow assertions at widths 390, 1279, 1280, and 1440.
- Corrected an overlap found in the first committed-source screenshot review by placing open timestamp evidence below its relative age; added a browser geometry assertion for the relationship.

## Task Commits

1. **Task 1: Stable backend source timestamp and retained evidence RED** — `2b04dff` (test)
2. **Task 1: Retained source evidence RED** — `dd33306` (test)
3. **Task 1: Render stable exact backend evidence** — `b2a4f6b` (feat)
4. **Task 2: Queue and threshold RED coverage** — `b612d0c` (test)
5. **Task 2: Preserve queue time and absent evidence semantics** — `83431fc` (feat)
6. **Task 3: Rendered browser proof RED** — `33748d1` (test)
7. **Task 3: Responsive browser evidence** — `77c8338` (feat)
8. **TAP formatter formatting required by the core gate** — `8f62c98` (style)
9. **Keep open exact timestamp evidence below its age** — `48fa841` (fix)

The T1 RED reports are `.planning/phases/173-shared-visual-foundation-and-operational-time/173-02-T1-red.{tap,json}` and `173-02-T1-retain-red.{tap,json}`. T2 RED is `173-02-T2-ops-red.{tap,json}`. T3 RED is `173-02-T3-browser-red.xml` with its companion JSON record. Each planned target failed on its behavior assertion, each report was checked by `gsd-tools.cjs check tdd-red-evidence`, and each returned `RED_EVIDENCE_OK` before implementation. The corresponding GREEN commits and tests passed.

## Verification

- `mix test test/scrypath/operator/status_test.exs` — passed, 5 tests, 0 failures.
- `(cd scrypath_ops && mix test test/scrypath_ops_web/live/posture_live_test.exs)` — passed, including the phase 173 failed-refresh retention and absence-state cases.
- `(cd scrypath_ops && mix test test/scrypath_ops_web/components/ops_ui_test.exs)` — passed, including precise boundaries, future instants, exact disclosure, and distinct unknown states.
- `bash examples/scrypath_ecommerce/scripts/verify-phase173.sh time` on committed source `48fa8419ecd13d42fd8687e1000c9d09a76038b3` — passed, 2 Playwright tests; disposable stack cleanup removed its containers, volume, and network.
- `mix verify.core --exclude integration --exclude docs_contract` on the same committed source — exit 0; format, clean packaged paths, warnings-as-errors compilation, Credo (2365 checks), 659 tests with 0 failures (85 excluded), docs with warnings as errors, and Standard Maturity Gate all passed.
- `make -C examples/scrypath_ecommerce contrast` — passed with 0 AA failures and 35 AAA advisories.
- `gsd-tools.cjs check evaluation-scope --plan 173-02 --commits-only --raw` — resolved the plan scope and found all 9 plan commits on this branch.

## Image Evidence and Inspection

- Before: `/private/tmp/scrypath-phase173-20261006-155750/evidence/173-02/baseline/`, source `21deaec9169eeb2241e04e0c67638fe4fee13ac5`; 8 actual mounted/standalone images at 390 and 1440 in light and dark themes.
- After: `/private/tmp/scrypath-phase173-20261006-155750/evidence/173-02/after/phase173-time-captures/`, source `48fa8419ecd13d42fd8687e1000c9d09a76038b3`; 16 actual app screenshots across both entrypoints, four widths, and both themes. JUnit report, Compose log, and source SHA are beside the capture directory.
- Inspected baseline mounted desktop light/dark and standalone mobile light/dark. Inspected final mounted mobile light/dark, standalone desktop light/dark, and mounted 1279/1280 light. The exact timestamp remains readable below its age with no collision; mobile content wraps without page overflow; contrast check has no AA failures. Browser assertions exercised theme changes, refresh, click, Enter, and touch while confirming the age stayed tied to the fixture observation snapshot.

## Files Created/Modified

- `lib/scrypath/operator/state.ex` — stores validated source ISO provenance without changing the public struct.
- `scrypath_ops/lib/scrypath_ops/posture.ex` and `scrypath_ops/lib/scrypath_ops_web/live/posture_live.ex` — retain source-local observation references and pass them through refresh/render flows.
- `scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex` — shared relative-time and exact timestamp presentation with explicit unknown meanings.
- `scrypath_ops/assets/css/app.css` and `scrypath_ops/priv/static/assets/css/app.css` — responsive disclosure layout and built CSS.
- `test/scrypath/operator/status_test.exs`, `scrypath_ops/test/scrypath_ops_web/components/ops_ui_test.exs`, and `scrypath_ops/test/scrypath_ops_web/live/posture_live_test.exs` — source, component, and LiveView behavior coverage.
- `examples/scrypath_ecommerce/e2e/phase173_time.spec.ts`, `examples/scrypath_ecommerce/docker-playwright.sh`, and both app-local `phase173_fixture_source.ex` providers — deterministic two-entrypoint browser proof.
- `scrypath_ops/test/support/tap_formatter.ex` and `scrypath_ops/test/test_helper.exs` — machine-readable ExUnit TAP for validated RED evidence.

## Decisions Made

- Keep `source_iso` in the existing internal metadata map and only retain it if parsing yields the same instant as `at`; serialize DateTime-only inputs at their available precision.
- Keep each source's last successful observation separate from current check status so refresh failures cannot re-date prior evidence.
- Use a native disclosure control and wrap exact technical evidence rather than truncating or adding a dependency.

## Deviations from Plan

**[Rule 3 - Blocking] Added a local TAP formatter for canonical TDD RED evidence** — Found during: Task 1 | The ExUnit suite did not emit a supported complete TAP report required to prove that the planned assertion failed before implementation. | Added a small test-support formatter and configured it for the Ops test suite; no dependency added. The core formatting gate then required formatting that new helper, committed as `8f62c98`. | Files: `scrypath_ops/test/support/tap_formatter.ex`, `scrypath_ops/test/test_helper.exs` | Verification: T1/T2 TAP evidence was accepted as `RED_EVIDENCE_OK`; core format gate passed. | Commit: `8f62c98`.

**Total deviations:** 1 auto-fixed (Rule 3: required TDD evidence tooling). **Impact:** Test-only support enables real, machine-checked RED reports and adds no runtime dependency.

## Issues Encountered

- The first committed-source browser screenshots showed the expanded exact timestamp overlapping the relative age at desktop widths. The disclosure was moved to its own row when open; the final browser suite now asserts the exact timestamp box starts beneath the age, and final screenshots show no overlap.
- The standalone Ops asset build emits the concrete existing `Scrypath.Sync.sync_related/3` typing warning: in `lib/scrypath/sync/related_enqueue.ex`, the compile-time no-Oban fallback for `RelatedEnqueue.enqueue/4` always raises, so the `:oban` branch is inferred as `none()` at `decorate_result/2`. The required full-project warnings-as-errors core gate passes; this optional-dependency warning did not block it and was left unchanged.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

OPUX-14 source, display, threshold, unknown-state, refresh-retention, and responsive disclosure behavior is implemented and verified. Plan 04 can add the planned copy outcome feedback. All disposable browser resources were removed; the captured image/report evidence remains under `/private/tmp/scrypath-phase173-20261006-155750/evidence/173-02/` outside the worktree.

## Orchestrator Post-Merge Reconciliation

The GSD helper merged and removed the completed worktree. Its scope advisories cover the required test-only fixture providers, component tests, TAP helper, and RED artifacts. No core health classification or production authorization change was made.

Reconciliation caught gaps in the initial browser proof: standalone origin rejection left the LiveView disconnected, the retained-refresh browser assertion had been removed, routine Checked metadata gained a disclosure, and ages inherited dense monospace styling. Regression tests first failed on the disconnected standalone page and the unwanted Checked disclosure. Commits `7af89c4` and `236443e` add connected-state/failed-refresh checks, a test-only standalone URL hostname selected by the disposable Compose environment, a later failed-check fixture clock, plain Checked metadata, and 14px body-family ages with no duplicate Last success label.

Final `verify-phase173.sh time` passed on source `236443e2f67fc5a3f8487ec431557baa9520e2b3`: native JUnit records 2 tests, 0 failures, 0 errors, 0 skipped. Both real LiveViews connect; a failed source refresh advances Checked by a day while retaining the prior exact ISO and 2-day success age. Both themes and all four widths assert readable age typography and no unwanted Checked disclosure/copy. All 16 new captures, JUnit, Compose log, and source SHA are preserved at `/private/tmp/scrypath-phase173-20261006-155750/evidence/173-02/post-merge/`. Mounted mobile-dark and standalone desktop-light captures were inspected after resetting scroll: chrome is at the top, ages are readable, and open exact evidence stays below the age.

The post-merge full `mix verify.ops_ui` passed 2 doctests and 240 tests. Ops asset build and contrast passed, with 0 AA failures. The required core gate's recorded 659-test pass remains source-bounded to `48fa8419`; final phase closeout will check the later exact SHA. UI and schema safety gates return `block: false`; codebase drift skips because STRUCTURE.md is absent. Disposable containers/network/volume were removed. No final phase or hosted closeout is claimed here.

## Self-Check: PASSED

- All key files and committed TDD evidence records exist.
- All 9 task/follow-up commits are ancestors of `HEAD`; evaluation scope resolves to those 9 commits.
- Browser, contrast, focused timestamp, and required root core gates passed on the final committed source.
- Shared STATE.md, ROADMAP.md, state.json, and REQUIREMENTS.md were not changed.

---
*Phase: 173-shared-visual-foundation-and-operational-time*
*Completed: 2026-10-06*
