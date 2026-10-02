# v1.41 delivery and scope review

**Reviewed:** 2026-09-28, snapshot checked through 16:47 UTC. **Method:** read-only Git/GitHub inventory, source and policy inspection; no tests, dispatches, merges, or publication. This review recommends changes; it grants no merge authority.

**Recommendation:** retain three outcome-oriented phases, but establish the clean public-main source boundary before Phase 168, require selected fixes to reach green `main`, and settle the final assessment protocol before Phase 170. This is feasible maintenance work. Its biggest avoidable cost is reconciling accumulated planning history repeatedly while actual fixes remain unpublished.

## Actual delivery inventory

Read-only `gh api repos/szTheory/scrypath/branches/main` matched local `origin/main` at `40c9978c975dbfb42db75511f44ff0369c8d7d88`. Local committed HEAD was `20ba2f3b1e42e8c4e90c97d794e124b5c4fff080`, **140 commits ahead**, none behind. The research's 137 is a dated baseline, now superseded by three milestone-start/research/requirements commits. Replace mutable counts in operative requirements with a timestamped inventory reference (`.planning/ROADMAP.md:50`; `.planning/research/v1.41/SUMMARY.md:12`).

`git diff --numstat origin/main HEAD` gives:

| Surface | Files | Added / removed lines | Delivery meaning |
|---|---:|---:|---|
| `.planning/` | 133 | 17,978 / 1,059 | Assessments, archives, checker tooling, tracking |
| `lib/` | 5 | 24 / 4 | Tenant-option and facet-filter bug fixes |
| Phoenix example | 11 | 688 / 3 | Host tenant scenario, migration, isolation, proof |
| Root tests | 3 | 1,005 / 0 | Tenant/facet contracts and bounded repair proof |
| Ratchet prompt | 1 | 272 / 0 | Maintainer policy |

125 commits touch only `.planning`; three touch `lib/`. The library delta excludes the already-composed `tenant_scope` from strict runtime configuration and renders facet keyword filters using existing grammar (`lib/scrypath/search/single.ex:44`, corresponding Many/FacetValues helpers; `lib/scrypath/meilisearch/client.ex:110`). These are actual package fixes. Calling v1.40 “planning-only” obscures them (`.planning/ROADMAP.md:6`; `.planning/PROJECT.md:135` correctly mentions the corrections).

The separate uncommitted mounted-readiness fix changes two setup commands plus five test lines. It already has bounded local evidence on a clean public-source export; hosted run [36439562644](https://github.com/szTheory/scrypath/actions/runs/36439562644) tested the unchanged public SHA, **not this fix** (`.planning/debug/resolved/ecommerce-mounted-readiness.md:60–86`). Preserve all unrelated dirty files; neither branch cleanup nor inventory authorizes their removal.

## Prioritized corrections

1. **Refresh security scope before implementation.** The companion [security review](SECURITY-REVIEW.md) identifies new Mint advisories, four affected graphs, Mint 1.11.0, and coupled consumer HPAX resolution. The old “root already fixed / consumer only / 1.10.1+” premise cannot constrain Phase 168. Keep updates limited to the demonstrated dependency closure. Clean-main preparation is an execution prerequisite for this security work, not a reason to wait for all Phase 169 archives. The existing harness is already on public main; the later tenant scenario can be integrated and proved with its runtime fixes.

2. **Make delivery an outcome.** `.planning/REQUIREMENTS.md:17–19,28` and `.planning/ROADMAP.md:50–53` permit completion with PRs merely prepared and merge conditional. Require the selected security correction, mounted-readiness fix, and confirmed tenant/facet fixes to merge with exact-source acceptance and green post-merge `main`. “Ready to merge” is a useful blocked-delivery status. It becomes a completed narrower slice only through an explicit maintainer scope/defer decision; a generic disposition entry cannot imply that acceptance. Do not turn every planning-only change into a shipping prerequisite.

3. **Freeze the triage boundary.** At this snapshot, PRs **65, 68–76** remain open, Dependabot-authored and `BEHIND`; none directly targets Mint. Record this finite inventory's timestamp, PR/head/base SHAs and rationale once. Recheck before acting on a selected PR. Newly opened routine updates belong to maintenance; reopen the milestone boundary only for material security/compatibility evidence. A deferred Req minor update or checkout major update needs a revisit trigger, not speculative upgrading or repeated full CI merely to complete a table (`prompts/scrypath-milestone-ratchet-roadmap.txt:147–175`).

4. **Separate history from tested source.** Reconstructed commits need new candidate/final and post-merge receipts. Reuse historical behavioral evidence only after comparing relevant source, locks, fixtures, workflow and configuration blobs, preserving original run/SHA/date and claim limits. A history rewrite alone does not invalidate identical behavioral source; it also does not transfer the old run to the new SHA. The debug's 357-blob comparison is a useful bounded example (`.planning/debug/resolved/ecommerce-mounted-readiness.md:48–60`). History-sensitive repository tests mean even identical runtime blobs are insufficient to waive required current gates (`.github/workflows/ci.yml:23–25,57–60`).

## Coherent integration choices

| Option | Practical example | Benefits | Costs / judgment |
|---|---|---|---|
| **A. Sequential coherent PRs — recommended** | Security graph correction; mounted startup fix; tenant/facet fixes with associated host/repair proof; docs and consolidated tracking | Security ships promptly; review and rollback boundaries are clear; planning volume does not bury fixes | Some repeated required CI; avoid excessive subdivision of the coupled tenant fixture, serializer and scenario |
| **B. Security first, then one bounded follow-through PR** | Merge security separately; combine remaining selected fixes, proof and docs, keeping bulk archives separately reviewable | Fewer main-base refreshes and integration runs | Broader second diff; suitable only with an explicit source manifest and understandable review |
| **C. Prepare PRs and hand off** | Tested PRs await a maintainer merge window | Honest when authority or availability prevents integration | Leaves public fixes undelivered; v1.41 delivery stays blocked unless the maintainer explicitly narrows acceptance; no inferred risk acceptance |

Avoid using the entire local branch as the delivery unit. Conversely, do not require one PR per historical commit, requirement, or planning artifact. These options follow the small useful outcome and cost rules in `prompts/scrypath-milestone-ratchet-roadmap.txt:123–136,189–200`.

## Phase outcomes and downstream decisions

**168 — Current security remediation delivered.** Resolve the newly confirmed graph scope on a clean public base, establish graph-specific audit and applicable existing consumer proofs, and reach green `main`. Decide whether the tiny mounted startup fix must land first to make repeated required verification reliable; its demonstrated race justifies early integration without reopening a broad CI project. No dependency on importing old planning history.

The execution adapter must explicitly create or select that isolated PR base: `.planning/config.json:10,40` currently combines `branching_strategy: none` with `use_worktrees: true`. Use supported GSD isolation rather than assuming configuration guarantees a clean branch. Do not push the current workspace branch or change global workflow settings during this review.

**169 — Confirmed fixes and selected proof integrated.** Complete the source inventory, deliver the package bug fixes with their coherent regression/adopter proof, disposition the frozen bot baseline, and reconcile selected planning records. Distinguish local implementation completion, merge, and package availability. Ordinary docs work can overlap this phase; no artificial requirement makes documentation wait for every bot disposition.

The tenant/facet corrections warrant a normal patch under the existing train: they repair public behavior in packaged `lib/`. Root dependency constraints may add another release reason; a consumer lock edit alone does not establish one. Use release-facing `fix:` semantics, let Release Please own version/tag/changelog, and make the publish-or-explicitly-defer decision at the integrated source. Once publication is selected, require the existing publish/consumer/parity receipts. Do not infer package delivery from a green local artifact or force publication merely because a milestone number changed (`docs/releasing.md:11–15,31,100–134`; [Release Please](https://github.com/googleapis/release-please#how-should-i-write-my-commits)).

**170 — Focused guidance and terminal delivery/assessment.** Consolidate README/JTBD duplication, merge the final selected docs/tracking changes, and establish their post-merge evidence; Phase 169's earlier green SHA cannot attest Phase 170 edits. Own the final release decision here: deliver the warranted Release Please patch and publish/parity evidence, or record an explicit authorized release deferral and keep package claims bounded. Reconcile release/support truth and assess six unchanged conditions at the resulting source. Preserve historical assessments; update stale “no milestone approved / Phase167 still completing” current prose (`.planning/reference/PRE-OPERATOR-UI-READINESS.md:3,36–40`). Keep requirement identifiers unambiguous before plans: adopt DOC-03/GATE-05/CLOSE-04 with a small old-to-new mapping, as the companion provenance review identifies earlier use.

## Authority and a finite closeout

Live protection has five strict required checks, linear history, no configured required-review rule, and squash-only merges; admin enforcement is disabled. This is not authorization to bypass checks or manufacture reviewer approval. Establish who may merge and whether a real review is requested before execution. Strict checks require an up-to-date base; PR CI normally tests the synthetic merge ref, so record that identity separately from head-dispatch and actual squash-main receipts ([GitHub protection](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches), [workflow event semantics](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows#pull_request)).

Prevent condition 6 from recursively creating new tracking debt. Finalize all tracked assessments, cleanup dispositions and archives before the last exact-SHA attestation (`CONTRIBUTING.md:76–83`; `.planning/PROJECT.md:327`). Use a provisional tracked assessment, then a separately dated authoritative terminal record outside the tested tree once all conditions and final attestation actually pass. Choose its durable location before planning; seven-day Actions artifacts alone are insufficient. Preserve source SHA, run/attempt, job outcomes and artifact digests. The existing attestation proves jobs and coverage, **not semantic six-condition readiness** (`.github/workflows/ci.yml:277–324`). Do not append its result to Git and start another finality cycle.

Leave the five required gates, advisory proof posture, narrow documentation scope, historical NOT READY decisions, and UI's separate scope/availability gate intact. A truthful NOT READY terminal assessment remains legitimate; silently deferring selected fixes or inventing new retrospective paperwork is not delivery.
