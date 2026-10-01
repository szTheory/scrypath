# Milestone candidates — Scrypath evidence-gated roadmap

**Purpose:** Help `$gsd-new-milestone` select work that improves Scrypath adopters or protects release trust without creating roadmap work for its own sake.
**Reviewed:** 2026-10-01 against v1.40 closeout, public PR #87/main and the refreshed Release Please PR #83 state.
**Current posture:** v1.41 scope and roadmap were approved on 2026-09-28 after requested upstream review: nine requirements across Phases 168–170. Phase 168 delivered the four-graph security fix, Phase 169 delivered the tenant/facet correction and cohort disposition, and Phase 170 docs/tooling reached public `main` at `87d74259a9f569c6b11c8d9481f5465a172c70ba` through PR #87. Read [current synthesis](../research/v1.41/SUMMARY.md). Hex 0.3.13 remains the published package. Release Please PR #83 proposes 0.3.14; the maintainer authorized the normal path, but it is blocked by the required approving review and remains unpublished. The latest main push run 36795877117 passed all five required checks and its deep-quality advisory. The four graph audit remains clean with Mint 1.11.0; PR #87 changed no lockfiles or runtime paths. v1.40's dated readiness assessment remains **NOT READY** (condition 2 FAIL; condition 6 UNKNOWN at its cutoff). Operator UI remains gated on a fresh READY assessment, maintainer availability, and a separate scope decision.

Use evidence-gated horizons, not calendar commitments. Reassess these candidates at each milestone boundary. See [`../../prompts/scrypath-milestone-ratchet-roadmap.txt`](../../prompts/scrypath-milestone-ratchet-roadmap.txt) for the durable decision guide.

The governing program and explicit **READY FOR OPERATOR UI** exit criteria are in [`PRE-OPERATOR-UI-READINESS.md`](PRE-OPERATOR-UI-READINESS.md); v1.40 requirements, audit, and phases are archived in `.planning/milestones/`, while the root `.planning/ROADMAP.md` tracks v1.41 and indexes recent shipped milestones.

## Near term — v1.41 readiness gate follow-through

**Completed:** v1.40 completed Phases 165–167: tenant/facet contract fixes, bounded host and repair proof, and a dated readiness decision. Its audit accepts bounded tech debt; the immutable decision remains NOT READY because condition 2 failed and condition 6 was UNKNOWN at its cutoff.

**Approved v1.41 scope:** Phase 168 closed Mint findings across all four maintained graphs, delivered the startup-readiness fix and recurring graph-audit coverage. Phase 169 delivered the known tenant/facet corrections and coherent proof, then dispositioned a frozen bot cohort. Phase 170 consolidated docs through PR #87, is reconciling the authorized-but-blocked 0.3.14 candidate, and will make the terminal six-condition decision after final-source evidence. See [roadmap](../ROADMAP.md) and [review synthesis](../research/v1.41/SUMMARY.md).

**Delivery boundary:** selected fixes and docs must be merged and verified on public main; a prepared PR remains blocked delivery until the actual repository gates pass. PR #87 is merged with exact-main evidence. PR #83 remains blocked by one required review after the exact candidate package and required check runs passed. Preserve unrelated worktree changes and use the [dated source inventory](../research/v1.41/DELIVERY-REVIEW.md) instead of a mutable commit-count target.

**Dependency PR boundary:** freeze the cohort at Phase 169 start, record rationale/revisit triggers once, and refresh checks before acting. New routine PRs enter maintenance; material security/compatibility evidence can reopen scope. An empty inbox is not required.

**Docs boundary:** retain the short first-result route and acceptance/visibility caveat; consolidate detailed canonical contracts and unique JTBD routes. Adjust directly related stale guide wording and obsolete copy assertions without a broad redesign.

**Readiness stop point:** preserve the v1.40 cutoff. Use finite baseline/workflow claims, current invalidators and final delivery/attestation receipts. The terminal decision is durable outside the tested tree to avoid another tracked-write loop. NOT READY must name blockers and revisit triggers; it does not automatically start another milestone. READY recommends ScrypathOps only when maintainer time and a separate scope decision support it.

**Release posture:** 0.3.13 remains published. Release Please PR #83 proposes 0.3.14 for the integrated fixes/docs; the user authorized the normal release path for its exact head, conditional on current policy. One actual approving review is still required. Do not report 0.3.14 as published until the existing Release Please, Hex/consumer, and parity chain passes. Keep blocked publication distinct from explicit owner deferral.

## Mid term — bounded, owner-approved wedges

| Candidate | Entry evidence | Boundary |
|---|---|---|
| ScrypathOps operator UX/design polish | Maintainer time is available and a specific operator JTBD, usability/accessibility issue, or repeated workflow friction is identified | Improve the existing optional operator surface; keep runtime/API behavior unchanged unless separately justified. Automate accessibility and behavioral acceptance where reliable; reserve visual judgment for irreducible design choices. |
| Adopter-driven product or documentation gap | Reproducible, reviewed outside-adopter evidence demonstrates a material unmet workflow | Address that workflow only; preserve Meilisearch-first and Ecto-native product boundaries. |
| Proof or release-train repair | Repeated CI/proof drift, concrete release compatibility pressure, or operational failure | Fix the smallest shared cause; measure CI/runtime cost and do not duplicate existing proof. |

**Operator UI timing:** ScrypathOps received major operator-flow, design-system, and accessibility/theme work in v1.32–v1.34. v1.40 completed a fresh whole-product assessment, which remains NOT READY because condition 2 FAILs and condition 6 was UNKNOWN at cutoff. Revisit UI only after a fresh assessment passes and maintainer time is available; no UI milestone is approved now. Passing the gate would support a recommendation, not automatically start UI work.

## Long term — strategic expansion only with evidence

| Candidate | Reopen only when |
|---|---|
| Public backend broadening | Multiple real adopters establish a stable common contract and the value outweighs abstraction and support costs. |
| Autocomplete, suggestions, vector/hybrid retrieval, personalization, or analytics | Reviewed adopter demand establishes a material gap and an explicit scope decision authorizes the capability. |
| New public runtime or reusable UI surfaces | A recurring cross-adopter job cannot be served cleanly by existing APIs and the addition preserves operational honesty and Ecto-first composition. |

These are conditional possibilities, not commitments. Existing scope guards remain authoritative until formally changed.

## Selection and closeout rules

1. Start with the evidence and the affected adopter/operator job. If neither is concrete, stay idle.
2. Check prior requirements, milestone archives, support reports, and existing proof before proposing new runtime/API scope.
3. Prefer the smallest vertical slice with the least maintenance and CI cost that can prove the outcome.
4. Automate software acceptance at the cheapest reliable layer; target zero human UAT. Put recurring checks in CI only when confidence justifies runtime and maintenance cost.
5. Keep serious work PR-first, require exact-commit CI, verify post-merge `main`, and close release/worktree/artifact cleanup when warranted. Reconcile local branch state against public `main`; a local milestone archive is not proof of a public merge.
6. Do not create milestones solely for routine Dependabot/dependency churn; handle ordinary bumps through maintenance and reserve larger work for evidenced security, compatibility, or adopter outcomes.
7. Refresh this file and `MILESTONE-ARC.md` at milestone close: mark shipped candidates complete, remove stale ideas, record evidence and deferrals, and do not invent a next milestone.

## Shipped context

- **v1.39 Pre-Operator UI Quality Readiness Ratchet:** completed Phases 162–164 with a 24-claim whole-product baseline, zero qualifying implementation candidates, and a fail-closed NOT READY decision because conditions 3 and 6 remain UNKNOWN. Final exact-SHA closeout passed; later closeout evidence does not retroactively change the dated readiness result.
- **v1.40 Readiness Evidence Closure:** completed Phases 165–167. Tenant/facet contracts and two compatible defects were verified, one persisted-membership Phoenix workflow and one bounded repair-to-visible-search workflow passed, and a separate dated decision remains NOT READY (condition 2 FAIL; condition 6 UNKNOWN at cutoff). Final phase-tracking and archive exact-SHA closeout runs passed; neither revises the cutoff.
- **v1.37 Code Quality Ratchet:** hardened runtime safety and architecture, introduced capability-named verification, reduced duplicated CI proof, secured release workflows, and established measured performance evidence. Its quality ledger reports no confirmed compatible high- or medium-leverage non-UI finding left open.
- **v1.38 Packaged Adopter Proof:** Scrypath 0.3.13 passed package-backed Phoenix integration, exact-SHA and post-merge CI, Hex/HexDocs publication, clean consumer compilation, and package-to-tag parity. No human UAT remains pending.
- **v1.41 Phase 170 docs delivery:** selected README/JTBD/sync guidance and factual closeout tooling are on public `main` through PR #87; exact-source required CI passed. This does not complete the readiness decision or publish 0.3.14.
- **v1.32–v1.34:** ScrypathOps design system, operator flows, dual-theme polish, and accessibility proof received dedicated milestones. Additional UI work is deferred by owner time and target evidence.
- Earlier product wedges through v1.36 are recorded in `.planning/MILESTONES.md` and `.planning/milestones/`.

*Provenance: adapted 2026-09-25 from the maintainer's cross-project ratchet prompt and refreshed 2026-09-28 from v1.40 closeout, public release/main evidence, privacy review, and the maintainer's documentation direction. Reconciled with `.planning/PROJECT.md`, `.planning/STATE.md`, `.planning/RETROSPECTIVE.md`, v1.37–v1.40 evidence, and exact-SHA closeout receipts. Read with `PRE-OPERATOR-UI-READINESS.md` and the companion guide in `prompts/`.*
