---
phase: "175"
slug: "repair-and-verification"
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-10-11"
validated: "2026-10-11"
---

# Phase 175 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit with Phoenix.LiveViewTest; existing mounted browser lane uses Playwright. |
| **Config file** | `scrypath_ops/mix.exs` aliases; `examples/scrypath_ecommerce/Makefile` and existing disposable E2E setup. |
| **Quick run command** | `cd scrypath_ops && mix test test/scrypath_ops_web/live/sync_drift_live_test.exs` |
| **Full suite command** | `mix verify.ops_ui` from the repository root; mounted mutation proof via the existing disposable operator E2E lane. |
| **Estimated runtime** | Budget up to 60 seconds for the focused ExUnit loop; mounted disposable proof may take several minutes. |

## Sampling Rate

- **After every task commit:** Run the focused LiveView test for the changed behavior and any directly affected component/accessibility test.
- **After every plan wave:** Run `mix verify.ops_ui`; run the existing disposable mounted lane for changes to mutation, navigation, async results, responsive behavior, or focus.
- **Before `$gsd-verify-work`:** Focused tests, the full Ops UI suite, and mounted proof for the changed repair/promotion journeys must pass.
- **Max feedback latency:** 60 seconds for focused ExUnit feedback; mounted proof stays at wave level.

## Requirement-Level Validation Map

Plans 175-01 through 175-04 assign nine tasks across four waves. The existing focused suites and disposable mounted lane exist before Wave 1; each task extends them and has immediate executable feedback. Mounted evidence is required at the Wave 3 gate.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 175-01-01 | 175-01 | 1 | OPUX-20, OPUX-21 | T-175-01, T-175-02 | Exact receipt identity reaches independently rendered queue, contract and active-document results; absent expected identity is not checked. | LiveView tracer | `cd scrypath_ops && mix test test/scrypath_ops_web/live/sync_drift_live_test.exs` | Yes; extend existing suite | ✓ pass — focused suite, `mix verify.ops_ui`, and `mix precommit` |
| 175-01-02 | 175-01 | 1 | OPUX-20, OPUX-21 | T-175-02, T-175-03 | Common recovery handoff, lifecycle states, unknown observer failures, retained history, and refresh without mutation are rendered. | LiveView rendered/async | `cd scrypath_ops && mix test test/scrypath_ops_web/live/sync_drift_live_test.exs` | Yes; extend existing suite | ✓ pass — focused suite, `mix verify.ops_ui`, and `mix precommit` |
| 175-02-01 | 175-02 | 2 | OPUX-21, OPUX-22 | T-175-05 | Matching terminal swap plus fresh alias/contract and applicable expected-document evidence precedes completion; mismatches do not. | LiveView + document observer | `cd scrypath_ops && mix test test/scrypath_ops/document_observation_test.exs test/scrypath_ops_web/live/sync_drift_live_test.exs` | Yes; extend existing suites | ✓ pass — focused suites, `mix verify.ops_ui`, `mix precommit`, and mounted proof |
| 175-02-02 | 175-02 | 2 | OPUX-21, OPUX-22 | T-175-04, T-175-06 | Same-UID refresh is observational; current host/allowlist/eligibility/target and confirmation gate the sole mutation. | LiveView rendered/async | `cd scrypath_ops && mix test test/scrypath_ops_web/live/sync_drift_live_test.exs` | Yes; extend existing suite | ✓ pass — focused suite, `mix verify.ops_ui`, and `mix precommit` |
| 175-03-01 | 175-03 | 3 | OPUX-20, OPUX-21, OPUX-22 | T-175-07, T-175-08 | Disposable mounted control flow correlates selected schema, exact UID, alias and authoritative fixture document; unsupported fixture effects are recorded as source limits. | Mounted Playwright | `BUILDX_CONFIG=/private/tmp/scrypath-buildx make -C examples/scrypath_ecommerce verify-mounted` | Yes; extend existing suite/fixture | ✓ pass — 4/4 focused mounted browser checks on the final source |
| 175-03-02 | 175-03 | 3 | OPUX-20, OPUX-21, OPUX-22 | T-175-09 | Degraded and long-ID states stay readable, focusable and contrast-compliant across themes and widths; full Ops suite remains green. | Mounted layout + contrast + ExUnit | `cd scrypath_ops && mix assets.build`; `BUILDX_CONFIG=/private/tmp/scrypath-buildx make -C examples/scrypath_ecommerce verify-mounted`; `make -C examples/scrypath_ecommerce contrast`; `mix verify.ops_ui`; `cd scrypath_ops && mix precommit`; containerized `admin-shell` representative-layout Playwright test | Yes; extend existing suites | ✓ pass — 0 AA failures; mounted browser checks 4/4; shell geometry across six surfaces and five widths passed; 261 tests + 2 doctests in precommit and root UI gate |
| 175-03-03 | 175-03 | 3 | OPUX-22 | T-175-08, T-175-09 | Cancel returns focus to the stable visible promotion disclosure; keyboard continuation retains the selected identity through task, alias, document, and refresh checks. | Mounted Playwright | `BUILDX_CONFIG=/private/tmp/scrypath-buildx make -C examples/scrypath_ecommerce verify-mounted` | Yes; extend existing operator journey | ✓ pass — final disposable mounted lane passed 4/4, including focus return and keyboard continuation |
| 175-04-01 | 175-04 | 4 | OPUX-21, OPUX-22 | T-175-10, T-175-11 | A matching receipt plus applicable expected effect that mismatches in the active index leaves promotion unconfirmed, retaining task/receipt identity and the observer reason. | Focused LiveView | `cd scrypath_ops && ASDF_ELIXIR_VERSION=1.19.0-otp-28 ASDF_ERLANG_VERSION=28.1 mix test test/scrypath_ops_web/live/sync_drift_live_test.exs:769` | Yes; existing suite extended | ✓ pass — correlated mismatch test passed; included in the 4/4 targeted gap-closure run |
| 175-04-02 | 175-04 | 4 | OPUX-21, OPUX-22 | T-175-10, T-175-11 | Unavailable expected-effect sources and active-index reads remain unconfirmed; no applicable effect stays explicitly not checked; pending refresh hides prior document evidence, and task-read failure clears stale verified evidence with a task-specific reason and same-task next step. | Focused LiveView | `cd scrypath_ops && ASDF_ELIXIR_VERSION=1.19.0-otp-28 ASDF_ERLANG_VERSION=28.1 mix test test/scrypath_ops_web/live/sync_drift_live_test.exs:816 test/scrypath_ops_web/live/sync_drift_live_test.exs:849 test/scrypath_ops_web/live/sync_drift_live_test.exs:911 test/scrypath_ops_web/live/sync_drift_live_test.exs:987` | Yes; existing suite extended | ✓ pass — source/read/control and stale-refresh regressions pass; task calls `[991, 991]`, swap calls `0` |

## Wave 0 Requirements

Existing ExUnit, LiveView, disposable browser, accessibility, and contrast infrastructure covers the phase, so Wave 0 requires no new scaffold. Extend current focused tests and mounted journeys for the named evidence and mismatch cases; do not add a dependency, framework, CI service, or production backend access.

## Manual-Only Verifications

All acceptance behaviors must have executable verification. Compare representative light/dark and desktop/narrow before/after captures as supporting visual evidence; screenshots or visual review do not replace assertions or become a pending human-acceptance gate.

## Validation Sign-Off

- [x] Every planned task has an executable `<automated>` verify using existing test infrastructure.
- [x] No three consecutive tasks lack automated feedback; all nine have immediate commands.
- [x] Existing test and disposable mounted infrastructure is identified; no new infrastructure is required.
- [x] No watch-mode command is used.
- [x] Focused feedback remains bounded and mounted proof is scheduled at Wave 3.
- [x] `nyquist_compliant: true` and `status: validated` after all nine task rows passed on the final source.
- [x] Exact-UID regression and async generation/task result checks were added after code review and passed focused, full Ops, and mounted verification.

**Approval:** All nine planned tasks have executable verification; no coverage gaps remain open or were escalated.

## Validation Audit 2026-10-11

| Metric | Count |
|---|---|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

## Final Plan Reconciliation and Gap-Closure Audit 2026-10-11

The original task map omitted `175-03-03`, although Plan 03 has three tasks. The row is now included, and the map accounts for every task in Plans 01–04: nine tasks across four waves. Plan 04's four original behavioral probes cover a correlated active-index mismatch, an unavailable expected-effect source, an unavailable active-index document read with same-task refresh, and a no-applicable-effect control. The mismatch test retains exact task and receipt identity and exposes the mismatch reason; the unavailable-read case retains schema/live/target identity, distinguishes a succeeded swap from failed observation, and proves the same UID is read twice with zero new swaps; the control keeps the explicit not-checked claim.

| Gate | Result |
|------|--------|
| Focused LiveView and document-observation suite | 44 passed, 0 failures (phase executor rerun) |
| `mix precommit` after gap closure | Passed, 266 tests + 2 doctests (phase execution gate) |
| `mix verify.ops_ui` after gap closure | Passed, 266 tests + 2 doctests (phase execution gate) |
| Disposable mounted lane on exact final source `fdaf9b8` | Passed, 4/4 |

Post-review regression `promotion task refresh failure clears the previous document observation` (LiveView test line 987) first proves that a pending refresh renders “Checking the retained swap task and current index evidence.” while hiding the prior verified-document detail and success-shaped copy. It then drives a task-read exit and asserts the result becomes unknown, loading ends, the previous verified observation and stale observer error are cleared, and no document effect is presented. The first failure is recorded in `175-04-03-stale-refresh-red.json`; the follow-up failure that required a precise task-read reason and next step is recorded in `175-04-04-task-read-copy-red.json`. On the final source the UI says “The retained task result could not be confirmed (task_observation_exit).” and “Refresh to inspect this same task; do not submit another operation.” The isolated regression passed (1/1), and the complete focused suite passed 44/44.

The validation auditor's first full focused run at 44 tests hit one intermittent existing ExUnit `on_exit` teardown error (`GenServer.stop/3`, process already stopped) in `post-promotion evidence applies only for the current generation and task`; the phase executor's subsequent complete focused rerun passed 44/44. The executor's final bounded cross-phase Ops gate and root `mix verify.ops_ui` each passed with 266 tests + 2 doctests. The exact-source disposable mounted lane passed 4/4 on `fdaf9b8`, completing the previously pending verification.

## UI Audit Follow-up Verification 2026-10-11

The UI audit findings that contradicted the approved Phase 175 contract were corrected and covered with regression assertions. The shared compact spacing called out by the first audit is an explicit UI-SPEC exception for existing OpsUi component patterns and was retained.

| Gate | Result |
|------|--------|
| Focused LiveView + document-observation tests | 39 passed, 0 failures |
| `mix assets.build` | Passed; tracked CSS rebuilt |
| `mix precommit` | 261 tests + 2 doctests passed |
| `mix verify.ops_ui` | 261 tests + 2 doctests passed |
| `make -C examples/scrypath_ecommerce contrast` | Passed; 0 AA failures |
| Disposable mounted operator lane | 4/4 Playwright tests passed; owned resources removed |

The first post-follow-up full `mix precommit` run had one teardown race in `SyncDriftLiveTest` after an already-exited test process. The isolated case passed, and the subsequent complete gate passed. No product verification or external service was used; the retained :4012 preview was untouched.

## Primary-Anchor Follow-up

The 6-pillar re-audit found one contract-specific hierarchy gap: the first section was ordered correctly but shared the same heading size as later evidence. The existing page-heading size is now applied to that semantic `h2`, and the focused regression verifies that the other evidence headings keep the section-heading size. On the final source, formatting, the focused LiveView file (24/24), `mix assets.build`, `mix precommit` (261 tests + 2 doctests), `mix verify.ops_ui` (261 tests + 2 doctests), the contrast gate (zero AA failures), and disposable mounted browser proof (4/4) all passed.

## Responsive Header Follow-up

Final rendered inspection exposed header content clipping at 320px and 390px despite no document-level horizontal overflow. The shared shell now compacts theme labels through 420px and renders the command action as an icon below 360px. Playwright checks the compact states and intrinsic content fit, then verifies all six operator surfaces at 320px, 390px, 1279px, 1280px, and 1440px. The containerized `admin-shell` representative-layout test passed across all surfaces and widths; existing 390px captures and contrast checks also passed. Theme and command accessible names remain available, and control targets remain at least 44px.
