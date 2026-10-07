---
phase: "174"
slug: recovery-entry-and-diagnosis
status: validated
nyquist_compliant: true
wave_0_complete: true
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
| 174-01-T1 | OPUX-16–19 | T-174-01/02; selected A survives fleet ranking and existing retry gate | LiveView journey | `cd scrypath_ops && mix test test/scrypath_ops_web/live/recovery_journey_live_test.exs` | New test created in task | pass — journey4/4; Wave1 Ops251+2/0 |
| 174-01-T2 | OPUX-19 | T-174-01/02; invalid/removed query and old receipt cannot act | LiveView journey | `cd scrypath_ops && mix test test/scrypath_ops_web/live/recovery_journey_live_test.exs` | Test exists after T1 | pass — journey4/4; Wave1 Ops251+2/0 |
| 174-02-T1 | OPUX-19 | T-174-03; shell links derive only validated target | shell/LiveView | `cd scrypath_ops && mix test test/scrypath_ops_web/ops_shell_contract_test.exs test/scrypath_ops_web/live/control_room_live_test.exs` | yes; extend | pass — scoped54/0; Ops254+2/0 |
| 174-02-T2 | OPUX-19 | T-174-03; row change selects explicit row, return remains scoped | LiveView | `cd scrypath_ops && mix test test/scrypath_ops_web/ops_shell_contract_test.exs test/scrypath_ops_web/live/posture_live_test.exs test/scrypath_ops_web/live/failed_sync_live_test.exs test/scrypath_ops_web/live/sync_drift_live_test.exs` | yes; extend | pass — scoped54/0; Ops254+2/0 |
| 174-03-T1 | OPUX-19 | T-174-05; safe local sudo return includes only canonical schema | unit/LiveView | `cd scrypath_ops && mix test test/scrypath_ops/integrations/sigra/gating_test.exs test/scrypath_ops_web/live/failed_sync_live_test.exs` | yes; extend | pass — scoped39/0; Ops259+2/0; see03 history limit |
| 174-03-T2 | OPUX-18/19 | T-174-06; stale async/confirmation cannot cross target | LiveView | `cd scrypath_ops && mix test test/scrypath_ops_web/live/failed_sync_live_test.exs test/scrypath_ops_web/live/sync_drift_live_test.exs` | yes; extend | pass — scoped39/0; Ops259+2/0; see03 history limit |
| 174-04-T1 | OPUX-16 | T-174-07; observed fleet scope/zero claims remain bounded | LiveView | `cd scrypath_ops && mix test test/scrypath_ops_web/live/control_room_live_test.exs` | yes; extend | pass — ControlRoom11/0, health15/0, contrastAA0; expanded browser11/11 |
| 174-04-T2 | OPUX-17 | T-174-08; source states/row targets/focus identity | LiveView | `cd scrypath_ops && mix test test/scrypath_ops_web/live/posture_live_test.exs` | yes; extend | pass — ControlRoom11/0, health15/0, contrastAA0; expanded browser11/11 |
| 174-05-T1 | OPUX-18/19 | T-174-09; current source/schema/full ID controls action/receipt/modal | LiveView | `cd scrypath_ops && mix test test/scrypath_ops_web/live/failed_sync_live_test.exs` | yes; extend | pass — FailedSync26/0; final Ops275+2/0; native collision browser pass |
| 174-05-T2 | OPUX-18 | T-174-10/11; bounded reason and accepted≠terminal | LiveView | `cd scrypath_ops && mix test test/scrypath_ops_web/live/failed_sync_live_test.exs` | yes; extend | pass — FailedSync26/0; final Ops275+2/0; native diagnosis/receipt/long reason/delete scope pass |
| 174-06-T1 | OPUX-16–19 | T-174-12; fixture routes are test-only real LiveViews | LiveView | `cd scrypath_ops && mix test test/scrypath_ops_web/live/phase174_fixture_live_test.exs` | New route/test created in task | pass — focused route/fixture10/0; test-only real views; normal-route regression |
| 174-06-T2 | OPUX-18/19 | T-174-05/12; standalone real Gating interruption, deliberate return and source states | LiveView/integration | `cd scrypath_ops && mix test test/scrypath_ops_web/live/phase174_fixture_live_test.exs test/scrypath_ops/integrations/sigra/gating_test.exs` | Fixture test exists after T1 | pass — focused route/Gating10/0; real browser stale-sudo, scoped return, no replay |
| 174-07-T1 | OPUX-19 | T-174-04; manifest contains validated destinations | shell contract; later browser DOM | `cd scrypath_ops && mix test test/scrypath_ops_web/ops_shell_contract_test.exs` | yes; extend; actual DOM in 08-T2 | pass — shell12/0; actual dual-entrypoint palette manifest/current links pass |
| 174-07-T2 | OPUX-19 | T-174-04; ignored palette hrefs synchronize from patched manifest | Ops asset build; later browser DOM | `cd scrypath_ops && mix assets.build` | Existing asset task; actual DOM in 08-T2 | pass — native hook1/0 and build; actual LiveView patch/filter/clear/Escape/focus browser pass |
| 174-08-T1 | OPUX-16–19 | T-174-13; real mounted retry in isolated task-owned stack | Playwright | `bash examples/scrypath_ecommerce/scripts/verify-phase174.sh recovery` | Runner/spec created in task | pass — native expanded final browser11/11; 48 AFTER captures |
| 174-08-T2 | OPUX-16–19 | T-174-04/13; actual dual-entrypoint DOM, focus, responsive and cleanup | Playwright/Ops/contrast | `bash examples/scrypath_ecommerce/scripts/verify-phase174.sh recovery`; `cd scrypath_ops && mix precommit`; `mix verify.ops_ui`; `make -C examples/scrypath_ecommerce contrast` | Runner/spec from T1; expand cases | pass — native expanded browser11/11; Ops275+2/0; root Ops275+2/0; contrastAA0/AAA35; actual reorder focus pass |

## Wave 0 Requirements

- [x] 174-06-T1/T2 create Phase174-scoped standalone fixtures; 174-08-T1 creates the disposable browser runner and actual mounted journey before its verify command runs. Unique Compose names/ports; preserve retained preview :4012 and frozen173 source.
- [x] Add assertions for source ID collision, fleet target independence, actual palette DOM links after patches, safe auth returns, invalid/removed schemas, stale generations and focus after reordering.
- Existing ExUnit, Playwright and Docker infrastructure covers framework setup. No dependency install or new mandatory CI lane is proposed.

## Manual-Only Verifications

All required phase behaviors have automated verification. Before/after images and agent inspection supplement runnable assertions. Maintainer review of the working UI is feedback, not a pending completion gate or simulated approval.

## Validation Sign-Off

- [x] Each plan task has automated verification or explicit Wave0 dependencies.
- [x] No three consecutive tasks without verification.
- [x] Missing runner/test references are created before use.
- [x] Final production browser proof covers both entrypoints, themes, responsive states and selected-schema seams.
- [x] All 30 explicit UI criteria are mapped: E1/E2 (16) to 174-04-T1/T2 plus 174-08-T2; E3 (8) to 174-05-T1/T2 plus 174-08-T2; E4 (6) to 174-02-T1/T2, 174-03-T1/T2, 174-07-T1/T2 and 174-08-T2.
- [x] Record measured latency and results; set compliance only after evidence exists.

Verification: local executable evidence complete; independent phase verification and exact final-SHA hosted closeout remain pending. Maintainer review is feedback, not an acceptance gate.

## Nyquist follow-up — partial, implementation fixes pending

The expanded browser audit ran 11 cases at source `46d830a` plus test/fixture changes: 8 passed, 2 assertion failures and 1 timeout. Native JUnit contradicts the auditor's G6 pass summary: pending refresh timed out, while pending retry passed. Focused mounted/standalone palette filtering and clearing subsequently passed 2/2. G3 is a confirmed refresh focus defect; G5 fixture error markers were filtered away, and the remaining state assertions did not execute. No failed or unexecuted behavior is counted as passing or moved to human acceptance. Parent is fixing these within the already authorized scope.

The 48 BEFORE images use `54c623e`, immediately before the 44px action correction, not before all Phase174 work. Its scratch harness used the observed legacy 40px minimum only for that baseline. The 48 AFTER images use `46d830a` plus the audited test/fixture diff. Original missing pre-Phase174 baseline frames remain disclosed.

## Validation Audit 2026-10-07

| Metric | Count |
|---|---|
| Gaps found | 7 |
| Resolved | 4 |
| Escalated | 3 |

## Parent follow-up — all seven gaps automated and green

G3 is fixed by schema-keyed rendering and its real refresh/reorder focus test passes. G5 is corrected at the fixture boundary: error marker atoms survive delay-marker removal, completed queue observations carry a timestamp, and long reasons assert the existing500-character bound. Its retained, unavailable, unknown, no-success, empty-history, empty-allowlist and long-value/delete-modal sequence executes green. G6 refresh now waits for the actual joined LiveView and asserts label/icon/prior evidence while the real source provider delays its response; retry uses an actual held WebSocket response. The full suite passes11/11, zero skipped/errors/failures, with48AFTER images. All gaps remain automated; none is delegated to human UAT. Native XML and local source identities are preserved in174-FINAL-BROWSER.xml and174-FINAL-EVIDENCE.json. The separate final-source hosted gates remain required byCONTRIBUTING.

## Validation Audit 2026-10-07

| Metric | Count |
|---|---|
| Gaps found | 7 |
| Resolved | 7 |
| Escalated | 0 |

## Post-review executable refresh

Final production/fixture e286962 browser lane: native 11/11, zero failures/errors/skips, 48 fresh AFTER captures, 22.8s. Ops precommit: 275 tests + 2 doctests/0. Source collision verification now follows the rendered status handoff and real telemetry collector; connected allowlist removal checks all recovery shells and Control Room refresh. Native reports/logs retain earlier failed reruns separately. Phase173 browser regression and independent goal verification are recorded at their own boundaries before completion.

Prior-phase regression closure: 34 unique browser cases have passing evidence (32 unchanged full-run passes plus the exact 2 previously failing cases passing focused rerun). Native full and focused XML plus exact test identities are retained; no edited/fabricated native report or global advisory pass is claimed.
