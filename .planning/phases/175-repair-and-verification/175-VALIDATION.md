---
phase: "175"
slug: "repair-and-verification"
status: draft
nyquist_compliant: false
wave_0_complete: false
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

The plan has not assigned task IDs or waves yet. The planner must split these scenarios into concrete task rows and identify any new executable cases before plans are finalized.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| Planner assigns | TBD | TBD | OPUX-20 | Planner assigns | Queue/backend, contract, and active-document results remain separate; missing expected identity is unavailable rather than guessed; ordinary repair and advanced promotion have distinct paths. | LiveView + mounted | `cd scrypath_ops && mix test test/scrypath_ops_web/live/sync_drift_live_test.exs`; existing disposable operator lane | Yes; extend existing suites | ⬜ pending |
| Planner assigns | TBD | TBD | OPUX-21 | Planner assigns | Accepted, running, terminal, and unknown are distinct; exact task/job identity is retained; refresh re-observes and never resubmits; observer failure cannot become remote failure or success. | LiveView + mounted | Focused Sync and drift suite; existing disposable operator lane where rendered lifecycle behavior changes | Yes; extend existing suites | ⬜ pending |
| Planner assigns | TBD | TBD | OPUX-22 | Planner assigns | Current host authorization, eligibility, selected schema/index, and confirmation are rechecked before mutation; promotion is complete only after matching task and fresh active-index/document evidence. | LiveView + disposable mounted | Focused Sync and drift suite; existing disposable operator lane | Yes; extend existing suites; verify fixture evidence before relying on it | ⬜ pending |

## Wave 0 Requirements

Existing ExUnit, LiveView, disposable browser, accessibility, and contrast infrastructure covers the phase. Extend current focused tests and mounted journeys for the named evidence and mismatch cases; do not add a dependency, framework, CI service, or production backend access.

## Manual-Only Verifications

All acceptance behaviors must have executable verification. Compare representative light/dark and desktop/narrow before/after captures as supporting visual evidence; screenshots or visual review do not replace assertions or become a pending human-acceptance gate.

## Validation Sign-Off

- [ ] Every planned task has an executable `<automated>` verify or an earlier Wave 0 task creates it.
- [ ] No three consecutive tasks lack automated feedback.
- [x] Existing test and disposable mounted infrastructure is identified; no new infrastructure is required.
- [ ] No watch-mode command is used.
- [ ] Focused feedback remains bounded and mounted proof is scheduled at wave level.
- [ ] `nyquist_compliant: true` set in frontmatter after plan mapping and evidence.

**Approval:** pending plan/task mapping and execution evidence.
