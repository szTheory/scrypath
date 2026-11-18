---
phase: "185"
slug: "executable-ui-quality-foundations"
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-10-30"
updated: "2026-11-01"
---

# Phase 185 — Validation Strategy

Implementation coverage audit is complete for all22 tasks. Current candidate [41318243156](https://github.com/szTheory/scrypath/actions/runs/41318243156) at `fa42d99ee3ad5290ea7d8ab089ba076c5e25558c` passed all five required jobs, coverage and exact-source immutable attestation, and its full advisory browser lane succeeded after the diagnosed transport, frame-safe accessibility, runtime-handoff, serial full-suite and cold-start repairs. Original local full/pair/global receipts retain their source identities. Final tracked-source terminal attestation remains mandatory and is not certified by this pre-dispatch record.

## Test Infrastructure

| Property | Value |
|----------|-------|
| Framework | Existing root ExUnit, Node built-in tests, Phoenix ConnCase and Docker Playwright |
| Configuration | `mix.exs`, `dev/mix/tasks/verify.phase99.ex`, existing demo browser configuration |
| Quick required command | `mix verify.repository_contracts` |
| Core regression command | `mix test --exclude integration --exclude docs_contract` |
| Built mounted proof | `mix verify.ecommerce_mounted` |
| Full browser proof | `mix verify.ecommerce_e2e` |
| Feedback target | Focused pure scanner/token/contrast tests within 60 seconds; required command target 120 seconds; measure during execution |

Select the installed supported Elixir/OTP toolchain explicitly before local Mix commands. No package or version addition, new framework, or browser download is planned. The approved CI repair installs the already-locked demo test dependencies with `npm ci --ignore-scripts`; it does not add a required job. Preserve the five required CI jobs and advisory/path-scoped lanes.

## Sampling Rate

- Every task: focused automated tests including negative fixtures for the changed behavior.
- Every wave: canonical `mix verify.repository_contracts`; run built/browser checks when their inputs change.
- Before phase completion: CONTRIBUTING changed-scope verification and exact-source terminal closeout after tracked writes, with receipt outside frozen source.
- Long Docker/browser checks do not replace fast pure checks. No watch commands.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirements | Threat Ref | Exact test paths / evidence | Automated verification | Status |
|---|---|---|---|---|---|---|---|
| 185-01-01 | 01 | 1 | UIF-04 | T-185-01 | test/mix/tasks/ui_contrast_contract_test.exs<br>test/mix/tasks/verify.phase99_test.exs | Owning task verify XML; all commands and immediate fails_when are canonical there | Verified implementation candidate from current hosted/local source-bound evidence; original per-task commands and source identities retained. |
| 185-01-02 | 01 | 1 | UIF-04 | T-185-01 | test/mix/tasks/ui_contrast_contract_test.exs | Owning task verify XML; all commands and immediate fails_when are canonical there | Verified implementation candidate from current hosted/local source-bound evidence; original per-task commands and source identities retained. |
| 185-02-01 | 02 | 2 | UIF-01 | T-185-03 | scripts/ci/ui_literal_policy.test.cjs<br>test/mix/tasks/ui_literal_contract_test.exs | Owning task verify XML; all commands and immediate fails_when are canonical there | Verified implementation candidate from current hosted/local source-bound evidence; original per-task commands and source identities retained. |
| 185-02-02 | 02 | 2 | UIF-01 | T-185-03 | scripts/ci/ui_literal_policy.test.cjs<br>test/mix/tasks/ui_literal_contract_test.exs | Owning task verify XML; all commands and immediate fails_when are canonical there | Verified implementation candidate from current hosted/local source-bound evidence; original per-task commands and source identities retained. |
| 185-03-01 | 03 | 3 | UIF-05 | T-185-06 | test/mix/tasks/ui_tokens_contract_test.exs | Owning task verify XML; all commands and immediate fails_when are canonical there | Verified implementation candidate from current hosted/local source-bound evidence; original per-task commands and source identities retained. |
| 185-03-02 | 03 | 3 | UIF-05 | T-185-06 | test/mix/tasks/ui_tokens_contract_test.exs | Owning task verify XML; all commands and immediate fails_when are canonical there | Verified implementation candidate from current hosted/local source-bound evidence; original per-task commands and source identities retained. |
| 185-04-01 | 04 | 2 | UIF-06 | T-185-08 | test/mix/tasks/workflow_wiring_test.exs | Owning task verify XML; all commands and immediate fails_when are canonical there | Verified implementation candidate from current hosted/local source-bound evidence; original per-task commands and source identities retained. |
| 185-04-02 | 04 | 2 | UIF-06 | T-185-08 | scripts/ci/ecommerce_evidence.test.cjs<br>scripts/ci/ecommerce_target.test.cjs<br>test/mix/tasks/workflow_wiring_test.exs | Owning task verify XML; all commands and immediate fails_when are canonical there | Verified implementation candidate from current hosted/local source-bound evidence; original per-task commands and source identities retained. |
| 185-04-03 | 04 | 2 | UIF-06 | T-185-08 | test/mix/tasks/workflow_wiring_test.exs | Owning task verify XML; all commands and immediate fails_when are canonical there | Verified implementation candidate from current hosted/local source-bound evidence; original per-task commands and source identities retained. |
| 185-05-01 | 05 | 3 | UIF-02, UIF-03 | T-185-10 | scripts/ci/ui_preservation.test.cjs<br>examples/scrypath_ecommerce/e2e/ui-review.selftest.mjs | Owning task verify XML; all commands and immediate fails_when are canonical there | Verified implementation candidate from current hosted/local source-bound evidence; original per-task commands and source identities retained. |
| 185-05-02 | 05 | 3 | UIF-02, UIF-03 | T-185-10 | scripts/ci/ui_preservation.test.cjs | Owning task verify XML; all commands and immediate fails_when are canonical there | Verified implementation candidate from current hosted/local source-bound evidence; original per-task commands and source identities retained. |
| 185-06-01 | 06 | 4 | UIF-02 | T-185-13 | scripts/ci/ui_bundle_contract.test.cjs | Owning task verify XML; all commands and immediate fails_when are canonical there | Verified implementation candidate from current hosted/local source-bound evidence; original per-task commands and source identities retained. |
| 185-06-02 | 06 | 4 | UIF-02 | T-185-13 | scripts/ci/ui_bundle_contract.test.cjs | Owning task verify XML; all commands and immediate fails_when are canonical there | Verified implementation candidate from current hosted/local source-bound evidence; original per-task commands and source identities retained. |
| 185-07-01 | 07 | 4 | UIF-03, UIF-01 | T-185-15 | scrypath_ops/test/scrypath_ops_web/controllers/page_controller_test.exs | Owning task verify XML; all commands and immediate fails_when are canonical there | Verified implementation candidate from current hosted/local source-bound evidence; original per-task commands and source identities retained. |
| 185-07-02 | 07 | 4 | UIF-03, UIF-01 | T-185-15 | examples/scrypath_ecommerce/e2e/ui_routes_preservation.spec.ts | Owning task verify XML; all commands and immediate fails_when are canonical there | Verified implementation candidate from current hosted/local source-bound evidence; original per-task commands and source identities retained. |
| 185-08-01 | 08 | 4 | UIF-02, UIF-03 | T-185-17 | examples/scrypath_ecommerce/e2e/ui_state_preservation.spec.ts<br>examples/scrypath_ecommerce/test/support/phase173_fixture_source.ex<br>scrypath_ops/test/support/phase173_fixture_source.ex | Owning task verify XML; all commands and immediate fails_when are canonical there | Verified implementation candidate from current hosted/local source-bound evidence; original per-task commands and source identities retained. |
| 185-08-02 | 08 | 4 | UIF-02, UIF-03 | T-185-17 | examples/scrypath_ecommerce/e2e/ui_content_preservation.spec.ts | Owning task verify XML; all commands and immediate fails_when are canonical there | Verified implementation candidate from current hosted/local source-bound evidence; original per-task commands and source identities retained. |
| 185-08-03 | 08 | 4 | UIF-02, UIF-03 | T-185-17 | scripts/ci/ui_state_pairs.cjs<br>Canonical before/candidate receipts and independent pair authority | Owning task verify XML; exact source-paired raw state/image comparison | Verified implementation candidate from current hosted/local source-bound evidence; original per-task commands and source identities retained. |
| 185-09-01 | 09 | 5 | UIF-02, UIF-03, UIF-06 | T-185-19 | Actual source-bound runtime receipts; no new test file | Owning task verify XML; all commands and immediate fails_when are canonical there | Verified implementation candidate from current hosted/local source-bound evidence; original per-task commands and source identities retained. |
| 185-09-02 | 09 | 5 | UIF-02, UIF-03, UIF-06 | T-185-19 | Actual source-bound runtime receipts; no new test file | Owning task verify XML; all commands and immediate fails_when are canonical there | Verified implementation candidate from current hosted/local source-bound evidence; original per-task commands and source identities retained. |
| 185-10-01 | 10 | 6 | UIF-01, UIF-02, UIF-03, UIF-04, UIF-05, UIF-06 | T-185-21 | Actual source-bound runtime receipts; no new test file | Owning task verify XML; all commands and immediate fails_when are canonical there | Verified implementation candidate from current hosted/local source-bound evidence; original per-task commands and source identities retained. |
| 185-10-02 | 10 | 6 | UIF-01, UIF-02, UIF-03, UIF-04, UIF-05, UIF-06 | T-185-21 | Actual source-bound runtime receipts; no new test file | Frozen-source check | Mandatory outer acceptance: final tracking commit then fresh pinned-source dispatch and unchanged HEAD; not yet executed in this tracked record. |

All listed new test paths are created by their owning task before invocation. Task 185-01-01 starts with a real failing canonical-command subprocess test and is verified before expansion. Fixture-only injectable APIs do not grant the production command an input/ref/skip override. Plan 02 commits the immutable-source bootstrap ledger before Plan 07 removes generator findings.

Same-wave ownership is disjoint: Wave 1 = 01; Wave 2 = 02/04; Wave 3 = 03/05; Wave 4 = 06/07/08; Wave 5 = 09; Wave 6 = 10. All 22 task IDs above are final planning IDs. Long actual build/browser/hosted commands have bounded stages and are not promised to finish within 60 seconds. Measure pure focused feedback during implementation.

## Test creation ownership (no separate execution wave)

- [ ] Scanner/source-discovery and exact multiset negative fixtures, including trusted-ref bootstrap/history and cleanup reversals.
- [ ] Canonical command integration proving scanner/contrast/token subprocess failures propagate.
- [ ] Contrast below-threshold, dark-only, live-focus binding and malformed-input fixtures.
- [ ] Typed DTCG validator and independent CSS-only/JSON-only drift fixtures.
- [ ] Dual build-output assertions and matched rendering/state preservation proof using disposable stacks.
- [ ] Judge producer/consumer retirement and historical evidence compatibility tests.

Each owning task creates its focused tests before invoking them. Plans 01–03 own root contrast/scanner/typed-token contracts and canonical negative subprocess witnesses; Plan 04 owns current/legacy evidence retirement tests; Plan 05 owns disposable/retained source guard self-tests and pre-change captures; Plan 06 owns actual two-output forced-utility assertions; Plan 07 owns route/auth/mount proof; Plan 08 owns held-out UI states. No new framework or dependency.

## Rendered Preservation and Review Boundaries

The approved UI-SPEC requires matched evidence for eight screens, three appearance modes and three viewports, plus full-page/hover/focus/compact-navigation and held-out state coverage. The refreshed held-out before/candidate pair passes exact comparison for all 61 cases and 213 observations. The original candidate screen matrix (135 entries / 546 images), exact comparison/repeat, actual image/copy inspection and owned teardown are complete at their original source; the exact-input reconciliation records why the later CI-only source update does not require replay. These facts do not imply independent design approval.

Retained-preview preflight is stopped. Preserve that stop and data. Disposable build/browser stacks have distinct projects, ports and artifacts and do not prove the retained preview is current. Store review evidence under `ui-review-artifacts/`, outside Playwright cleanup. No human UAT gate, simulated approval or automatic visual-baseline update.

## Complete UI and edge obligations

Plan 08 authors every confirmed E/category pair as a separate structured `{statement, verification: backstop}` truth. Exact case titles are `E[number] [category]` in `ui_state_preservation.spec.ts` (42 empty/loading/error/populated/partial/zero-one-many obligations) and `ui_content_preservation.spec.ts` (9 overflow + 10 long-text obligations). Category/element index and meanings are in [185-SOURCE-AUDIT.md](185-SOURCE-AUDIT.md). Plan 09 requires actual paired capture/copy inspection and all 61 receipt joins; fixture availability, test collection and capture inventory do not establish observed preservation.

Each backstop needs actual held-out state execution or inspected matched captures at the named surface. No evidence means insufficient_spec/abstention; no human UAT or simulated approval substitutes. The four unclassified edge rows remain explicit unresolved flagged assumptions in the owning plans/audit. Three descriptorless judgment prohibitions in Plan 09 remain flagged-unverified, never auto-green.

Trusted Git cases use temporary real repositories: current target reductions, candidate first-parent reversal, valid/invalid immutable bootstrap, pre-introduction absence versus deletion/reset, duplicate/same-count/path changes and missing/shallow history. Contrast cases include raw boundaries, ordinary labels, focus/background changes, dark-only and malformed/missing data. Typed tokens independently mutate CSS and JSON and validate the entire document and exact theme key sets. Build assertions force utility candidates in both real profiles; route cases protect standalone/mounted/host auth and assets.

Final closeout is task 185-10-02: finish all summaries/tracking before the terminal committed source, then obtain fresh exact-source hosted authority with external receipt. No tracked summary, validation or STATE write follows successful terminal attestation. An actual subsequent source correction requires a new terminal dispatch.

## Validation Sign-Off

- [x] Every final task has automated verification or explicit earlier test prerequisites.
- [x] No three consecutive tasks lack fast automated feedback.
- [x] Missing test paths are created by owning plans before invocation.
- [x] No watch mode; measured focused feedback meets the target or documented limit.
- [x] All six requirements and approved UI backstops mapped to concrete final task IDs.
- [x] Implementation evidence reviewed before `nyquist_compliant` changes.

Implementation coverage is validated. Final tracking-source terminal acceptance remains external; this document grants no design approval or future terminal result.

## Execution index reconciliation

The final declared Plan08 includes task185-08-03; the map contains all 22 declared task IDs. External draft `final-nyquist-task-evidence-draft.json` maps the tasks and six requirements. Current held-out evidence is accepted before R15 and full candidate R4 with an exact 61/213 comparison and completed repeat. The original 135/546 candidate UI capture and inspection are complete at their frozen source. Current candidate required/full hosted closeout passed; final tracked-source terminal acceptance remains external.

At candidate source `4db097d9`, local `mix verify.repository_contracts` passed in 225.48 seconds and `mix verify.core --exclude integration --exclude docs_contract` passed in 410.61 seconds (`root-repository-r7-result.json`, `root-core-r7-result.json`). Hosted run 41295225239 passed core/package/backend/coverage/compatibility but failed the repository job because the existing demo PNG test dependency was not installed and the full handoff differed. The approved CI-only repair adds installation of the existing locked demo test prerequisites (`npm ci --ignore-scripts`, browser download disabled) and aligns run-owned handoff/artifact paths; its exact-source hosted successor passed after the diagnosed transport and measured accessibility timing repairs. These measured full-suite times exceed the 120-second target; that target applies to focused feedback, not full CI lanes.

## Current evidence and requirement status — 2026-11-01

| Requirement | Evidence now available | Remaining evidence | Phase status |
|---|---|---|---|
| UIF-01 | Actual canonical contract/build/rendered evidence plus current candidate 41318243156; detailed sources remain in preservation and goal verification. | Mandatory final tracked-source terminal proof only; classifier flags remain explicit. | Complete implementation candidate |
| UIF-02 | Actual canonical contract/build/rendered evidence plus current candidate 41318243156; detailed sources remain in preservation and goal verification. | Mandatory final tracked-source terminal proof only; classifier flags remain explicit. | Complete implementation candidate |
| UIF-03 | Actual canonical contract/build/rendered evidence plus current candidate 41318243156; detailed sources remain in preservation and goal verification. | Mandatory final tracked-source terminal proof only; classifier flags remain explicit. | Complete implementation candidate |
| UIF-04 | Actual canonical contract/build/rendered evidence plus current candidate 41318243156; detailed sources remain in preservation and goal verification. | Mandatory final tracked-source terminal proof only; classifier flags remain explicit. | Complete implementation candidate |
| UIF-05 | Actual canonical contract/build/rendered evidence plus current candidate 41318243156; detailed sources remain in preservation and goal verification. | Mandatory final tracked-source terminal proof only; classifier flags remain explicit. | Complete implementation candidate |
| UIF-06 | Actual canonical contract/build/rendered evidence plus current candidate 41318243156; detailed sources remain in preservation and goal verification. | Mandatory final tracked-source terminal proof only; classifier flags remain explicit. | Complete implementation candidate |

Evidence references: `/private/tmp/scrypath-phase185-execution/accepted-before-r15.json`, `/private/tmp/scrypath-phase185-execution/accepted-candidate-r4.json`, `/private/tmp/scrypath-phase185-execution/state-pair-authority-r15-r4.json`, `/private/tmp/scrypath-phase185-execution/ui-review-artifacts/phase185/state-pair-comparison-r15-r4/ui-state-pairs.json`, and `/private/tmp/scrypath-phase185-execution/mounted-r2-acceptance.json`. The mounted R2 check is a cached local retry, not cold-CI evidence; its own artifact manifest is focused and `acceptance_eligible:false`. The unchanged R15/R4 repeat log is `/private/tmp/scrypath-phase185-execution/state-pair-r15-r4-repeat.log`.

The original 135/546 capture and actual image/copy inspection remain complete at their original source; `global-input-reconciliation-e445a2c4.json` confirms no global replay is required for the CI-only change. The R15/R4 repeat receipt `state-pair-r15-r4-unchanged-result.json` pins the same output digest before and after for all 61/213/426 comparisons. Fresh hosted candidate evidence for the CI repair and the terminal exact-SHA run remain pending. Four unclassified assumptions (UIF-02/03/04/05) and three descriptorless judgment prohibitions remain flagged-unverified; none is auto-resolved or treated as human approval.

## Final implementation coverage cutoff

Current candidate [41318243156](https://github.com/szTheory/scrypath/actions/runs/41318243156) at `fa42d99ee3ad5290ea7d8ab089ba076c5e25558c` passed all five required jobs, coverage and exact-source immutable attestation, and its full advisory browser lane succeeded after the diagnosed transport, frame-safe accessibility, runtime-handoff, serial full-suite and cold-start repairs. Original local full/pair/global receipts retain their source identities. Final tracked-source terminal attestation remains mandatory and is not certified by this pre-dispatch record. All22 tasks have executable descriptors and behavior evidence; the only future action is the explicit final-tracked-source outer gate. There are no manual-only/UAT items. The four classifier assumptions and three judgment prohibitions remain unverified/nonblocking annotations. Feedback targets remain unmet where measured core/repository runs exceed120seconds; no performance pass is claimed. Earlier pending-status notes below/above are historical execution cutoffs superseded by this dated result.

The changed accessibility harness is covered by the current source-bound full receipt, not relabeled from C4db. The focused 17-case frame guard suite and actual 51-case affected-browser A/B passed before dispatch; real Chromium cross-origin/transient-frame/exception tests establish complete fallback behavior. Full acceptance and immutable artifact validation are in `candidate-r10-full-acceptance.json`.

## Serial full-suite source and proof boundary

The current source passed the complete serial full lane, immutable archive verification and independent canonical receipt recomputation. The batches preserve one worker, zero retries, original traces, the exact discovered union and clean owned teardown within the existing limits. The cold local path explicitly acquires only the existing service images before startup; failed acquisition prevents execution.

[Source reconciliation](185-SOURCE-AUDIT.md#serial-full-suite-source-and-proof-boundary) records the six changed outer overlay files, unchanged product/capture inputs, preserved original pair/global identities, discarded trace experiment and excluded failed/superseded runs. The actual current receipt is `candidate-r10-full-acceptance.json`. Final tracking-source terminal acceptance remains a separate mandatory external gate; no independent/design/risk approval or retained-preview action is inferred.

## Validation Audit 2026-11-01

| Metric | Count |
|---|---|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |
