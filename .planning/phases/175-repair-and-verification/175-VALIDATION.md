---
phase: "175"
slug: "repair-and-verification"
status: planned
nyquist_compliant: true
wave_0_complete: true
created: "2026-10-11"
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

Plans 175-01 through 175-03 assign six tasks across three sequential waves. The existing focused suites and disposable mounted lane exist before Wave 1; each task extends them and has immediate executable feedback. Mounted evidence is also required at the Wave 3 gate.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 175-01-01 | 175-01 | 1 | OPUX-20, OPUX-21 | T-175-01, T-175-02 | Exact receipt identity reaches independently rendered queue, contract and active-document results; absent expected identity is not checked. | LiveView tracer | `cd scrypath_ops && mix test test/scrypath_ops_web/live/sync_drift_live_test.exs` | Yes; extend existing suite | ⬜ pending |
| 175-01-02 | 175-01 | 1 | OPUX-20, OPUX-21 | T-175-02, T-175-03 | Common recovery handoff, lifecycle states, unknown observer failures, retained history, and refresh without mutation are rendered. | LiveView rendered/async | `cd scrypath_ops && mix test test/scrypath_ops_web/live/sync_drift_live_test.exs` | Yes; extend existing suite | ⬜ pending |
| 175-02-01 | 175-02 | 2 | OPUX-21, OPUX-22 | T-175-05 | Matching terminal swap plus fresh alias/contract and applicable expected-document evidence precedes completion; mismatches do not. | LiveView + document observer | `cd scrypath_ops && mix test test/scrypath_ops/document_observation_test.exs test/scrypath_ops_web/live/sync_drift_live_test.exs` | Yes; extend existing suites | ⬜ pending |
| 175-02-02 | 175-02 | 2 | OPUX-21, OPUX-22 | T-175-04, T-175-06 | Same-UID refresh is observational; current host/allowlist/eligibility/target and confirmation gate the sole mutation. | LiveView rendered/async | `cd scrypath_ops && mix test test/scrypath_ops_web/live/sync_drift_live_test.exs` | Yes; extend existing suite | ⬜ pending |
| 175-03-01 | 175-03 | 3 | OPUX-20, OPUX-21, OPUX-22 | T-175-07, T-175-08 | Disposable mounted control flow correlates selected schema, exact UID, alias and authoritative fixture document; unsupported fixture effects are recorded as source limits. | Mounted Playwright | `BUILDX_CONFIG=/private/tmp/scrypath-buildx make -C examples/scrypath_ecommerce verify-mounted` | Yes; extend existing suite/fixture | ⬜ pending |
| 175-03-02 | 175-03 | 3 | OPUX-20, OPUX-21, OPUX-22 | T-175-09 | Degraded and long-ID states stay readable, focusable and contrast-compliant across themes and widths; full Ops suite remains green. | Mounted layout + contrast + ExUnit | `cd scrypath_ops && mix assets.build`; `BUILDX_CONFIG=/private/tmp/scrypath-buildx make -C examples/scrypath_ecommerce verify-mounted`; `make -C examples/scrypath_ecommerce contrast`; `mix verify.ops_ui`; `cd scrypath_ops && mix precommit` | Yes; extend existing suites | ⬜ pending |

## Wave 0 Requirements

Existing ExUnit, LiveView, disposable browser, accessibility, and contrast infrastructure covers the phase, so Wave 0 requires no new scaffold. Extend current focused tests and mounted journeys for the named evidence and mismatch cases; do not add a dependency, framework, CI service, or production backend access.

## Manual-Only Verifications

All acceptance behaviors must have executable verification. Compare representative light/dark and desktop/narrow before/after captures as supporting visual evidence; screenshots or visual review do not replace assertions or become a pending human-acceptance gate.

## Validation Sign-Off

- [x] Every planned task has an executable `<automated>` verify using existing test infrastructure.
- [x] No three consecutive tasks lack automated feedback; all six have immediate commands.
- [x] Existing test and disposable mounted infrastructure is identified; no new infrastructure is required.
- [x] No watch-mode command is used.
- [x] Focused feedback remains bounded and mounted proof is scheduled at Wave 3.
- [x] `nyquist_compliant: true` set after exact plan/task/command mapping; execution results remain pending.

**Approval:** Plan validation map complete; execution evidence remains pending.
