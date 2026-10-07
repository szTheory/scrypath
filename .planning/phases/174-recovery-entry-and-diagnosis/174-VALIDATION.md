---
phase: "174"
slug: recovery-entry-and-diagnosis
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-06"
---

# Phase 174 — Validation Strategy

## Test Infrastructure

| Property | Value |
|---|---|
| Framework | ExUnit, Phoenix.LiveViewTest, existing Playwright Docker lane |
| Config | scrypath_ops/test/test_helper.exs; examples/scrypath_ecommerce/package.json |
| Quick run | `cd scrypath_ops && mix test test/scrypath_ops_web/live/failed_sync_live_test.exs test/scrypath_ops_web/live/posture_live_test.exs` |
| Full Ops suite | `cd scrypath_ops && mix precommit` |
| Phase gate | Focused Ops suites, `mix verify.ops_ui`, token contrast and scoped Phase174 browser proof in standalone and mounted entrypoints |
| Runtime | Record observed durations during execution; research does not supply measured latency |

## Sampling Rate

After each task, run the smallest affected ExUnit suite; after each plan wave, run Ops precommit. Verify the first real selected-schema journey before expanding it. Browser-only behavior uses the scoped disposable runner after its Wave0 creation. No watch mode. Tests must report executed cases and zero failures; a nonzero exit, missing cases or missing native result is not a pass. Run browser proof and contrast against the final changed source before phase verification.

## Per-Task Verification Map

Task IDs below map the implementation slices to runnable commands and phase-unique threat references. Commands for the new Phase174 browser runner are used only after 174-08-T1 creates that script, Compose override and Playwright spec. A passing unit command is not a substitute for the final rendered browser gate.

| Task ID | Requirement | Threat ref and secure behavior | Test type | Automated command | Exists | Status |
|---|---|---|---|---|---|---|
| 174-01-T1 | OPUX-16–19 | T-174-01/02; selected A survives fleet ranking and existing retry gate | LiveView journey | `cd scrypath_ops && mix test test/scrypath_ops_web/live/recovery_journey_live_test.exs` | New test created in task | pending |
| 174-01-T2 | OPUX-19 | T-174-01/02; invalid/removed query and old receipt cannot act | LiveView journey | `cd scrypath_ops && mix test test/scrypath_ops_web/live/recovery_journey_live_test.exs` | Test exists after T1 | pending |
| 174-02-T1 | OPUX-19 | T-174-03; shell links derive only validated target | shell/LiveView | `cd scrypath_ops && mix test test/scrypath_ops_web/ops_shell_contract_test.exs test/scrypath_ops_web/live/control_room_live_test.exs` | yes; extend | pending |
| 174-02-T2 | OPUX-19 | T-174-03; row change selects explicit row, return remains scoped | LiveView | `cd scrypath_ops && mix test test/scrypath_ops_web/ops_shell_contract_test.exs test/scrypath_ops_web/live/posture_live_test.exs test/scrypath_ops_web/live/failed_sync_live_test.exs test/scrypath_ops_web/live/sync_drift_live_test.exs` | yes; extend | pending |
| 174-03-T1 | OPUX-19 | T-174-05; safe local sudo return includes only canonical schema | unit/LiveView | `cd scrypath_ops && mix test test/scrypath_ops/integrations/sigra/gating_test.exs test/scrypath_ops_web/live/failed_sync_live_test.exs` | yes; extend | pending |
| 174-03-T2 | OPUX-18/19 | T-174-06; stale async/confirmation cannot cross target | LiveView | `cd scrypath_ops && mix test test/scrypath_ops_web/live/failed_sync_live_test.exs test/scrypath_ops_web/live/sync_drift_live_test.exs` | yes; extend | pending |
| 174-04-T1 | OPUX-16 | T-174-07; observed fleet scope/zero claims remain bounded | LiveView | `cd scrypath_ops && mix test test/scrypath_ops_web/live/control_room_live_test.exs` | yes; extend | pending |
| 174-04-T2 | OPUX-17 | T-174-08; source states/row targets/focus identity | LiveView | `cd scrypath_ops && mix test test/scrypath_ops_web/live/posture_live_test.exs` | yes; extend | pending |
| 174-05-T1 | OPUX-18/19 | T-174-09; current source/schema/full ID controls action/receipt/modal | LiveView | `cd scrypath_ops && mix test test/scrypath_ops_web/live/failed_sync_live_test.exs` | yes; extend | pending |
| 174-05-T2 | OPUX-18 | T-174-10/11; bounded reason and accepted≠terminal | LiveView | `cd scrypath_ops && mix test test/scrypath_ops_web/live/failed_sync_live_test.exs` | yes; extend | pending |
| 174-06-T1 | OPUX-16–19 | T-174-12; fixture routes are test-only real LiveViews | LiveView | `cd scrypath_ops && mix test test/scrypath_ops_web/live/phase174_fixture_live_test.exs` | New route/test created in task | pending |
| 174-06-T2 | OPUX-18/19 | T-174-05/12; standalone real Gating interruption, deliberate return and source states | LiveView/integration | `cd scrypath_ops && mix test test/scrypath_ops_web/live/phase174_fixture_live_test.exs test/scrypath_ops/integrations/sigra/gating_test.exs` | Fixture test exists after T1 | pending |
| 174-07-T1 | OPUX-19 | T-174-04; manifest contains validated destinations | shell contract; later browser DOM | `cd scrypath_ops && mix test test/scrypath_ops_web/ops_shell_contract_test.exs` | yes; extend; actual DOM in 08-T2 | pending |
| 174-07-T2 | OPUX-19 | T-174-04; ignored palette hrefs synchronize from patched manifest | Ops asset build; later browser DOM | `cd scrypath_ops && mix assets.build` | Existing asset task; actual DOM in 08-T2 | pending |
| 174-08-T1 | OPUX-16–19 | T-174-13; real mounted retry in isolated task-owned stack | Playwright | `bash examples/scrypath_ecommerce/scripts/verify-phase174.sh recovery` | Runner/spec created in task | pending |
| 174-08-T2 | OPUX-16–19 | T-174-04/13; actual dual-entrypoint DOM, focus, responsive and cleanup | Playwright/Ops/contrast | `bash examples/scrypath_ecommerce/scripts/verify-phase174.sh recovery`; `cd scrypath_ops && mix precommit`; `mix verify.ops_ui`; `make -C examples/scrypath_ecommerce contrast` | Runner/spec from T1; expand cases | pending |

## Wave 0 Requirements

- [ ] 174-06-T1/T2 create Phase174-scoped standalone fixtures; 174-08-T1 creates the disposable browser runner and actual mounted journey before its verify command runs. Unique Compose names/ports; preserve retained preview :4012 and frozen173 source.
- [ ] Add assertions for source ID collision, fleet target independence, actual palette DOM links after patches, safe auth returns, invalid/removed schemas, stale generations and focus after reordering.
- Existing ExUnit, Playwright and Docker infrastructure covers framework setup. No dependency install or new mandatory CI lane is proposed.

## Manual-Only Verifications

All required phase behaviors have automated verification. Before/after images and agent inspection supplement runnable assertions. Maintainer review of the working UI is feedback, not a pending completion gate or simulated approval.

## Validation Sign-Off

- [ ] Each plan task has automated verification or explicit Wave0 dependencies.
- [ ] No three consecutive tasks without verification.
- [ ] Missing runner/test references are created before use.
- [ ] Final production browser proof covers both entrypoints, themes, responsive states and selected-schema seams.
- [ ] All 30 explicit UI criteria are mapped: E1/E2 (16) to 174-04-T1/T2 plus 174-08-T2; E3 (8) to 174-05-T1/T2 plus 174-08-T2; E4 (6) to 174-02-T1/T2, 174-03-T1/T2, 174-07-T1/T2 and 174-08-T2.
- [ ] Record measured latency and results; set compliance only after evidence exists.

Approval: pending execution evidence.
