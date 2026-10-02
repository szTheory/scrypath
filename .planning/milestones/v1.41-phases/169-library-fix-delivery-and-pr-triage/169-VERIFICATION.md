---
phase: 169-library-fix-delivery-and-pr-triage
verified: 2026-10-02T11:38:40.416Z
status: passed
score: 41/41 must-haves verified
covered_files:
  - .planning/PROJECT.md
  - .planning/milestones/v1.41-REQUIREMENTS.md
  - .planning/milestones/v1.41-ROADMAP.md
  - .planning/STATE.md
  - .planning/milestones/v1.41-phases/169-library-fix-delivery-and-pr-triage/169-01-PLAN.md
  - .planning/milestones/v1.41-phases/169-library-fix-delivery-and-pr-triage/169-01-SUMMARY.md
  - .planning/milestones/v1.41-phases/169-library-fix-delivery-and-pr-triage/169-02-PLAN.md
  - .planning/milestones/v1.41-phases/169-library-fix-delivery-and-pr-triage/169-02-SUMMARY.md
  - .planning/milestones/v1.41-phases/169-library-fix-delivery-and-pr-triage/169-03-PLAN.md
  - .planning/milestones/v1.41-phases/169-library-fix-delivery-and-pr-triage/169-03-SUMMARY.md
  - .planning/milestones/v1.41-phases/169-library-fix-delivery-and-pr-triage/169-04-PLAN.md
  - .planning/milestones/v1.41-phases/169-library-fix-delivery-and-pr-triage/169-04-SUMMARY.md
  - .planning/milestones/v1.41-phases/169-library-fix-delivery-and-pr-triage/169-05-PLAN.md
  - .planning/milestones/v1.41-phases/169-library-fix-delivery-and-pr-triage/169-05-SUMMARY.md
  - examples/phoenix_meilisearch/priv/repo/migrations/20260927000000_add_host_memberships_and_post_tenants.exs
  - examples/phoenix_meilisearch/test/smoke/meilisearch_oban_stack_test.exs
  - examples/phoenix_meilisearch/test/smoke/meilisearch_related_inline_stack_test.exs
  - examples/phoenix_meilisearch/test/smoke/meilisearch_related_oban_stack_test.exs
  - examples/phoenix_meilisearch/test/smoke/meilisearch_stack_test.exs
  - examples/phoenix_meilisearch/test/support/meilisearch_test_index.ex
  - lib/scrypath/meilisearch/client.ex
  - lib/scrypath/meilisearch/query.ex
  - lib/scrypath/search/facet_values.ex
  - lib/scrypath/search/many.ex
  - lib/scrypath/search/single.ex
  - test/scrypath/live_operator_verification_test.exs
  - test/scrypath/search_within_facet_test.exs
  - test/scrypath/tenant_scope_contract_test.exs
covered_digest: "v1:sha256:3da3e68da65d489bf4e3f794925e9a71c2d25614fac95bc25f5d5908909a240f"
behavior_unverified: 0
overrides_applied: 1
overrides:
  - must_have: "The coherent tenant/facet runtime, regression, host and repair slice reaches public main through an actually reviewed PR and ordinary protections."
    reason: "The user explicitly authorized the normal squash merge after CI was green. The PR was merged through ordinary protections with passing required checks; no GitHub review occurred and none is claimed. This accepts the workflow deviation only; it does not assert that the review condition happened."
    accepted_by: "user"
    accepted_at: "2026-09-29"
---

# Phase 169: Library Fix Delivery and PR Triage Verification Report

**Phase Goal:** The known public-contract corrections become available on verified public `main`, and a finite inventory accounts for remaining owned local work and dependency PRs.  
**Verified:** 2026-10-02T11:38:40.416Z  
**Status:** passed (one explicit workflow-deviation override)  
**Re-verification:** No — original verification refreshed for final tracking inputs; no prior gaps.

**Fingerprint refresh (2026-10-02):** Phase 169's verification is source-bound to PR #85 squash commit `933ad30645c41df9f21dd4ddfd2d5b93fbd48620` and exact-SHA run `36644133759`; these are the implementation and delivery evidence, not the shared workspace branch. The shared branch is at `c8e0d7df86f691534077146a18179ed663754840` and has six different local copies of files covered by that historical report. A read-only commit comparison of those six paths from `933ad30645c41df9f21dd4ddfd2d5b93fbd48620` to current public main `eb9233cfc60fa027f2fab5bccff00e46f9c7a69f` returned no diff, so the named public-main evidence remains applicable. The differing shared-branch copies are not used as verification inputs and were not changed. Phase 169 plans, summaries, requirements outcomes, and source-bound run receipts remain the basis for the original 41/41 review; no product tests were rerun.

**Planning-input fingerprint refresh (2026-10-02):** The authorized Phase 170 tracking reconciliation updated shared `.planning/PROJECT.md`, `ROADMAP.md`, and `STATE.md` after the preceding Phase 169 fingerprint refresh. Those control-plane edits do not change Phase 169 implementation paths, requirements, plan summaries, or its source-specific evidence. The covered-input digest is refreshed against their current bytes only; no Phase 169 tests, CI, or product checks were rerun.

## Goal Achievement

### Roadmap Success Criteria

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | Dated refreshed-main comparison identifies selected runtime, regression/adopter, documentation and planning changes; every owned remainder has a delivery path or evidence-backed disposition; accumulated local branch is not the delivery unit. | ✓ VERIFIED | Plans 01/05 preserve the refreshed-main baseline and dated 232-path ownership snapshot. The selector validator reported complete coverage (232 paths, 17 non-overlapping selectors). Plan 05 gives source-linked dispositions; delivery used the isolated PR candidate. |
| 2 | Tenant-option and facet keyword-filter corrections with coherent regression/adopter/repair proof are merged and verified on `main`; historical evidence is source-compared; candidate, merge-ref and squash-main receipts remain distinct. | ✓ VERIFIED | PR #85 merged at `933ad30645c41df9f21dd4ddfd2d5b93fbd48620`. Candidate `46331b…`, merge ref `dbe9d0…`, and squash commit have separate identities; all resolve to tree `48605fa22efafd8c37ad563ea84949a1fdf05988`. GitHub blobs confirmed the corrected facet/client/query/single/many library files at that SHA. Named host/path/package/repair receipts exist; post-merge run `36644133759` succeeded on the exact SHA. |
| 3 | Each PR in the phase-start cohort has a keep/update/close/defer disposition, current evidence and revisit trigger where relevant; selected heads/bases are refreshed before action; routine arrivals do not expand scope automatically. | ✓ VERIFIED | Plan 05 has exactly ten rows: #65 and #68–#76. Each records observed state, full head/base SHAs, checks, rationale, disposition, action state and trigger. Current refresh and structure validation passed. Unauthorized actions remain explicitly pending. |
| 4 | Normal patch rationale is recorded for Phase 170; selected unmerged code blocks delivery unless scope changes; planning archives and low-value churn do not block unrelated fixes. | ✓ VERIFIED | Plan 05 records the existing Release Please patch-train rationale and hands publication/readiness to Phase 170. `published_package: none`; selected code is merged. Zero archive import is reasoned, and unrelated state is preserved. |

**Roadmap score:** 4/4 success criteria verified.

### Plan Must-Have Ledger

The five plans contain 37 truths in addition to the four roadmap criteria. These were checked against all plans/summaries, source, GSD artifact/link probes, recorded test receipts, and exact-SHA GitHub records.

| Plan truth IDs | Status | Evidence |
|---|---|---|
| 169-01 T1–T8 | ✓ VERIFIED | Refreshed-main base and Phase 168 source/lock comparisons are recorded. Request-tracer tests cover encoded tenant+keyword filters, all public search paths, validation/collisions and empty/default compatibility. Identity-aware path/blob comparison and order-independent inventory logic are present; recorded focused and fast suites passed. |
| 169-02 T1–T6 | ✓ VERIFIED | Public example source has persisted membership authorization before dispatch and tenant/published/returned-ID-bounded hydration. Tests assert positive controls and raw counts/facets separately. Recorded path and fresh local-package modes each passed 16 tests; smoke paths and graph/artifact identities are recorded. |
| 169-03 T1–T5 | ✓ VERIFIED | Repair proof uses an explicit Ecto selected-ID query and checks the returned task's terminal success before visibility. Tests cover no-action, source-only, already-visible, repeated-scope and empty-scope cases; recorded focused root/backend evidence passed. |
| 169-04 T1 | ✓ VERIFIED (override) | See “Review Workflow Deviation.” The PR merged with ordinary protections and required checks under explicit user authorization. GitHub reports empty `reviewDecision` and `reviews=[]`; no review is claimed. |
| 169-04 T2–T7 | ✓ VERIFIED | Candidate checks and named path/package/repair proof are source-linked; candidate, PR head/base/merge-ref, squash-main and package identities are distinct; exact-main post-merge workflow succeeded; source comparison and README reconciliation are recorded; Hex publication is not claimed. |
| 169-05 T1–T11 | ✓ VERIFIED | Dated path inventory and frozen ten-PR cohort exist. Rows retain independent evidence, missing evidence is not treated as success, row order does not define value, pending actions stay explicit, State links the standard owners, and patch handoff is separate from publication/readiness. Selector, cohort, handoff and #85 readback validators passed. |

**Score:** 41/41 truths verified, including one PASSED (override). **Behavior-unverified:** 0.

### Review Workflow Deviation

Plan 04's exact truth says the slice reaches public `main` “through an actually reviewed PR and ordinary protections.” GitHub confirms PR #85 was merged with an empty `reviewDecision` and zero reviews. The user explicitly authorized the normal squash path when CI was green (“yeah if it's ci green u can merge that's good for me.”). The accepted override records that workflow decision; it does not relabel the absent GitHub review as performed. Required checks passed and no admin bypass was used.

### Deferred Items

None. Pending close/update actions for selected cohort PRs are outside the authorization for PR #85 and remain recorded with revisit triggers. They do not make TRIAGE-01 incomplete: it requires evidence-based dispositions, not an empty inbox or execution of every disposition.

## Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `lib/scrypath/search/facet_values.ex` | strict runtime option partition | ✓ VERIFIED | Present/substantive; public-main blob matches local source. |
| `lib/scrypath/meilisearch/query.ex`, `client.ex`, `lib/scrypath/search/single.ex`, `many.ex` | common renderer and validated scope dispatch | ✓ VERIFIED | Present/substantive; key-link probes pass; corrected public blobs match. |
| Tenant-scope/facet contract tests | public composition and encoded-request regressions | ✓ VERIFIED | Present/substantive; recorded named test receipts passed. |
| Phoenix context/schema/migration/host and smoke tests/index helper | persisted fixture, host policy and selected consumer paths | ✓ VERIFIED | Present in public merge tree; public host source inspected. Named path/package receipts and exact-SHA CI cover the merged source. |
| Four existing Phoenix sync smoke tests | inline/Oban smoke paths | ✓ VERIFIED | Plan 02 receipts report all four passing with explicit primary-key setup. |
| `test/scrypath/live_operator_verification_test.exs` | bounded manual repair proof | ✓ VERIFIED | `selected_query` and `Tasks.wait_for_task` paths present; recorded focused repair evidence passed. |
| Phoenix README | bounded host-proof explanation | ✓ VERIFIED | Present/substantive; reconciliation is in candidate/main receipt. |
| Five plan/summary pairs and `.planning/STATE.md` | standard planning and handoff records | ✓ VERIFIED | Present/substantive; State points to standard summary owners. |

## Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| `facet_values.ex` | Meilisearch `client.ex` | validated public facet callback | ✓ WIRED | Probe finds `search_facet_values`. |
| Meilisearch `client.ex` | `query.ex` | keyword filters through common renderer | ✓ WIRED | Probe finds `render_common_filter`; public blobs match. |
| Phoenix `blog.ex` | Phoenix `blog/post.ex` | membership-derived search and hydration | ✓ WIRED | Probe finds authorization path; public module inspected. |
| Phoenix tenant smoke test | package verification task | same named test via fresh artifact | ✓ WIRED | Probe finds `SCRYPATH_PHASE166_HOST`; path/package receipts exist. |
| Repair test | `lib/scrypath/backfill.ex` | explicit Ecto ID predicate | ✓ WIRED | Probe finds `selected_query`. |
| Repair test | Meilisearch task oracle | returned UID terminal state | ✓ WIRED | Probe finds `wait_for_task`. |
| Plan 02 summary | Plan 04 summary | host/path/package handoff | ✓ WIRED | Source-linked handoff present. |
| Plan 03 summary | Plan 04 summary | repair proof/main comparison | ✓ WIRED | Source-linked handoff present. |
| Plan 05 summary | Plan 04 summary | integrated delivery identity | ✓ WIRED | Exact receipt link present. |
| `.planning/STATE.md` | Plan 05 summary | inventory authority pointer | ✓ WIRED | Pointer present; GSD probe passes. |

## Data-Flow Trace (Level 4)

| Artifact | Data variable | Source | Produces real data | Status |
|---|---|---|---|---|
| Tenant/facet calls | filter and encoded request | validated options and Meilisearch query renderer | Yes; request tests assert sent predicates | ✓ FLOWING |
| Phoenix tenant search | tenant, returned IDs, records | persisted membership query, Meilisearch IDs, constrained Ecto hydration | Yes; public source uses membership and tenant/status/ID predicates | ✓ FLOWING |
| Phoenix facets | raw values/counts and host result | backend response plus Ecto count query | Yes; consumer proof asserts raw and recomputed values independently | ✓ FLOWING |
| Manual repair | selected rows and task state | selected-ID Ecto query, backend upsert and task UID | Yes; named tests assert terminal success and visibility | ✓ FLOWING |
| Delta/cohort inventory | paths, PR state and checks | refreshed GitHub refs/blob API and run-linked metadata | Yes; dated path set and ten evidenced rows | ✓ FLOWING |

## Behavioral Spot-Checks

| Behavior | Command/evidence | Result | Status |
|---|---|---|---|
| Tenant/facet regressions | Prior receipts: tenant test 9/0; facet + within-facet tests 12/0. Not rerun in this resume. | Passed on recorded candidate; corrected library blobs match public `main`. | ✓ PASS (prior evidence) |
| Phoenix host policy/path/package modes | Prior Plan 02 receipts: path and fresh local-package modes each 16/0 with source/graph identities. | Passed on recorded candidate. | ✓ PASS (prior evidence) |
| Bounded repair | Prior Plan 03 receipts; selected-ID predicate and terminal task oracle present. | Passed on recorded candidate. | ✓ PASS (prior evidence) |
| Phase 168 regression gate | Orchestrator-provided: seven files, 66/0 under Elixir 1.19.5 / OTP 28; not rerun. | Passed. | ✓ PASS (prior evidence) |
| Public-main post-merge workflow | `gh run view 36644133759 --repo szTheory/scrypath --json ...` | Success on exact squash SHA; required jobs succeeded. | ✓ PASS |
| Candidate/merge-ref/squash identities | GitHub commit API reads | All three resolve to tree `48605fa22efafd8c37ad563ea84949a1fdf05988`. | ✓ PASS |

No phase plan or regression test was rerun during this verification, per the resume instruction. Recorded Phase 169 results and direct exact-SHA GitHub checks were used.

## Probe Execution

No phase probe scripts were declared or found; this is not a migration/tooling phase.

## Requirements Coverage

| Requirement | Source plan | Description | Status | Evidence |
|---|---|---|---|---|
| DELIV-02 | 169-01 through 169-05 | Dated refreshed-main delta, tenant/facet correction merged and verified with regression/adopter proof, and owned remainder accounted for | ✓ SATISFIED | Public merge SHA and green exact-SHA run; source-specific test/package/repair receipts; complete inventory. |
| TRIAGE-01 | 169-05 | Frozen dated Dependabot cohort has evidence-based dispositions and revisit triggers; routine arrivals stay in maintenance | ✓ SATISFIED | Ten rows for #65 and #68–#76 with observed state/head/base, evidence, rationale, disposition and trigger. |

No other REQUIREMENTS.md rows map to Phase 169; no orphaned requirement found.

## Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---:|---|---|---|
| None | — | No debt/placeholder markers in scanned owned implementation/test files; no disabled linked tests found. File-write matches were ordinary `on_exit` cleanup, not expected-value generation. | — | No blocker. |

## Decision Coverage

All eight trackable Phase 169 CONTEXT decisions are honored by shipped artifacts (non-blocking check, 8/8).

## Human Verification Required

None. Service-backed consumer and repair behaviors have named executable evidence and exact-SHA hosted post-merge evidence. The review deviation uses the explicit override above; it does not claim a review occurred.

## Gaps Summary

No remaining roadmap or requirement gap. Plan 04's literal review-first truth is a recorded workflow deviation: GitHub shows `reviews=[]` and empty `reviewDecision`; the user authorized the ordinary squash merge once CI was green. The override does not assert a review occurred. Public `main` is the verified squash source, exact-SHA workflow succeeded, and the finite cohort inventory records pending mutations without claiming they happened.

---

_Verified: 2026-10-02T11:38:40.416Z_  
_Verifier: the agent (gsd-verifier)_
