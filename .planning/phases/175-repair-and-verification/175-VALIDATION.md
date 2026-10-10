---
phase: "175"
slug: "repair-and-verification"
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-10-10"
---

# Phase 175 — Validation Strategy

Audit of six plans and twelve tasks. Current Ops proof: 334 tests and 2 doctests, zero failures. Expanded browser proof: seven cases, zero failures/skips/retries. Exact-final-SHA hosted closeout remains pending. The callback runtime gap found during security review is resolved and independently rechecked; the final requirement verdict and hosted closeout remain pending.

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
| 175-01-T1 | 175-01 | 1 | OPUX-20 | T-175-01 | Rendered non-first selector/URL, scoped observations, read-only check | LiveView | `cd scrypath_ops && mix test test/scrypath_ops_web/live/sync_drift_live_test.exs` | Yes; extend | Green |
| 175-01-T2 | 175-01 | 1 | OPUX-20 | T-175-02 | Complete zero versus partial/error and independent config read | LiveView | `cd scrypath_ops && mix test test/scrypath_ops_web/live/sync_drift_live_test.exs` | Yes; extend | Green |
| 175-02-T1 | 175-02 | 2 | OPUX-20, OPUX-21, OPUX-22 | T-175-03, T-175-04 | Exact retry job/attempt/task and active-index upsert | LiveView/correlation | `cd scrypath_ops && mix test test/scrypath_ops_web/live/sync_drift_live_test.exs test/scrypath_ops/recovery_observation_test.exs` | Yes; extend | Green |
| 175-02-T2 | 175-02 | 2 | OPUX-21, OPUX-22 | T-175-03, T-175-04, T-175-05 | Delete absence, expired/superseded/wrong-runtime unknown | LiveView/correlation | `cd scrypath_ops && mix test test/scrypath_ops_web/live/sync_drift_live_test.exs test/scrypath_ops/recovery_observation_test.exs test/scrypath_ops/document_observation_test.exs` | Yes | Green: current-runtime success/exit regression passed |
| 175-03-T1 | 175-03 | 3 | OPUX-21, OPUX-22 | T-175-06, T-175-08 | Same-UID GET, enqueued versus processing, no second POST | LiveView | `cd scrypath_ops && mix test test/scrypath_ops_web/live/sync_drift_live_test.exs` | Yes; extend | Green |
| 175-03-T2 | 175-03 | 3 | OPUX-21, OPUX-22 | T-175-06, T-175-07, T-175-08 | Terminal/malformed/timeout and stale success/error callbacks | LiveView | `cd scrypath_ops && mix test test/scrypath_ops_web/live/sync_drift_live_test.exs` | Yes; extend | Green |
| 175-04-T1 | 175-04 | 4 | OPUX-20, OPUX-22 | T-175-09, T-175-10 | Rendered exact-pair confirmation, host gate, fresh prerequisites | LiveView | `cd scrypath_ops && mix test test/scrypath_ops_web/live/sync_drift_live_test.exs` | Yes; extend | Green |
| 175-04-T2 | 175-04 | 4 | OPUX-22 | T-175-09, T-175-10, T-175-11 | Retained blocker, double submit, auth/cancel and disclosure | LiveView/eligibility | `cd scrypath_ops && mix test test/scrypath_ops_web/live/sync_drift_live_test.exs test/scrypath_ops/promotion_eligibility_test.exs` | Yes; extend | Green |
| 175-05-T1 | 175-05 | 5 | OPUX-20, OPUX-21, OPUX-22 | T-175-12, T-175-13 | Test-only standalone real view and exact fake task | LiveView fixture | `cd scrypath_ops && mix test test/scrypath_ops_web/live/phase175_fixture_live_test.exs` | New in this task | Green |
| 175-05-T2 | 175-05 | 5 | OPUX-20, OPUX-21, OPUX-22 | T-175-12, T-175-13 | Isolated adverse standalone scenarios through rendered controls | LiveView fixture | `cd scrypath_ops && mix test test/scrypath_ops_web/live/phase175_fixture_live_test.exs test/scrypath_ops_web/live/sync_drift_live_test.exs` | New in T1; extend | Green |
| 175-06-T1 | 175-06 | 6 | OPUX-20, OPUX-21, OPUX-22 | T-175-14, T-175-16 | Owned mounted swap exact UID/pair/document plus standalone check | Playwright/Compose | `bash examples/scrypath_ecommerce/scripts/verify-phase175.sh repair` | New in this task | Green |
| 175-06-T2 | 175-06 | 6 | OPUX-20, OPUX-21, OPUX-22 | T-175-14, T-175-15, T-175-16 | Full state/visual matrix, owned cleanup and exact source | Playwright/Compose/Ops | `bash examples/scrypath_ecommerce/scripts/verify-phase175.sh repair`; `mix verify.ops_ui`; `make -C examples/scrypath_ecommerce contrast` | New in T1; extend | Green |

Each `<automated>` in the plans is immediately followed by a `<fails_when>` covering nonzero exit and the relevant zero-case or absent artifact. The Plan 06 final task additionally runs `cd scrypath_ops && mix assets.build` and `cd scrypath_ops && mix precommit` with their own failure signals. Commands name existing files or files created by the same preceding task; no test command is run in planning.

## Wave and Security Gate Map

| Wave | Plan | Before advancing | Threat refs |
|------|------|------------------|-------------|
| 1 | 175-01 | Rendered selected-schema, complete/partial and config checks green | T-175-01–02 |
| 2 | 175-02 | Exact recovery upsert/delete and unknown correlation green | T-175-03–05 |
| 3 | 175-03 | Same-UID read-only task lifecycle and stale-callback cases green | T-175-06–08 |
| 4 | 175-04 | Rendered host gate, exact-pair confirmation and retained blockers green | T-175-09–11 |
| 5 | 175-05 | Test-only standalone fixture route and no-leak cases green | T-175-12–13 |
| 6 | 175-06 | Owned mounted/standalone browser, visual and canonical Ops gates green; exact-SHA hosted evidence then required before closeout | T-175-14–16 |

Every plan includes reserved T-175-SC. No npm/pip/cargo install task exists, so the package-legitimacy install checkpoint does not activate. Security enforcement is ASVS level 1, blocking high-severity threats until their named tests/evidence pass. The runner may mutate only its uniquely named disposable Compose project; previews :4012/:4014, the original dirty checkout, frozen Phase 173 source and unrelated resources remain outside its ownership.

## Multi-Source Coverage Audit

| Source | Items | Plan coverage | Status |
|--------|-------|---------------|--------|
| ROADMAP goal and three success criteria | Safe supported repair/promotion; separate config/freshness and observation/mutation; exact accepted/running/terminal/unknown evidence | 175-01–04 behavior, 175-05–06 dual-entrypoint proof | Executed locally |
| REQUIREMENTS | OPUX-20 | 175-01, 175-02, 175-04, 175-05, 175-06 | Executed locally |
| REQUIREMENTS | OPUX-21 | 175-02, 175-03, 175-05, 175-06 | Executed locally |
| REQUIREMENTS | OPUX-22 | 175-02, 175-03, 175-04, 175-05, 175-06 | Executed locally |
| CONTEXT | D-01–D-02 accepted audit, current components and design | 175-01, 175-04, 175-06 | Executed locally |
| CONTEXT | D-03–D-08 selection, ordinary hierarchy, distinct reads and restrained diagnostics | 175-01, 175-02 | Executed locally |
| CONTEXT | D-09–D-11 retry task/document correlation and unknown protection | 175-02, 175-03 | Executed locally |
| CONTEXT | D-12 same-UID promotion task lifecycle | 175-03, 175-05, 175-06 | Executed locally |
| CONTEXT | D-13–D-16 advanced disclosure, eligibility, confirmation and pinned swap copy | 175-04, 175-06 | Executed locally |
| CONTEXT | D-17–D-20 standalone/mounted, visual, exact-source and PR-first boundaries | 175-05, 175-06 | Executed locally |
| RESEARCH | Existing configured client/TaskPayload, receipt/document modules, PromotionEligibility/Gating, native details, pinned Meilisearch swap, no new dependency | 175-02–05 | Executed locally |
| UI-SPEC | Eight grouped empty/loading/error/populated/partial/overflow/zero-one-many/long-text truths, all 68 E1–E10/category pairs | 175-06 plain `must_haves.truths`, with behavior built in 175-01–05 | Executed locally |

Deferred broad brand/core/backend/auth work, automatic retry/reindex/backfill, durable receipt service, generalized freshness scan, new required CI service, paid judge, Search/Playbooks phase scope and merge/release authority are excluded by CONTEXT and ROADMAP, rather than missing plan items.

## Spec-Less Probe and Assumption Disposition

No plain 175-SPEC.md supplied `## Edge Coverage` or `## Prohibitions`. The deterministic edge fallback report at `/private/tmp/scrypath-phase173-20261006-155750/phase175-edge-probe.json` has exactly three rows: OPUX-20, OPUX-21 and OPUX-22 are each `unclassified`, `unresolved`, with no verification/resolution. They remain three explicit flagged planner assumptions in Plans 01, 03 and 04, respectively. No row was auto-resolved, dismissed, or converted to a backstop truth. The plans separately author grounded observable acceptance from ROADMAP, CONTEXT, RESEARCH and UI-SPEC.

Prohibition recall asked of each requirement what the feature could silently become against the author's product/safety intent. Stage 1 considered misleading freshness, implicit mutation, scope substitution, queue acceptance as completion, unrelated task evidence, observer error as remote failure, browser-only gate, auth replay, inaccurate swap effect, stale callbacks and routine validation/test hygiene. Precision dropped ordinary correctness items that are covered by the edge/behavior and STRIDE checks. The six surviving bespoke safety/transparency statements are projected via the installed `projectProhibitions` serializer into Plans 01/03/04 as descriptor-less `must_haves.prohibitions`, two per requirement, each `status: unresolved`. Calling the installed `dispositionForProhibition` on these projections returns `{status: unverified, flagged: true}` without enforcement evidence; no `check_*` descriptor is fabricated. Canonical injection, authorization, session and transport threats are instead referred to the per-plan STRIDE register and `$gsd-secure-phase`, not minted as bespoke prohibitions. These flags remain review-visible at verification and are not a runtime pass or human approval.

The assumption-delta detector returned `detected: true` solely for `chosen` term `choose` in the ROADMAP goal. Decision: `no-change`; the primary identity stays the current allowlisted schema plus exact receipt/task and runtime context. “Choose” describes an operator action between existing ordinary and advanced workflows, not a transition from derived identity to user-configurable primary key. The API coverage detector run over ROADMAP Phase 175 plus all six plans returned `detected: false`; this phase consumes an existing Meilisearch client seam and does not add an external API integration, so COVERAGE.md is not required by that detector. The schema-push scan found no modified Payload/Prisma/Drizzle/Supabase/TypeORM schema path; no schema push is planned. These are detector dispositions, not an extension of product scope.

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

## Execution Audit Evidence

- Focused Nyquist pass: 93 tests, zero failures at `724c5ac`. Expanded browser fixes found and repaired a connected authorization-return path defect; focused regression: 19 tests, zero failures.
- Current full Ops run: `/private/tmp/scrypath-phase173-20261006-155750/evidence/phase175/post-audit-ops.log` — 333 tests + 2 doctests, zero failures.
- Expanded browser receipt: `evidence/phase175/post-audit-final/` under the same external parent directory — seven cases, zero failures/skips/retries; exact upsert and delete receipt/job/attempt/task/document probes, double submit, changed prerequisite, standalone sudo return, same-UID recheck, UI states, System Light/Dark and reduced motion. Cleanup status zero. Earlier failed attempts remain retained in `nyquist-final/`.
- No required manual-only verification was introduced. Source-before/source-after composition screenshots remain absent and nonblocking; interaction screenshots are labeled honestly. The 68 UI pairs receive grouped assertions and source-owned component checks rather than 68 separate browser cases; independent UI/goal verification must assess that coverage.
- Potential remaining gap: recovery success/error callbacks check generation/handle/allowlist, but the current endpoint/runtime may change after the observation begins. Security must confirm and close this branch before `nyquist_compliant` or `wave_0_complete` changes.

## Validation Audit 2026-10-10

| Metric | Count |
|---|---|
| Gaps found | 7 |
| Resolved | 6 |
| Escalated | 1 |

## Security Followup Validation

Commit `22089e9513a14d38a252e6dc59530b6d3698ef1d` captures recovery runtime identity and rejects callbacks after endpoint, Oban instance, repo, prefix or node changes on success and exit. The intended RED failed on stale endpoint verification; GREEN ran 52 focused tests, zero failures. The security auditor rechecked both T-175-05 and T-175-07 as closed. Canonical Ops: 334 tests + 2 doctests, zero failures (`security-fix-ops.log`). Browser at that exact committed source: seven cases, zero failures/skips/retries, cleanup zero (`security-fix-final/`). The original planning assumption/prohibition descriptors remain review-visible and await independent verifier disposition; no descriptor or human approval is fabricated.

## Validation Audit 2026-10-10

| Metric | Count |
|---|---|
| Gaps found | 7 |
| Resolved | 7 |
| Escalated | 0 |
