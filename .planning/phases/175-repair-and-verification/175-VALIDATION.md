---
phase: "175"
slug: "repair-and-verification"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-10"
---

# Phase 175 — Validation Strategy

Planning contract; no Phase 175 execution results are asserted. The planner must replace the provisional requirement rows with the finalized per-task/wave/threat map before plan verification.

## Test Infrastructure

| Property | Value |
|----------|-------|
| Framework | Existing ExUnit, Phoenix.LiveViewTest, Playwright and token-contrast lanes |
| Config file | `scrypath_ops/test/test_helper.exs`; existing ecommerce Playwright configuration |
| Quick run command | From repo root: `cd scrypath_ops && mix test test/scrypath_ops_web/live/sync_drift_live_test.exs test/scrypath_ops/promotion_eligibility_test.exs test/scrypath_ops/recovery_observation_test.exs test/scrypath_ops/document_observation_test.exs` |
| Full suite command | Repo root: `mix verify.ops_ui`; owned mounted stack: `mix verify.ecommerce_mounted` |
| Estimated runtime | Measure during execution; focused feedback target under 120 seconds, full container/browser gates separately recorded |

Select the supported installed Elixir/OTP toolchain before commands; the current shell has no selected asdf version. Reuse CONTRIBUTING environment guidance and earlier proven commands. Do not start or seed retained previews on 4012/4014. Mutations, fixture seeding and prerequisite changes belong only in uniquely owned disposable stacks. Test commands must fail on a non-zero exit and on zero relevant test cases; every runnable PLAN command needs a following `<fails_when>`.

## Sampling Rate

- After every task commit: run the focused test lane relevant to that task, with rendered controls for changed interactions.
- After each wave: run `mix verify.ops_ui`; run root/core gates if implementation touches core source.
- Before phase closeout: run the owned standalone and mounted mutation/browser lanes, Ops precommit/canonical checks, affected token contrast, and applicable exact-source hosted CI required by CONTRIBUTING.
- No three consecutive tasks may lack automated verification. No watch mode or arbitrary sleeps.
- Full phase behaviors are executable; subjective comparison of approved before/after compositions is nonblocking and does not replace behavior/contrast/focus proof.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| Planner assigns | Planner assigns | Planner assigns | OPUX-20 | Planner assigns | Independent sync/config reads; visible validated selection; configuration match cannot claim freshness | LiveView/browser | `cd scrypath_ops && mix test test/scrypath_ops_web/live/sync_drift_live_test.exs` | Yes, extend cases | Pending |
| Planner assigns | Planner assigns | Planner assigns | OPUX-21 | Planner assigns | Exact job/attempt/task/document evidence; unknown remains unknown; busy observer differs from processing | LiveView/unit | Quick run command above | Yes, extend cases | Pending |
| Planner assigns | Planner assigns | Planner assigns | OPUX-22 | Planner assigns | Current host gate/allowlist/prerequisites and rendered confirmation; readonly timeout recheck cannot submit another swap | LiveView/mounted browser | `mix verify.ops_ui`; owned `mix verify.ecommerce_mounted` | Lanes exist; Phase 175 cases needed | Pending |

## Wave 0 Requirements

- [ ] Add exact-task observation cases using actual configured client map/struct normalization: enqueued is accepted; processing is running; succeeded/failed/cancelled require matching UID; malformed/read-error/timeout/missing UID remain unconfirmed.
- [ ] Add readonly status-check event assertions showing GET of the retained UID and zero additional swap POSTs after timeout or refresh.
- [ ] Add current-context tests for success/error callbacks after schema/allowlist/generation/backend endpoint or runtime identity changes; preserve failure-history eligibility policy.
- [ ] Add rendered form, modal, cancel, auth-return, duplicate/in-flight and immediately changed prerequisite assertions.
- [ ] Cover exact recovery attempt/task plus active-index upsert projection and delete absence; include expired/superseded/wrong-runtime receipts and wrong/historical evidence.
- [ ] Reuse existing disclosure/focus behavior; verify manual expansion across patches and status/UID discoverability outside collapsed advanced controls.
- [ ] Add source-owned Phase 175 standalone and mounted disposable fixture/browser lanes with ownership checks, deterministic bounded state transitions and cleanup limited to owned resources.
- [ ] Record affected before/after light/dark compositions at 390/768/1440, System/reduced-motion/keyboard/focus/overflow and existing contrast checks.

Existing infrastructure is retained; no new framework, dependency, required hosted job, paid visual judge, or manual UAT gate is authorized. Prior 57-case UX evidence has its original source/scenario limits and does not close Phase 175 semantics.

## Manual-Only Verifications

None required for phase completion. All required behavior, current-context safety, task/document correlation, focus/disclosure, layout bounds and contrast receive automated proof. Before/after design inspection uses the approved UI contract and remains nonblocking.

## Validation Sign-Off

- [ ] Finalized tasks have an automated verify or explicit Wave 0 dependency.
- [ ] Sampling continuity: no three consecutive tasks without automated verify.
- [ ] Wave 0 covers all missing references and both deployment forms.
- [ ] No watch-mode flags; failure signals are stated.
- [ ] Feedback latency is measured during execution; focused target under 120 seconds.
- [ ] Execution evidence supports `nyquist_compliant: true` and `wave_0_complete: true` before those fields change.

**Approval:** Pending plan verification and execution evidence; no user or runtime approval simulated.
