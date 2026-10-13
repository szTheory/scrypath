---
phase: "173"
slug: "shared-visual-foundation-and-operational-time"
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-10-06"
---

# Phase 173 — Validation Strategy

Planning validation is separate from product verification. Phase 173 has executable evidence for OPUX-09–OPUX-15. Historical per-task gates and their source SHAs are recorded below; the final-source audit at `1174a53f87d73c4e658029866a49c41d345452d9` rechecked all seven requirements and 11 task paths, and reran the shell, status, and PostureLive regression suites. It did not rerun unchanged time, clipboard, root-core, contrast, or full Ops gates at that SHA; their prior passing receipts remain identified by their original SHAs. The independent plan checker passed after one revision.

## Test Infrastructure

| Property | Value |
| --- | --- |
| Framework | Existing root/Ops ExUnit suites, token contrast checker, ecommerce Playwright |
| Configuration | Root and Ops mix.exs; ecommerce package.json, playwright.config.ts and existing Docker orchestration |
| Quick Ops command, from root | `cd scrypath_ops && mix test test/scrypath_ops_web/design_tokens_contract_test.exs test/scrypath_ops_web/ops_shell_contract_test.exs test/scrypath_ops_web/live/posture_live_test.exs` |
| Root timestamp command | `mix test test/scrypath/operator/status_test.exs` |
| Root core gate | `mix verify.core --exclude integration --exclude docs_contract` from repository root in 173-02-T3 after T2's atomic normalization commit; a nonzero result blocks completion |
| Static contrast command | `make -C examples/scrypath_ecommerce contrast` |
| Full Ops gate | `mix verify.ops_ui` from repository root; Ops `mix precommit` when implementation is complete |
| Mounted gate | `make -C examples/scrypath_ecommerce verify-mounted` |
| Browser gate | `bash examples/scrypath_ecommerce/scripts/verify-phase173.sh {shell\|time\|status\|copy}` creates and cleans an isolated mounted+standalone Compose stack. 173-01-T2's production-route/asset smoke and 173-01-T3 shell suite passed; subsequent `time`, `status`, and `copy` suites passed with their own deterministic cases. Existing `make -C examples/scrypath_ecommerce verify-e2e` remains advisory. |
| Runtime | Not measured in this planning run; focused feedback targets under 120 seconds; the full root core gate and disposable browser startup are slower plan/wave gates reported separately, with no under-120-second claim |

## Sampling Rate

- After each task, run the focused test/contrast command named by that task, with an observable nonzero-exit or empty-suite failure condition.
- After each wave, run relevant focused tests and that wave's Phase 173 browser proof on disposable fixtures; run `mix verify.ops_ui` after source-complete Ops changes. Run the root core gate in 173-02-T3 after T2's normalized core source is committed and rerun after any later root core edit.
- Before phase verification, all per-requirement obligations and applicable CONTRIBUTING.md gates must have current-source evidence.
- Feedback target: under 120 seconds for focused checks. The full root core gate and disposable browser startup are separate slower wave gates; do not claim an unmeasured runtime.
- Run root and Ops test paths from their own Mix projects. Do not pass `scrypath_ops/test/...` to root `mix test`.

## Per-Requirement Plan/Task Verification Map

| Requirement | Plan/tasks | Automated command and executable evidence |
| --- | --- | --- |
| OPUX-09 | 173-01-T1/T2/T3 | **COVERED.** Shell contract (10 tests), disposable production-route/asset smoke, and contrast (0 AA failures) passed. The current-source `shell` browser suite passed 14/14 at `b12a7c47157b4fb88b05237b7e2525d11896fd59`; both entrypoints, light/dark/System, responsive widths, pre-paint theme, storage failures, flat shell, and scroll cues are covered. |
| OPUX-10 | 173-03-T1/T2/T3 | **COVERED.** Focused Ops suite (31 tests) and `status` browser suite (6 tests) passed. Production LiveViews cover neutral containers, explicit degraded/failed/unknown cues, and partial retained data. |
| OPUX-11 | 173-03-T1/T2/T3 | **COVERED.** Same current-source Ops and `status` suites passed; neutral zero, nonzero/unavailable distinctions, queue-unused, and no freshness implication are asserted. |
| OPUX-12 | 173-01-T1/T2/T3 | **COVERED.** Shell contract passed. The current-source `shell` browser suite passed 14/14 at `b12a7c47157b4fb88b05237b7e2525d11896fd59`, including pointer/keyboard preference, one visual/ARIA selection, System appearance, pre-paint theme, reload/navigation/cross-tab behavior, and get/set/remove storage failures. |
| OPUX-13 | 173-03-T2/T3 | **COVERED.** Focused Ops contracts and `status` browser suite (6 tests) passed for hover/press/focus/selected/disabled/busy, retained labels/icons, reduced motion, and server eligibility after patches. |
| OPUX-14 | 173-02-T1/T2/T3 | **COVERED.** Root status tests (6), focused PostureLive tests (11), `time` browser suite (8), and `mix verify.core --exclude integration --exclude docs_contract` (660 tests + 4 properties) passed. Boundary/precision/future cases, fixed observation snapshot, exact ISO/UTC disclosure, and absent/unavailable/unused states are asserted in both entrypoints. |
| OPUX-15 | 173-04-T1/T2 | **COVERED.** The current-source `copy` browser suite passed 10/10 at `b12a7c47157b4fb88b05237b7e2525d11896fd59`; Ops `mix precommit` and root `mix verify.ops_ui` each passed 246 tests plus 2 doctests. Exact source payload, awaited result, four-second reset, persistent rejection/unavailable guidance, selection, Checked no-copy, keyboard/touch, and failed-refresh age are covered in both entrypoints. |

### Final-source refresh

At `b12a7c47157b4fb88b05237b7e2525d11896fd59`, the shell suite passed 14/14 and the timestamp-copy suite passed 10/10. The independent UI review scored 24/24 with no human-review item; the code review reported zero findings. No requirement coverage gap or manual-only item remains.

## Per-Task Execution Results

| Task | Result | Evidence |
| --- | --- | --- |
| 173-01-T1 | PASS | Ops shell contract: 10 tests, 0 failures. |
| 173-01-T2 | PASS | `verify-phase173.sh shell --smoke`: both production routes and entrypoint assets reachable; disposable stack cleaned. |
| 173-01-T3 | PASS | `verify-phase173.sh shell`: 11 browser tests, 0 failures. |
| 173-02-T1 | PASS | Focused PostureLive suite: 11 tests, 0 failures. |
| 173-02-T2 | PASS | Root status suite: 6 tests; focused PostureLive suite: 11 tests; 0 failures. |
| 173-02-T3 | PASS | `verify-phase173.sh time`: 8 browser tests; root core gate: 660 tests + 4 properties, 0 failures. |
| 173-03-T1/T2 | PASS | Focused design-token, shell, and PostureLive suite: 31 tests, 0 failures. |
| 173-03-T3 | PASS | `verify-phase173.sh status`: 6 browser tests; contrast: 0 AA failures. |
| 173-04-T1/T2 | PASS | `verify-phase173.sh copy`: 10 browser tests; Ops LiveView/full suite and accessibility checks passed; contrast: 0 AA failures. |

Every task's `<verify>` has an automated command and an explicit nonzero/empty-suite failure condition; all planned task checks passed. The standalone and mounted browser proofs assert source-derived production PostureLive rows/controls and actual built Ops assets so duplicated fixture markup cannot satisfy them. The core gate's workspace-clean check passed in its isolated execution checkout. Images were inspected in their slices, supplemented by computed style, geometry, and state assertions. The Phase 173 runner uses a unique Compose project, no published host port for its standalone service, and removes its owned containers/volume/network; preview :4012 was excluded and remains untouched.

## Multi-Source Coverage Audit

| Source | Items | Coverage |
| --- | --- | --- |
| GOAL | Neutral readable state, one preference, actions, trustworthy time/copy | 173-01 through 173-04, in outcome order. |
| REQ | OPUX-09–OPUX-15 | Every ID appears in its owning plan frontmatter and task map above. |
| RESEARCH | Neutral tokens, local severity/zero, guarded browser preference, action hooks, source ISO/snapshot, disclosure/copy, dual-entrypoint proof, no new dependency | 173-01/T1-T3; 173-02/T1-T3; 173-03/T1-T3; 173-04/T1-T2. |
| CONTEXT | D-01–D-03 completed research/UI adoption and no dependency; D-04–D-14 palette/status/theme/action; D-15–D-20 time/copy; D-21–D-22 evidence/preservation | D-01–D-03 173-01; D-04–D-14 173-01/03; D-15–D-20 173-02/04; D-21–D-22 all plans. |

Deferred later-phase recovery/repair/search consolidation, ticking clock, local-time preference, new framework/service/CI lane are excluded by CONTEXT/ROADMAP. Package legitimacy gate is inapplicable because no package install is planned. Browser Clipboard/storage calls do not make this an external API/service integration.

## Spec-less Edge and Prohibition Disposition

No Phase 173 SPEC exists. The deterministic edge probe in `/tmp/scrypath-173-edge-coverage.json` reported 10 rows: four `unclassified` and six classified. The four initial unclassified assumptions are now resolved by behavioral evidence: OPUX-09 breakpoint behavior is exercised by the shell browser matrix; OPUX-11 zero/unavailable/partial distinctions are exercised by the status browser matrix and PostureLive tests; OPUX-12 denied-storage behavior is exercised by shell cases in both entrypoints; and OPUX-15 clipboard rejection and absence are exercised by the copy browser cases in both bundles (prior exact-source run at `b12a7c47157b4fb88b05237b7e2525d11896fd59`).

Classified rows resolve to explicit tests: OPUX-10 empty/encoding uses zero-config, one/many schema rows and long Unicode identifiers/reasons that wrap without truncation (173-03-T2/T3). OPUX-13 empty/encoding requires meaningful nonempty action labels and long Unicode labels that retain icon/target and wrap (173-03-T2/T3). OPUX-14 boundary/precision tests exactly 59/60/3599/3600/86399/86400/604799/604800 seconds, microsecond-future comparison before flooring, source fractional/offset preservation, and full UTC display (173-02-T2/T3). No backstop-only acceptance is used.

Adversarial intent probe retains two project-specific prohibitions already made testable above: zero/last success/failed fetch must not imply current document freshness (173-02/03), and clipboard dispatch/rejection must not claim successful copy (173-04). Routine input hygiene and canon security checks stay in existing tests/guidance; no synthetic approval or judgment-only completion gate is introduced.

## Wave 0 Requirements

173-01-T2 created the isolated standalone service, paired app-local test-support fixture providers and test config, both routes into production PostureLive, fixed observation snapshot, and `--smoke` route/asset probe. The mounted host cannot use the Ops dependency's test/support module, so each app supplies its own provider behind the same private source contract; browser cases assert parity. 173-01-T3 wired the first browser spec and shell scope dispatch. The `time`, `status`, and `copy` specs and their docker-playwright.sh dispatch cases were added by 173-02-T3, 173-03-T3, and 173-04-T1. Existing Playwright infrastructure or shell-only E2EUIFixtureLive markup alone does not establish operational standalone coverage.

No new dependency, required CI service/job, or paid judge is authorized. Reuse the existing economical lanes; preserve the current dirty baseline and retained preview at :4012. Mutation fixtures, databases, networks and volumes belong to disposable verification projects.

## Manual-Only Verifications

No routine human UAT is planned. Executors inspect representative before/after desktop/mobile images against the approved UI contract and record findings alongside executable geometry/state/contrast proof. Image inspection supplements the automated checks and does not replace them.

## Validation Sign-Off

- [x] Actual plan/task IDs, commands, and observed passing evidence are mapped for all 11 tasks.
- [x] Every task has automated verification and its stated failing direction, or an earlier task creates the missing harness.
- [x] Every task has planned automated feedback; no watch-mode commands.
- [x] Timestamp normalization, failed-check stability, and standalone/mounted clipboard paths have passing source-to-render proof.
- [x] All 26 approved UI considerations are lifted into plan must_haves.truths; all seven requirements are covered without backstop-only acceptance.
- [x] Focused checks, full root core gate, Ops gates, contrast, and disposable browser runs passed.

**Planning review:** Independent plan checker passed 2026-10-06 after one revision; see 173-PLAN-CHECK.md. This execution audit found zero uncovered requirement/task paths. No human-only UAT is pending.

## Validation Audit 2026-10-10

| Metric | Count |
|---|---|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

## Final-source adversarial coverage audit 2026-10-12

**Source SHA:** `1174a53f87d73c4e658029866a49c41d345452d9` (`fix(ops): keep source errors accurate and private`). The source delta changes the generic fetch-error explanation and updates its regression assertions; the current-source regression set also checks queue-error sanitization and response-body redaction. The commit does not change theme handling, timestamp normalization/rendering, clipboard behavior, or the browser runner.

### Tests run at the exact source SHA

| Suite | Result | Behavioral coverage relevant to the audit |
| --- | --- | --- |
| `bash examples/scrypath_ecommerce/scripts/verify-phase173.sh status` | **6/6 passed** across mounted and standalone entrypoints | Sanitized unavailable and queue-error copy; no fixture/internal error detail leakage; 14px recovery guidance; two readable retained-evidence columns at 390px; failed/healthy/disabled refresh transitions, busy/focus/press states, retry guidance, and no false success. Disposable runner cleanup passed. |
| `bash examples/scrypath_ecommerce/scripts/verify-phase173.sh shell` | **14/14 passed** across mounted and standalone entrypoints | System/light/dark preference, keyboard/pointer selection, OS changes, reload/navigation, cross-tab synchronization, denied/throwing storage, and responsive shell behavior. Disposable runner cleanup passed. |
| `cd scrypath_ops && mix test test/scrypath_ops_web/live/posture_live_test.exs` | **17/17 passed** | Generic backend and queue errors remain sanitized; an HTTP 503 response body containing a private credential is not rendered; retained evidence and exact timestamp source behavior remain covered. |

The browser counts are suite totals across both entrypoints, not a count per entrypoint. The 14px assertion is against the unavailable-reason paragraph; it is not a claim that every UI text role was measured in this run.

### Requirement and task comparison

| Requirement | Current or preserved executable evidence | Coverage decision |
| --- | --- | --- |
| OPUX-09 | Exact-source shell suite 14/14; earlier 10-case Ops shell contract and contrast receipt remain recorded above. | **Covered.** Current browser run exercises the mounted and standalone responsive shells. |
| OPUX-10 | Exact-source status suite 6/6 and PostureLive 17/17. | **Covered.** Neutral containers, local state cues, partial retained data, and safe failure copy are exercised. |
| OPUX-11 | Exact-source status suite 6/6 and PostureLive 17/17. | **Covered.** Zero, unavailable, unknown queue, unused queue, empty, and partial states remain distinguishable. |
| OPUX-12 | Exact-source shell suite 14/14. | **Covered.** Theme preference and storage-denial behavior run through both entrypoints. |
| OPUX-13 | Exact-source status suite 6/6 and PostureLive 17/17; existing design-token contract receipt remains in the task history. | **Covered.** Refresh affordance states, keyboard focus, reduced motion, server eligibility after patches, and retry behavior are exercised. |
| OPUX-14 | Exact-source PostureLive suite 17/17; `time` browser suite (8 cases) and root core gate (660 tests + 4 properties) retain their earlier exact-source receipts at `012649917e6dd0cf82dbb7d0154ccd37ac45bc43`. | **Covered, with carried-forward browser/core receipts.** The 1174 commit does not modify timestamp source, snapshot, disclosure, or root core code. The 8-case browser suite and root core gate were not rerun at 1174. |
| OPUX-15 | Exact-source PostureLive suite 17/17; `copy` browser suite (10 cases) and Ops/root Ops gates retain their earlier receipts at `b12a7c47157b4fb88b05237b7e2525d11896fd59` and prior listed SHAs. | **Covered, with carried-forward browser receipt.** The 1174 commit does not modify the clipboard hook or copy UI. The 10-case copy suite was not rerun at 1174. |

The 11 task paths remain accounted for: 173-01-T1/T2/T3 are backed by the shell contract/smoke receipts plus the exact-source dual-entrypoint shell run; 173-02-T1/T2 by PostureLive and root status unit receipts, and 173-02-T3 by the preserved time/core receipts; 173-03-T1/T2/T3 by the exact-source PostureLive/status suites plus the preserved token/contrast receipts; 173-04-T1/T2 by the preserved dual-entrypoint copy suite and exact-source PostureLive suite. Thus the final-source run refreshes the behavior touched by 1174 while the unaffected time/copy gates remain explicitly historical rather than being represented as rerun.

**Gap result:** 0 uncovered requirements; 0 escalations. No test was weakened and no new dependency was introduced. The unchanged time, copy, core, contrast, and full Ops checks are not reported as executed at `1174a53f`.
