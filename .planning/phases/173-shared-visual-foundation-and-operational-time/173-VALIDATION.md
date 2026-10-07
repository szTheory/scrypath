---
phase: "173"
slug: "shared-visual-foundation-and-operational-time"
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-10-06"
---

# Phase 173 — Validation Strategy

Execution validation: all seven requirements have behavior-targeted automated coverage. The four existing browser specs passed together (28 cases, no failures/errors/skips) on `185832d6c863b1c84c863e1f5f4e9e2c44dbfc18`; full Ops passed 244 tests plus two doctests. Independent phase verification and exact final-SHA hosted closeout are separate required steps.

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
| Browser gate | Planned `bash examples/scrypath_ecommerce/scripts/verify-phase173.sh {shell\|time\|status\|copy}` creates and cleans an isolated mounted+standalone Compose stack; 173-01-T2 creates test-only routes into production PostureLive, paired deterministic app-local test-support Phase173FixtureSource providers, runner and asset readiness checks; 173-01-T3 wires the first spec and docker-playwright.sh scope, and later browser tasks wire their own scopes. Existing `make -C examples/scrypath_ecommerce verify-e2e` remains advisory. |
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
| OPUX-09 | 173-01-T1/T2/T3 | `cd scrypath_ops && mix test test/scrypath_ops_web/ops_shell_contract_test.exs`; `make -C examples/scrypath_ecommerce contrast`; `bash examples/scrypath_ecommerce/scripts/verify-phase173.sh shell` — both test-only routes mount production PostureLive with entrypoint-specific built Ops assets; flat computed shell in light/dark/System at 390/1279/1280/1440, scroll-edge cues, inspected before/after images. |
| OPUX-10 | 173-03-T1/T2/T3 | `cd scrypath_ops && mix test test/scrypath_ops_web/live/posture_live_test.exs`; `bash examples/scrypath_ecommerce/scripts/verify-phase173.sh status` — deterministic backend/queue failure inputs pass through production PostureLive/Posture/Status/State/OpsUi on both routes; degraded/failed/unknown labels and local icons appear on neutral containers, including partial retained data. |
| OPUX-11 | 173-03-T1/T2/T3 | Same focused Ops/`status` runner — neutral zero, distinct nonzero/unavailable, unchanged Posture classification and no freshness copy. |
| OPUX-12 | 173-01-T1/T2/T3 | `bash examples/scrypath_ecommerce/scripts/verify-phase173.sh shell` — pointer/keyboard native preference, one visual/ARIA selection, OS System transition, reload/navigation/patch/tabs and blocked/invalid storage in both entrypoints. |
| OPUX-13 | 173-03-T2/T3 | Focused Ops contracts plus `bash examples/scrypath_ecommerce/scripts/verify-phase173.sh status` — hover/pressed/focus/selected/disabled/busy, nested label/icon, server eligibility across patches with reduced motion. |
| OPUX-14 | 173-02-T1/T2/T3 | `mix test test/scrypath/operator/status_test.exs`; `cd scrypath_ops && mix test test/scrypath_ops_web/live/posture_live_test.exs`; `bash examples/scrypath_ecommerce/scripts/verify-phase173.sh time && mix verify.core --exclude integration --exclude docs_contract` in T3 after T2's atomic core commit — threshold boundaries, microsecond future, source ISO/offset and fixed successful snapshot pass through production PostureLive/Posture/Status/State/OpsUi on both routes; browser exact disclosure and failed-refresh/absent/unavailable/unused cases fail when that render path or standalone asset is stale. |
| OPUX-15 | 173-04-T1/T2 | `bash examples/scrypath_ecommerce/scripts/verify-phase173.sh copy` plus focused Ops LiveView test — both production PostureLive routes supply source ISO to OpsUi and entrypoint-specific JS hook; resolved/rejected/missing promise outcomes, exact payload, four-second reset, persistent failure, selectable evidence, Checked no-copy in standalone and mounted. |

All commands above are execution targets, not results. The new fixture source, routes, runner, scope dispatch and specs must be created by the named tasks before use. The standalone and mounted browser proofs must assert a source-derived production PostureLive row/control and actual built Ops assets so duplicated fixture markup cannot satisfy them. Every task's `<verify>` has an automated command and an explicit nonzero/empty-suite failure condition; the full core gate also blocks on any nonzero result. Its workspace-clean check requires committed root source in a clean execution checkout; preserve the local dirty baseline rather than discarding it. Images are inspected by the executor in the same slice, with computed style, geometry and state assertions as executable proof. The Phase 173 runner must use a unique Compose project, no published host port for its standalone service, and cleanup volumes/network; preview :4012 is excluded.

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

173-01-T2 creates the isolated standalone service, paired app-local test-support fixture providers and test config, both routes into production PostureLive, fixed observation snapshot, and `--smoke` route/asset probe. The mounted host cannot use the Ops dependency's test/support module, so each app supplies its own provider behind the same private source contract; browser cases assert parity. 173-01-T3 wires the first browser spec and shell scope dispatch. The `time`, `status`, and `copy` specs and their docker-playwright.sh dispatch cases are then added by 173-02-T3, 173-03-T3, and 173-04-T1 respectively. No later task may invoke a scope before its spec exists. Existing Playwright infrastructure or shell-only E2EUIFixtureLive markup alone does not establish operational standalone coverage.

No new dependency, required CI service/job, or paid judge is authorized. Reuse the existing economical lanes; preserve the current dirty baseline and retained preview at :4012. Mutation fixtures, databases, networks and volumes belong to disposable verification projects.

## Manual-Only Verifications

No routine human UAT is planned. Executors inspect representative before/after desktop/mobile images against the approved UI contract and record findings alongside executable geometry/state/contrast proof. Image inspection supplements the automated checks and does not replace them.

## Validation Sign-Off

- [x] Actual plan/task IDs and proposed executable commands replace the preliminary map; commands remain unrun.
- [x] Every task has automated verification and its stated failing direction, or an earlier task creates the missing harness.
- [x] Every task has planned automated feedback; no watch-mode commands.
- [x] Timestamp normalization, failed-check stability and standalone/mounted clipboard paths have explicit planned source-to-render proof; execution remains pending.
- [x] All 26 approved UI considerations are lifted individually into plan must_haves.truths and OPUX-09–OPUX-15 are mapped without backstop-only acceptance; product verification remains pending.
- [x] Focused checks are targets; full root core gate and browser startup are explicitly unmeasured slower gates.

**Planning review:** Independent plan checker passed 2026-10-06 after one revision; see 173-PLAN-CHECK.md. No maintainer approval or product-test pass is inferred. Draft/Nyquist execution status remains unchanged.

## Execution Coverage Audit

| Requirement | Status | Actual coverage |
| --- | --- | --- |
| OPUX-09 | COVERED | Shell spec: computed flat neutral chrome, both routes/themes and responsive widths; palette regression in status spec. |
| OPUX-10 | COVERED | Status spec: connected production rows across nine failure/partial/unavailable/configuration scenarios; Ops LiveView assertions. |
| OPUX-11 | COVERED | Status spec and component tests: zero/nonzero/unavailable distinction and neutral zero counts. |
| OPUX-12 | COVERED | Shell spec: keyboard, pointer, System OS changes, navigation/reload/patch, cross-tab and denied/invalid storage. |
| OPUX-13 | COVERED | Status spec: busy icon/label, independent focus and neutral press, actual server eligibility change after refresh. |
| OPUX-14 | COVERED | Core status tests and Ops tests: precision/boundaries/absence; time spec: exact ISO and retained snapshot age after real failed refresh. |
| OPUX-15 | COVERED | Copy spec: awaited outcomes, out-of-order writes, failure fallback, repeated timer, keyboard/touch, no Checked copy, composed text contrast and 40px targets in all preferences. |

All 11 planned tasks have their mapped automated commands and executed coverage. The combined proof covers all four specs on one committed source; the earlier required root core gate passed 659 tests plus four properties and no later core source change occurred. Baseline artifact limits and the missing intentional RED history in 173-01 remain honestly recorded in its summary; no retroactive RED history or human approval is inferred. Evidence: `/private/tmp/scrypath-phase173-20261006-155750/evidence/173-final/`; native report `phase173-all.xml`. No validation gap or manual-only acceptance remains.

## Validation Audit 2026-10-07

| Metric | Count |
|---|---|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |
