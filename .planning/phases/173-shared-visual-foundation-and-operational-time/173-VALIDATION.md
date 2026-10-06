---
phase: "173"
slug: "shared-visual-foundation-and-operational-time"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-06"
---

# Phase 173 — Validation Strategy

Planning validation is separate from product verification. Requirements OPUX-09–OPUX-15 remain pending until implementation has executable evidence. The planner must replace the preliminary requirement map below with actual plan/task IDs and concrete runner commands before the plan checker passes.

## Test Infrastructure

| Property | Value |
| --- | --- |
| Framework | Existing root/Ops ExUnit suites, token contrast checker, ecommerce Playwright |
| Configuration | Root and Ops mix.exs; ecommerce package.json, playwright.config.ts and existing Docker orchestration |
| Quick Ops command, from root | `cd scrypath_ops && mix test test/scrypath_ops_web/design_tokens_contract_test.exs test/scrypath_ops_web/ops_shell_contract_test.exs test/scrypath_ops_web/live/posture_live_test.exs` |
| Root timestamp command | `mix test test/scrypath/operator/status_test.exs` |
| Static contrast command | `make -C examples/scrypath_ecommerce contrast` |
| Full Ops gate | `mix verify.ops_ui` from repository root; Ops `mix precommit` when implementation is complete |
| Mounted gate | `make -C examples/scrypath_ecommerce verify-mounted` |
| Browser gate | Existing full advisory `make -C examples/scrypath_ecommerce verify-e2e`; planner must bind focused standalone/mounted phase proof to a disposable runner |
| Runtime | Not measured in this planning run; fast checks target under 120 seconds, browser gates reported separately |

## Sampling Rate

- After each task, run the focused test/contrast command named by that task, with an observable nonzero-exit or empty-suite failure condition.
- After each wave, run `mix verify.ops_ui` and that wave's focused browser proof on disposable fixtures.
- Before phase verification, all per-requirement obligations and applicable CONTRIBUTING.md gates must have current-source evidence.
- Feedback target: under 120 seconds for focused checks. Slow disposable browser startup is a separate bounded wave gate; do not claim an unmeasured runtime.
- Run root and Ops test paths from their own Mix projects. Do not pass `scrypath_ops/test/...` to root `mix test`.

## Preliminary Per-Requirement Verification Map

| Requirement | Behavior | Test type | Automated command / planned evidence |
| --- | --- | --- | --- |
| OPUX-09 | Flat shell in light/dark/System, mobile and 1279/1280 layouts; scroll-edge cues preserved | Token/component/browser | Static contrast and focused shell tests; browser computed styles, no overflow, before/after images |
| OPUX-10 | Neutral summary/schema surfaces with explicit local degraded/failed/unknown cues | Component/LiveView/browser | Posture and shell tests plus rendered status fixtures |
| OPUX-11 | Neutral zero-error counts; nonzero/unavailable remain distinct; no freshness assertion | Component/LiveView | Posture tests covering zero/nonzero/unavailable and unchanged classification |
| OPUX-12 | One native preference selection agreeing with aria-pressed; appearance, storage, navigation and tabs | Browser | Phase cases for System OS transitions, reload, cross-tab, invalid/blocked storage, patches and both entrypoints |
| OPUX-13 | Quiet action state matrix; focus and eligibility; icon/label retained when busy | Component/LiveView/browser | Shared action tests plus browser keyboard/pointer/reduced-motion patch transitions |
| OPUX-14 | Snapshot-relative thresholds; source precision/offset; accessible selectable exact evidence | Root unit/Ops/browser | Root status and Ops time/Posture fixtures for boundaries, future/absent/unavailable, failed checks, unrelated rerenders |
| OPUX-15 | Full ISO payload; confirmation after resolved write only; repeated copy; persistent rejection/unavailable; Checked no-copy | Browser/component | Deferred/resolved/rejected/missing clipboard stubs, exact selection and keyboard/pointer proof in standalone and mounted Ops |

## Wave 0 Requirements

The planner must assign creation/extension of missing timestamp component/unit cases and any focused disposable standalone browser fixture/runner before dependent tests run. Existing Playwright infrastructure alone does not establish standalone coverage. Do not use nonexistent test scripts or invent a runnable path; list its creating task first.

No new dependency, required CI service/job, or paid judge is authorized. Reuse the existing economical lanes; preserve the current dirty baseline and retained preview at :4012. Mutation fixtures, databases, networks and volumes belong to disposable verification projects.

## Manual-Only Verifications

No routine human UAT is planned. Executors inspect representative before/after desktop/mobile images against the approved UI contract and record findings alongside executable geometry/state/contrast proof. Image inspection supplements the automated checks and does not replace them.

## Validation Sign-Off

- [ ] Actual plan/task IDs and executable commands replace the preliminary map.
- [ ] Every task has automated verification and its stated failing direction, or an earlier task creates the missing harness.
- [ ] No three consecutive tasks lack automated feedback; no watch-mode commands.
- [ ] Timestamp normalization, failed-check stability and standalone/mounted clipboard paths have explicit proof.
- [ ] All 26 approved UI considerations and OPUX-09–OPUX-15 are covered without backstop-only acceptance.
- [ ] Runtime claims are measured or explicitly estimates.

**Approval:** Pending independent plan-checker review; no maintainer approval or product-test pass is inferred.
