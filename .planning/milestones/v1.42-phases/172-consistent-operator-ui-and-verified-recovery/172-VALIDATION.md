---
phase: "172"
slug: consistent-operator-ui-and-verified-recovery
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-10-03"
---

# Phase 172 — Validation Strategy

## Test Infrastructure

Existing ExUnit/Phoenix LiveView tests, static token and contrast contracts, Playwright mounted/full suites, and Docker Compose verifiers. Read CONTRIBUTING.md and `.planning/research/v1.42/UI-AUTOMATION.md` for canonical commands and actual proof boundaries. No framework installation or new required CI job.

## Sampling Rate

- After each behavior task, run focused existing/new ExUnit or browser assertions for that behavior.
- After each coherent wave, run `mix verify.ops_ui` (or its documented container equivalent); shared CSS also runs fast contrast/token checks.
- Final: existing required checks and `make verify-mounted` from `examples/scrypath_ecommerce`, plus one appropriate advisory visual run. No full matrix after every commit.
- Tests must fail on nonzero exit or no selected tests; arbitrary sleeps, optional Retry branches, prior successful tasks and generic existing documents do not prove recovery.

## Per-Task Verification Map

Each task owns its test additions; existing files are extended in place. New test/helper files are explicitly listed in their owning plan and created before its command. Commands execute at repository root. Runtime entries below record summary/log-backed outcomes, not plans alone. Product, PR delivery and release publication are verified. Final-source attestation is the enclosing post-commit transaction; its receipt is external so completion records can be included in that source.

| Task | Requirements | Exact automated command(s) | Test paths / infrastructure | Threat Ref | Runtime |
| --- | --- | --- | --- | --- | --- |
|172-01-1|OPUX-01, OPUX-03, OPUX-07|`cd scrypath_ops && MIX_ENV=test mix do compile --warnings-as-errors + test --warnings-as-errors test/scrypath_ops_web/live/control_room_live_test.exs`|`scrypath_ops/test/scrypath_ops_web/live/control_room_live_test.exs`|T-172-01|PASS — summary: focused Control Room 6 tests/0; precommit 157+2 doctests/0|
|172-01-2|OPUX-01, OPUX-03, OPUX-07|`cd scrypath_ops && MIX_ENV=test mix do compile --warnings-as-errors + test --warnings-as-errors test/scrypath_ops_web/design_tokens_contract_test.exs`<br>`make -C examples/scrypath_ecommerce contrast`|`scrypath_ops/test/scrypath_ops_web/design_tokens_contract_test.exs`|T-172-01|PASS — token contracts 4/0; contrast AA 0 (Plan01 summary)|
|172-02-1|OPUX-01, OPUX-02, OPUX-03|`cd scrypath_ops && MIX_ENV=test mix do compile --warnings-as-errors + test --warnings-as-errors test/scrypath_ops_web/live/search_live_test.exs test/scrypath_ops_web/ops_a11y_contract_test.exs`|`scrypath_ops/test/scrypath_ops_web/live/search_live_test.exs`<br>`scrypath_ops/test/scrypath_ops_web/ops_a11y_contract_test.exs`|T-172-02, T-172-03|PASS — combined Search/a11y coverage included in focused 39/0; precommit 165+2/0 (Plan02 summary)|
|172-02-2|OPUX-01, OPUX-02, OPUX-03|`cd scrypath_ops && MIX_ENV=test mix do compile --warnings-as-errors + test --warnings-as-errors test/scrypath_ops_web/live/playbook_live_test.exs test/scrypath_ops_web/ops_a11y_contract_test.exs`|`scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs`<br>`examples/scrypath_ecommerce/e2e/admin_shell_chrome.spec.ts`|T-172-02, T-172-03|PASS — combined LiveView/a11y/asset contracts included in focused 39/0; precommit 165+2/0 (Plan02 summary)|
|172-03-1|OPUX-03, OPUX-04|`cd scrypath_ops && MIX_ENV=test mix do compile --warnings-as-errors + test --warnings-as-errors test/scrypath_ops/operator_selection_test.exs`|`scrypath_ops/test/scrypath_ops/operator_selection_test.exs`|T-172-04, T-172-05|PASS — OperatorSelection 4/0; precommit 179+2 doctests/0 (Plan03 summary)|
|172-03-2|OPUX-03, OPUX-04|`cd scrypath_ops && MIX_ENV=test mix do compile --warnings-as-errors + test --warnings-as-errors test/scrypath_ops_web/live/failed_sync_live_test.exs test/scrypath_ops_web/live/posture_live_test.exs test/scrypath_ops_web/operator_ia_contract_test.exs`|`scrypath_ops/test/scrypath_ops_web/live/failed_sync_live_test.exs`<br>`scrypath_ops/test/scrypath_ops_web/live/posture_live_test.exs`<br>`scrypath_ops/test/scrypath_ops_web/operator_ia_contract_test.exs`|T-172-04, T-172-05|PASS — focused FailedSync/Posture/IA/SyncDrift 29/0; precommit 179+2/0 (Plan03 summary)|
|172-04-1|OPUX-04, OPUX-05, OPUX-06|`cd scrypath_ops && MIX_ENV=test mix do compile --warnings-as-errors + test --warnings-as-errors test/scrypath_ops/recovery_observation_test.exs test/scrypath_ops_web/live/failed_sync_live_test.exs`|`scrypath_ops/test/scrypath_ops/recovery_observation_test.exs`<br>`scrypath_ops/test/scrypath_ops_web/live/failed_sync_live_test.exs`|T-172-06, T-172-07, T-172-08, T-172-09|PASS — focused recovery/FailedSync 19/0; final combined 30/0; precommit 203+2/0 (Plan04 summary)|
|172-04-2|OPUX-04, OPUX-05, OPUX-06|`cd scrypath_ops && MIX_ENV=test mix do compile --warnings-as-errors + test --warnings-as-errors test/scrypath_ops/document_observation_test.exs test/scrypath_ops/recovery_observation_test.exs test/scrypath_ops_web/live/sync_drift_live_test.exs`|`scrypath_ops/test/scrypath_ops/document_observation_test.exs`<br>`scrypath_ops/test/scrypath_ops_web/live/sync_drift_live_test.exs`|T-172-06, T-172-07, T-172-08, T-172-09|PASS — focused document/recovery/SyncDrift 30/0; precommit 203+2/0 (Plan04 summary)|
|172-05-1|OPUX-03, OPUX-05, OPUX-07|`cd scrypath_ops && MIX_ENV=test mix do compile --warnings-as-errors + test --warnings-as-errors test/scrypath_ops/promotion_eligibility_test.exs test/scrypath_ops_web/live/sync_drift_live_test.exs`|`scrypath_ops/test/scrypath_ops/promotion_eligibility_test.exs`<br>`scrypath_ops/test/scrypath_ops_web/live/sync_drift_live_test.exs`|T-172-10, T-172-11|PASS — focused eligibility/SyncDrift 13/0; final precommit 208+2/0 (Plan05 summary)|
|172-05-2|OPUX-03, OPUX-05, OPUX-07|`cd scrypath_ops && MIX_ENV=test mix do compile --warnings-as-errors + test --warnings-as-errors test/scrypath_ops_web/live/sync_drift_live_test.exs test/scrypath_ops_web/live/posture_live_test.exs test/scrypath_ops_web/operator_ia_contract_test.exs`|`scrypath_ops/test/scrypath_ops_web/live/sync_drift_live_test.exs`<br>`scrypath_ops/test/scrypath_ops_web/live/posture_live_test.exs`|T-172-10, T-172-11|PASS — focused SyncDrift/Posture/IA 22/0; precommit 208+2/0 (Plan05 summary)|
|172-06-1|OPUX-04, OPUX-05, OPUX-06, OPUX-07|`make -C examples/scrypath_ecommerce verify-mounted`|`examples/scrypath_ecommerce/e2e/helpers/e2e.ts`<br>`examples/scrypath_ecommerce/e2e/operator.spec.ts`|T-172-12, T-172-13, T-172-14|PASS — mounted exact recovery journey; 4 passed, 0 retries/skips (source 3fd8972…, run log phase172-06-run10)|
|172-06-2|OPUX-04, OPUX-05, OPUX-06, OPUX-07|`make -C examples/scrypath_ecommerce verify-mounted`|`examples/scrypath_ecommerce/e2e/operator.spec.ts`<br>`examples/scrypath_ecommerce/e2e/helpers/e2e.ts`|T-172-12, T-172-13, T-172-14|PASS — exact task/document plus promotion journey; included in mounted 4/0 run (Plan06 summary)|
|172-07-1|OPUX-01, OPUX-02, OPUX-03, OPUX-07|`cd scrypath_ops && MIX_ENV=test mix do compile --warnings-as-errors + test --warnings-as-errors test/scrypath_ops_web/design_tokens_contract_test.exs test/scrypath_ops_web/ops_a11y_contract_test.exs`<br>`make -C examples/scrypath_ecommerce contrast`|`scrypath_ops/test/scrypath_ops_web/design_tokens_contract_test.exs`|T-172-15, T-172-16|PASS — final Ops suite 233+2 doctests/0; static contrast AA 0 (Plan07 summary/logs)|
|172-07-2|OPUX-01, OPUX-02, OPUX-03, OPUX-07|Prepared task-owned disposable server via `PLAYWRIGHT_BASE_URL` (never preview4012): `cd examples/scrypath_ecommerce && npm run test:e2e:admin-shell -- --workers=1 --retries=0`<br>`OPS_UI_LLM_JUDGE=0 OPS_UI_LLM_JUDGE_REQUIRED=0 make -C examples/scrypath_ecommerce verify-e2e`|`examples/scrypath_ecommerce/e2e/helpers/operator-ui.ts`<br>`examples/scrypath_ecommerce/e2e/operator.spec.ts`<br>`examples/scrypath_ecommerce/e2e/admin_shell_chrome.spec.ts`<br>`examples/scrypath_ecommerce/e2e/admin_contrast_matrix.spec.ts`<br>`examples/scrypath_ecommerce/e2e/admin_screenshot_matrix.spec.ts`|T-172-15, T-172-16|PASS — local corrected broad advisory and exact hosted candidate browser proof; see detailed results below|
|172-08-1|OPUX-07, OPUX-08|`mix verify.ops_ui`<br>`cd scrypath_ops && mix precommit`|existing closeout/check infrastructure; planning artifacts authored in task|T-172-17, T-172-18, T-172-19|PASS — root core 657 tests+4 properties/0; Ops 233+2 doctests/0; independent review resolved findings|
|172-08-2|OPUX-07, OPUX-08|`node scripts/ci_monitor.cjs closeout --push --branch "$(git branch --show-current)" --sha "$(git rev-parse HEAD)"`|existing closeout/check infrastructure; planning artifacts authored in task|T-172-17, T-172-18, T-172-19|PASS candidate/PR checks — exact-SHA candidate and PR run are green; initial watcher transport reset recovered by read-only collector|
|172-08-3|OPUX-07, OPUX-08|`node scripts/ci_monitor.cjs closeout --push --branch "$(git branch --show-current)" --sha "$(git rev-parse HEAD)"`<br>`git diff --exit-code HEAD`|existing closeout/check infrastructure; planning artifacts authored in task|T-172-17, T-172-18, T-172-19|COVERED — candidate closeout and release closeout passed; all completion records are prepared before final source selection. The enclosing final run and clean-tree check execute after commit; their actual receipt is external, not preclaimed here|

## Executed evidence crosswalk

Plan07 consolidated eight UI truths cover all50 applicable element/category pairs. Element mapping: E1=shell/handoffs; E2=Posture/fleet; E3=Failed Sync; E4=Sync/recovery/promotion; E5=Search; E6=Playbooks; E7=dialogs. Pair counts below are from `172-SOURCE-AUDIT.md`: empty6 + loading7 + error7 + populated5 + partial6 + overflow7 + zero/one/many5 + long-text7 = **50**.

| UI truth | Covered pair category/elements | Named executable evidence and result |
| --- | --- | --- |
| Empty collections show named empty copy; absent configuration shows setup/disabled controls | empty E2–E7; error/partial E1–E7 | `control_room_live_test.exs` unconfigured fleet; `search_live_test.exs` empty allowlist and disabled runtime; `failed_sync_live_test.exs` zero work vs empty allowlist vs failed observation; `playbook_live_test.exs` empty workspace. Focused plan suites and final Ops 233+2 doctests passed. |
| Pending work retains input/context, blocks duplicates and discards superseded results | loading E1–E7; partial E2–E7 | `sync_drift_live_test.exs` duplicate/replay, stale queued checks and old observer generation; `playbook_live_test.exs` superseded run; `failed_sync_live_test.exs` schema/refresh behavior; `admin_shell_chrome.spec.ts` modal cycle and overlay isolation. Plan07 full browser run passed at corrected candidate (104/104 hosted); local focused regressions passed. |
| Failed read/mutation names object and next supported action; old evidence becomes stale | error E1–E7; partial E2–E7 | FailedSync failed observation/refuse retry; SyncDrift stale contract and recovery refresh; Playbooks forced failure/raw error; Posture errors-first/failed-sync egress; mounted `operator.spec.ts` recovery and history. Root’s latest queue-error cause test: 16/0 (RED16/2); promotion observation test: 17/0 (RED17/1). |
| Populated rows expose identity/state/action and actionable reason before Diagnostics | populated E2–E6 | FailedSync triage/reason-class and bounded latest Oban map cause; Posture errors-first; Search successful capture; Playbooks catalog/import; mounted `operator.spec.ts` rendered Retry. UI evidence is supplemented by direct image review recorded in Plan07 summary and `172-EVIDENCE.md`. |
| Partial observations name unavailable sources; unknown queue/task/document correlation never claims success | partial E2–E7; error E1–E7 | `promotion_eligibility_test.exs` unavailable/pending/failure denial; `recovery_observation_test.exs` exact receipt joins and expiry/restart unknown; `document_observation_test.exs` unknown task status, malformed identity, transport and delete limits; `sync_drift_live_test.exs` promotion poll errors render unknown. Plan06 mounted exact recovery passed 4/4; final candidate browser proof passed 104/104. |
| 320/390 layout has no page overflow; action groups and identifiers reflow; technical data is contained | overflow E1–E7 | `admin_shell_chrome.spec.ts`: `representative operator boundaries and non-contrast accessibility`, `long content and five-schema native select`, `narrow operator header controls do not overlap`; Plan07 reports five widths (320,390,1279,1280,1440), six surfaces and theme variants. Corrected local advisory set 9/9 and hosted full browser suite 104/104. |
| Zero/one/many has correct copy/order, both schema-picker branches work, summary ≤160px at 390px | zero-one-many E2,E3,E4,E5,E6 | FailedSync zero/singular tests; Search zero/populated schema picker; Playbooks empty/catalog; promotion eligibility set checks; browser radio/select and geometry scenarios in `admin_shell_chrome.spec.ts`. Plan07 browser evidence passed at the exact hosted candidate. |
| Long labels, filenames, IDs, errors, navigation remain accessible and actionable type stays ≥14px | long-text E1–E7 | `operator_selection_test.exs` exact UTF-8 identity and encoding; Playbooks labels/file actions/preserved invalid value; `document_observation_test.exs` encoded ID/index paths; Plan07 long-content fixture/geometry and image captures. Hosted light filename/width inventory passed 20/20; this is inventory/width evidence, not pixel parity. |

## Requirements and task results

| Requirement | Named tests / result | Current boundary |
| --- | --- | --- |
| OPUX-01 shared roles and responsive surfaces | `design_tokens_contract_test.exs`, `control_room_live_test.exs`, `admin_shell_chrome.spec.ts`; Plan07 precommit 233 tests+2 doctests/0, shell matrix 6/6, five widths, static contrast AA0 | Covered by local and candidate evidence; contrast AAA advisories remain advisory (36 static). |
| OPUX-02 accessible inputs and modal focus | `ops_a11y_contract_test.exs`, Search/Playbooks LiveView tests, `admin_shell_chrome.spec.ts` full focus/overlay lifecycle; Plan07 dialogs RED21/2→GREEN21/0 and browser rename1/1 | Covered in Plan07 tests and hosted browser lane; no paid judge approval claimed. |
| OPUX-03 domain terms/action hierarchy | `operator_ia_contract_test.exs`, six LiveView suites, Plan07 copy contract38/0 and full shell/recovery browser cases | Source-audit classifier assumption A-03 remains flagged despite behavior tests. |
| OPUX-04 schema/context identity | `operator_selection_test.exs`4/0, FailedSync/SyncDrift stale-generation tests, mounted non-first Variant journey | Plan06 mounted exact-source run 4/4, no retries/skips; A-04 remains flagged as manual edge-classification assumption. |
| OPUX-05 truthful recovery/promotion | RecoveryObservation, DocumentObservation and PromotionEligibility focused tests; latest queue readiness RED19/2→GREEN19/0 and promotion-observation RED17/1→GREEN17/0; Ops suite233+2/0 | Candidate browser and mounted evidence pass. A-05’s unknown-on-missing/malformed-correlation predicate is explicitly resolved. |
| OPUX-06 exact rendered recovery effect | `operator.spec.ts` exact replacement job/attempt/task/document and promotion pair; mounted run4/4; hosted browser104/104 | A-06 remains flagged for classifier completeness; do not generalize the deterministic journey to all possible stale/replay inputs. |
| OPUX-07 regression/responsive/keyboard/theme/image evidence | Plan07 per-surface tests, shell full lifecycle, five-width geometry, contrast reports, 40-shot capture matrix; hosted light inventory20/20 | The corrected exact-source hosted candidate passes; local broad first pass was95/104, then the nine obsolete expectation corrections passed9/9. Preserve both results, never relabel the initial run green. A-07 remains a flagged classifier assumption. |
| OPUX-08 reviewed delivery/traceability/release/cleanup | Plan08 local root `mix verify.core --exclude integration --exclude docs_contract`: 657 tests+4 properties/0 (85 excluded); Ops verify/precommit each233+2/0; independent review has0 open findings. Candidate `135517b2aa7d1515a4be71c4f9d53aa8dd60c341`, run37178388184 has all required jobs, coverage, full browser104/104, mounted4/4 and workflow attestation green. PR #91 run37178390800 has all required plus scoped Ops green. | PR91 merged3ad154a; PR92 merged8dd20e8 and published0.3.15 with live publish/parity run37181522723. Cleanup verified; preview retained. Final enclosing attestation remains external; A-08 stays a classifier-completeness flag, not a missing product proof. |

### Candidate runtime detail and incident chronology

- Candidate `135517b2aa7d1515a4be71c4f9d53aa8dd60c341`, workflow run `37178388184`: required jobs, coverage, browser and attestation passed. Hosted browser proof: **104 passed in 5.9 minutes**, mounted: **4 passed in 9.2 seconds**, filename/width inventory **20/20**, static AA **0 failures**. Browser log: `/private/tmp/phase172-hosted-browser-proof2.log`.
- Read-only `collect-readiness` exited0 and validated signed-by-workflow artifact/archive/member identity. A first closeout watcher exited1 only because of a transport connection reset; collector evidence recovers readiness without pretending the watcher command exited0. Receipt: `/private/tmp/phase172-candidate-receipt.json`.
- PR `#91`, run `37178390800`: all required jobs and scoped Ops job green. This supports candidate review/CI but is not merge or final delivery.
- Local broad advisory history: first source run **95/104**, nine obsolete expectation failures, zero retries/skips/flakes; corrected test-only source ran **9/9**; full hosted corrected candidate then passed **104/104**. Preserve the distinction and source/run identities in `172-EVIDENCE.md`.
- Completion still needs actual PR merge/delivery identity, final exact-SHA canonical attestation/receipt after all completion bookkeeping, recorded release disposition/publication state, and disposable-stack cleanup/retention confirmation. Never substitute the current candidate or PR synthetic merge SHA for final source.
- The pre-existing `Scrypath.Sync.sync_related/3` dependency typing warning remains visible during local Ops compilation; own warnings-as-errors checks passed. It is not a Phase172 regression.

## Seven resolved edge predicates

| Predicate | Named evidence and disposition |
| --- | --- |
| OPUX-01 empty/setup | Control Room unconfigured fleet; Search and FailedSync empty allowlist distinct from healthy zero. Explicitly resolved. |
| OPUX-01 UTF-8 identity | `operator_selection_test.exs` preserves exact canonical name and `%C3%89clair` URL; rendered selector/handoff tests. Explicitly resolved. |
| OPUX-02 empty/count | Search zero/one/four/five schema picker and Playbooks empty/import cases; browser native-select branch. Explicitly resolved. |
| OPUX-02 long UTF-8 value | Playbook label/file/paste tests and long-content fixture preserve text; browser geometry. Explicitly resolved. |
| OPUX-02 overlay concurrency | Playbook dialog semantics plus full focus, Escape, cancel, removed-trigger, patch and overlay lifecycle browser coverage. Explicitly resolved. |
| OPUX-05 missing/malformed correlation | Recovery/document observers return unknown; unknown never becomes verified or promotion-ready. Explicitly resolved. |
| OPUX-05 exact encoded target | Document observer checks exact task/index/document path and projected JSON; receipt joins task UID/index/type/attempt. Explicitly resolved. |

## Five flagged classifier assumptions and prohibition fallback

The source audit retains A-03, A-04, A-06, A-07 and A-08 as *manual edge-classification assumptions*, not resolved predicates. Their tests provide behavior evidence but do not certify classifier completeness.

| Assumption | Flagged boundary | Evidence / outstanding boundary |
| --- | --- | --- |
| A-03 / OPUX-03 | Task hierarchy, copy and state boundaries | IA contract and six LiveView suites plus Plan07 copy contracts38/0; assumption remains visible. |
| A-04 / OPUX-04 | Invalid/removed/non-first/back/refresh/context isolation | OperatorSelection, rendered handoffs, stale-generation tests and mounted journey; no classifier-completeness claim. |
| A-06 / OPUX-06 | Stale task, wrong document and replayability | Exact mounted task/document journey and negative controls; retain as classifier assumption. |
| A-07 / OPUX-07 | Responsive layout, focus, theme and diagnostic proof | Five widths, full keyboard lifecycle, browser contrast, full capture matrix and direct image dispositions; retain as classifier assumption. |
| A-08 / OPUX-08 | SHA, review, release and cleanup identity | Candidate/PR/release identities and cleanup now recorded in EVIDENCE. Final post-commit receipt is external. The classifier assumption remains flagged. |

`172-SOURCE-AUDIT.md` also records two descriptor-less prohibition fallbacks. They remain **flagged-unverified**: source/tests/review substantiate truthful failure-history and reviewer-identity requirements, but no wired prohibition descriptor exists. Do not claim descriptor-based automatic enforcement or human approval.

## Wave 0 Requirements

Existing infrastructure is available. New tests/fixtures must be introduced with their owning behavior, listed explicitly by the planner; no empty stubs treated as coverage.

## Manual-Only Verifications

None. Direct agent screenshot inspection is part of the implementation review. Maintainer feedback is optional design direction, not pending acceptance.

## Validation Sign-Off

- [x] Every planned task has an executable check and observable failure direction.
- [x] Missing test/fixture paths are created by an explicit dependency.
- [x] Sampling has no three consecutive tasks without automated verification.
- [x] Runtime evidence covers each listed behavior at the changed source.
- [x] Nyquist compliance audited after implementation; no planning-time pass claim.

## Finalization boundary

`nyquist_compliant` records implemented test coverage and observed passing candidate/release evidence, not a future final run result. Plan08 explicitly requires this validation record and all other completion writes before final attestation. The enclosing finalization operation must fail closed if the final exact SHA fails; its successful receipt is stored outside tracked source. No final run ID is invented here.
