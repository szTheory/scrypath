---
phase: "185"
slug: "executable-ui-quality-foundations"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-30"
---

# Phase 185 — Validation Strategy

Planning contract only; no implementation verification is claimed. Final task IDs, waves and test paths below match the ten executable plans and 21 tasks. Implementation remains pending.

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

Select the installed supported Elixir/OTP toolchain explicitly before local Mix commands. No package installation or new framework is planned. Preserve the five required CI jobs and advisory/path-scoped lanes.

## Sampling Rate

- Every task: focused automated tests including negative fixtures for the changed behavior.
- Every wave: canonical `mix verify.repository_contracts`; run built/browser checks when their inputs change.
- Before phase completion: CONTRIBUTING changed-scope verification and exact-source terminal closeout after tracked writes, with receipt outside frozen source.
- Long Docker/browser checks do not replace fast pure checks. No watch commands.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirements | Threat Ref | Exact test paths / evidence | Automated verification | Status |
|---|---|---|---|---|---|---|---|
| 185-01-01 | 01 | 1 | UIF-04 | T-185-01 | test/mix/tasks/ui_contrast_contract_test.exs<br>test/mix/tasks/verify.phase99_test.exs | Owning task verify XML; all commands and immediate fails_when are canonical there | Planned, not run |
| 185-01-02 | 01 | 1 | UIF-04 | T-185-01 | test/mix/tasks/ui_contrast_contract_test.exs | Owning task verify XML; all commands and immediate fails_when are canonical there | Planned, not run |
| 185-02-01 | 02 | 2 | UIF-01 | T-185-03 | scripts/ci/ui_literal_policy.test.cjs<br>test/mix/tasks/ui_literal_contract_test.exs | Owning task verify XML; all commands and immediate fails_when are canonical there | Planned, not run |
| 185-02-02 | 02 | 2 | UIF-01 | T-185-03 | scripts/ci/ui_literal_policy.test.cjs<br>test/mix/tasks/ui_literal_contract_test.exs | Owning task verify XML; all commands and immediate fails_when are canonical there | Planned, not run |
| 185-03-01 | 03 | 3 | UIF-05 | T-185-06 | test/mix/tasks/ui_tokens_contract_test.exs | Owning task verify XML; all commands and immediate fails_when are canonical there | Planned, not run |
| 185-03-02 | 03 | 3 | UIF-05 | T-185-06 | test/mix/tasks/ui_tokens_contract_test.exs | Owning task verify XML; all commands and immediate fails_when are canonical there | Planned, not run |
| 185-04-01 | 04 | 2 | UIF-06 | T-185-08 | test/mix/tasks/workflow_wiring_test.exs | Owning task verify XML; all commands and immediate fails_when are canonical there | Planned, not run |
| 185-04-02 | 04 | 2 | UIF-06 | T-185-08 | scripts/ci/ecommerce_evidence.test.cjs<br>scripts/ci/ecommerce_target.test.cjs<br>test/mix/tasks/workflow_wiring_test.exs | Owning task verify XML; all commands and immediate fails_when are canonical there | Planned, not run |
| 185-04-03 | 04 | 2 | UIF-06 | T-185-08 | test/mix/tasks/workflow_wiring_test.exs | Owning task verify XML; all commands and immediate fails_when are canonical there | Planned, not run |
| 185-05-01 | 05 | 3 | UIF-02, UIF-03 | T-185-10 | scripts/ci/ui_preservation.test.cjs<br>examples/scrypath_ecommerce/e2e/ui-review.selftest.mjs | Owning task verify XML; all commands and immediate fails_when are canonical there | Planned, not run |
| 185-05-02 | 05 | 3 | UIF-02, UIF-03 | T-185-10 | scripts/ci/ui_preservation.test.cjs | Owning task verify XML; all commands and immediate fails_when are canonical there | Planned, not run |
| 185-06-01 | 06 | 4 | UIF-02 | T-185-13 | scripts/ci/ui_bundle_contract.test.cjs | Owning task verify XML; all commands and immediate fails_when are canonical there | Planned, not run |
| 185-06-02 | 06 | 4 | UIF-02 | T-185-13 | scripts/ci/ui_bundle_contract.test.cjs | Owning task verify XML; all commands and immediate fails_when are canonical there | Planned, not run |
| 185-07-01 | 07 | 4 | UIF-03, UIF-01 | T-185-15 | scrypath_ops/test/scrypath_ops_web/controllers/page_controller_test.exs | Owning task verify XML; all commands and immediate fails_when are canonical there | Planned, not run |
| 185-07-02 | 07 | 4 | UIF-03, UIF-01 | T-185-15 | examples/scrypath_ecommerce/e2e/ui_routes_preservation.spec.ts | Owning task verify XML; all commands and immediate fails_when are canonical there | Planned, not run |
| 185-08-01 | 08 | 4 | UIF-02, UIF-03 | T-185-17 | examples/scrypath_ecommerce/e2e/ui_state_preservation.spec.ts<br>examples/scrypath_ecommerce/test/support/phase173_fixture_source.ex<br>scrypath_ops/test/support/phase173_fixture_source.ex | Owning task verify XML; all commands and immediate fails_when are canonical there | Planned, not run |
| 185-08-02 | 08 | 4 | UIF-02, UIF-03 | T-185-17 | examples/scrypath_ecommerce/e2e/ui_content_preservation.spec.ts | Owning task verify XML; all commands and immediate fails_when are canonical there | Planned, not run |
| 185-09-01 | 09 | 5 | UIF-02, UIF-03, UIF-06 | T-185-19 | Actual source-bound runtime receipts; no new test file | Owning task verify XML; all commands and immediate fails_when are canonical there | Planned, not run |
| 185-09-02 | 09 | 5 | UIF-02, UIF-03, UIF-06 | T-185-19 | Actual source-bound runtime receipts; no new test file | Owning task verify XML; all commands and immediate fails_when are canonical there | Planned, not run |
| 185-10-01 | 10 | 6 | UIF-01, UIF-02, UIF-03, UIF-04, UIF-05, UIF-06 | T-185-21 | Actual source-bound runtime receipts; no new test file | Owning task verify XML; all commands and immediate fails_when are canonical there | Planned, not run |
| 185-10-02 | 10 | 6 | UIF-01, UIF-02, UIF-03, UIF-04, UIF-05, UIF-06 | T-185-21 | Actual source-bound runtime receipts; no new test file | Frozen-source check | Planned, not run |

All listed new test paths are created by their owning task before invocation. Task 185-01-01 starts with a real failing canonical-command subprocess test and is verified before expansion. Fixture-only injectable APIs do not grant the production command an input/ref/skip override. Plan 02 commits the immutable-source bootstrap ledger before Plan 07 removes generator findings.

Same-wave ownership is disjoint: Wave 1 = 01; Wave 2 = 02/04; Wave 3 = 03/05; Wave 4 = 06/07/08; Wave 5 = 09; Wave 6 = 10. All 21 task IDs above are final planning IDs. Long actual build/browser/hosted commands have bounded stages and are not promised to finish within 60 seconds. Measure pure focused feedback during implementation.

## Test creation ownership (no separate execution wave)

- [ ] Scanner/source-discovery and exact multiset negative fixtures, including trusted-ref bootstrap/history and cleanup reversals.
- [ ] Canonical command integration proving scanner/contrast/token subprocess failures propagate.
- [ ] Contrast below-threshold, dark-only, live-focus binding and malformed-input fixtures.
- [ ] Typed DTCG validator and independent CSS-only/JSON-only drift fixtures.
- [ ] Dual build-output assertions and matched rendering/state preservation proof using disposable stacks.
- [ ] Judge producer/consumer retirement and historical evidence compatibility tests.

Each owning task creates its focused tests before invoking them. Plans 01–03 own root contrast/scanner/typed-token contracts and canonical negative subprocess witnesses; Plan 04 owns current/legacy evidence retirement tests; Plan 05 owns disposable/retained source guard self-tests and pre-change captures; Plan 06 owns actual two-output forced-utility assertions; Plan 07 owns route/auth/mount proof; Plan 08 owns held-out UI states. No new framework or dependency.

## Rendered Preservation and Review Boundaries

The approved UI-SPEC requires matched evidence for eight screens, three appearance modes and three viewports, plus full-page/hover/focus/compact-navigation and held-out state coverage. Map every UI consideration backstop to explicit tests or inspected matched captures. Use the same browser/platform/data/route/state/viewport and source-bound pre-change/candidate pair; report the intentional standalone generator redirect separately. Inspect actual images and copy. Capture completion is not pixel parity or independent design approval.

Retained-preview preflight is stopped. Preserve that stop and data. Disposable build/browser stacks have distinct projects, ports and artifacts and do not prove the retained preview is current. Store review evidence under `ui-review-artifacts/`, outside Playwright cleanup. No human UAT gate, simulated approval or automatic visual-baseline update.

## Complete UI and edge obligations

Plan 08 authors every confirmed E/category pair as a separate structured `{statement, verification: backstop}` truth. Exact case titles are `E[number] [category]` in `ui_state_preservation.spec.ts` (42 empty/loading/error/populated/partial/zero-one-many obligations) and `ui_content_preservation.spec.ts` (9 overflow + 10 long-text obligations). Category/element index and meanings are in [185-SOURCE-AUDIT.md](185-SOURCE-AUDIT.md). Plan 09 requires actual paired capture/copy inspection and all 61 receipt joins; fixture availability, test collection and capture inventory do not establish observed preservation.

Each backstop needs actual held-out state execution or inspected matched captures at the named surface. No evidence means insufficient_spec/abstention; no human UAT or simulated approval substitutes. The four unclassified edge rows remain explicit unresolved flagged assumptions in the owning plans/audit. Three descriptorless judgment prohibitions in Plan 09 remain flagged-unverified, never auto-green.

Trusted Git cases use temporary real repositories: current target reductions, candidate first-parent reversal, valid/invalid immutable bootstrap, pre-introduction absence versus deletion/reset, duplicate/same-count/path changes and missing/shallow history. Contrast cases include raw boundaries, ordinary labels, focus/background changes, dark-only and malformed/missing data. Typed tokens independently mutate CSS and JSON and validate the entire document and exact theme key sets. Build assertions force utility candidates in both real profiles; route cases protect standalone/mounted/host auth and assets.

Final closeout is task 185-10-02: finish all summaries/tracking before the terminal committed source, then obtain fresh exact-source hosted authority with external receipt. No tracked summary, validation or STATE write follows successful terminal attestation. An actual subsequent source correction requires a new terminal dispatch.

## Validation Sign-Off

- [ ] Every final task has automated verification or explicit earlier test prerequisites.
- [ ] No three consecutive tasks lack fast automated feedback.
- [ ] Missing test paths are created by owning plans before invocation.
- [ ] No watch mode; measured focused feedback meets the target or documented limit.
- [ ] All six requirements and approved UI backstops mapped to concrete final task IDs.
- [ ] Implementation evidence reviewed before `nyquist_compliant` changes.

Approval: pending implementation evidence. This document records planned checks, not completed tests.
