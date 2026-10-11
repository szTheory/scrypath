---
phase: "173"
slug: "shared-visual-foundation-and-operational-time"
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-10-06"
---

# Phase 173 — Validation Strategy

Planning validation is separate from product verification. Phase 173 implementation now has passing executable evidence for OPUX-09–OPUX-15. The independent plan checker passed after one revision; all 11 task verification paths and all seven requirement rows were rechecked against their completed summaries and current-source gates. No validation gaps remain; routine human UAT is not required.

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
| OPUX-09 | 173-01-T1/T2/T3 | **COVERED.** Shell contract (10 tests), disposable production-route/asset smoke, `shell` browser suite (11 tests), and contrast (0 AA failures) passed. Both entrypoints, light/dark/System, responsive widths, theme state, flat shell, and scroll cues are covered; before/after images were inspected. |
| OPUX-10 | 173-03-T1/T2/T3 | **COVERED.** Focused Ops suite (31 tests) and `status` browser suite (6 tests) passed. Production LiveViews cover neutral containers, explicit degraded/failed/unknown cues, and partial retained data. |
| OPUX-11 | 173-03-T1/T2/T3 | **COVERED.** Same current-source Ops and `status` suites passed; neutral zero, nonzero/unavailable distinctions, queue-unused, and no freshness implication are asserted. |
| OPUX-12 | 173-01-T1/T2/T3 | **COVERED.** Shell contract and `shell` browser suite (11 tests) passed, including pointer/keyboard preference, one visual/ARIA selection, System appearance, reload/navigation/tabs, and storage failure cases. |
| OPUX-13 | 173-03-T2/T3 | **COVERED.** Focused Ops contracts and `status` browser suite (6 tests) passed for hover/press/focus/selected/disabled/busy, retained labels/icons, reduced motion, and server eligibility after patches. |
| OPUX-14 | 173-02-T1/T2/T3 | **COVERED.** Root status tests (6), focused PostureLive tests (11), `time` browser suite (8), and `mix verify.core --exclude integration --exclude docs_contract` (660 tests + 4 properties) passed. Boundary/precision/future cases, fixed observation snapshot, exact ISO/UTC disclosure, and absent/unavailable/unused states are asserted in both entrypoints. |
| OPUX-15 | 173-04-T1/T2 | **COVERED.** Current-source `copy` browser suite (10 tests), focused LiveView/shell tests, full Ops suites (244 tests + 2 doctests), and tagged accessibility suite (4 tests) passed. Exact source payload, awaited result, four-second reset, persistent rejection/unavailable guidance, selection, Checked no-copy, keyboard/touch, and failed-refresh age are covered. |

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

No Phase 173 SPEC exists. The deterministic edge probe in `/tmp/scrypath-173-edge-coverage.json` reported 10 rows: four `unclassified` and six classified. The four unclassified rows remain **flagged assumptions**, not silent passes: OPUX-09 assumes existing shell semantics at every changed breakpoint (173-01-T3); OPUX-11 assumes zero and unavailable remain distinct under partial observation (173-03-T1/T3); OPUX-12 assumes current-page preference remains usable under storage policy denial (173-01-T1/T3); OPUX-15 assumes Clipboard API rejection and absence can be induced in both bundles (173-04-T2). Executors record actual outcomes; an unmet assumption requires plan revision.

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
