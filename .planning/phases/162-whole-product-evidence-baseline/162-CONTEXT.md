# Phase 162: Whole-Product Evidence Baseline - Context

**Gathered:** 2026-09-25
**Status:** Ready for planning

<domain>
## Phase Boundary

Assess the approved non-UI product surface across representative adopter and operator jobs. Produce a claim-level baseline that identifies supporting evidence, provenance, freshness, boundaries, and limitations. Reuse existing proof only where it supports the specific claim. This phase assesses and indexes evidence; it does not implement unspecified product changes, add UI scope, or declare readiness from incomplete evidence.

</domain>

<decisions>
## Implementation Decisions

### Representative adopter roles and boundaries
- **D-01:** Use four role lenses: first-hour application integrator; application feature owner; production operator/platform owner; and library maintainer/releaser. Map claims over first-hour setup, indexing, search, failure diagnosis, recovery, upgrade, and release.
- **D-02:** Name the integration seam and claim boundary for each row. The baseline should trace package/toolchain, Ecto schema/context/Repo, Scrypath, optional Oban, Meilisearch, optional Phoenix request-edge integration, and release/support boundaries.
- **D-03:** Treat the downstream searcher as an outcome of the application feature owner's job. The host application owns user authorization, business policy, and presentation; do not imply those are Scrypath guarantees.
- **D-04:** Use a capability-by-evidence matrix linked to canonical evidence. Keep UI, arbitrary host policies, every supported-version cross-product, new runtime/backend/search capability, and capacity/disaster-recovery exercises out of the assessment unless already-backed evidence directly bears on an approved claim. Record limitations without turning them into implicit pass/fail claims or implementation scope.

### Evidence freshness and sufficiency
- **D-05:** Judge evidence against the exact claim it supports, at the cheapest reliable layer. Record source and result, date, commit or immutable hosted receipt, environment and versions where relevant, evidence boundary, what it proves, and known limitations.
- **D-06:** Keep claim assessment separate from evidence freshness. Assess claims as supported, insufficiently supported, or unknown; describe evidence as current, reusable within its stated boundary, stale after a relevant invalidator, or unknown.
- **D-07:** Use event-triggered, claim-specific revalidation. Relevant code/test/config/documentation changes; dependency or supported-version changes; service/protocol changes; package, tag, or release changes; workflow/security changes; incidents; and time-sensitive external assertions can invalidate affected claims. Revalidate narrowly rather than rerunning the whole portfolio.
- **D-08:** Do not use blanket evidence age cutoffs, readiness scores, new required CI lanes, or routine human UAT. Missing or stale proof is not itself a product defect; disclose it as insufficient support or unknown until evidence distinguishes the cause.

### the agent's Discretion
- Choose the most readable artifact structure that preserves one canonical baseline index and links to detailed evidence instead of duplicating it.
- Choose concise identifiers and column names for roles, jobs, claims, boundaries, provenance, freshness, and limitations.
- Select only the narrow inspections or proof reruns needed to resolve a decision-relevant uncertainty, consistent with the approved scope and verification-cost policy.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.** The current project and v1.39 planning authority supersede any conflicting or older recommendation in research prompts.

### Scope, requirements, and assessment policy
- `.planning/reference/PRE-OPERATOR-UI-READINESS.md` — approved seven dimensions, evidence practices, exclusions, and six-condition readiness gate.
- `.planning/REQUIREMENTS.md` — phase requirements BASE-01 through BASE-03 and milestone boundaries.
- `.planning/ROADMAP.md` — phase goal, success criteria, and sequencing.
- `.planning/PROJECT.md` — current product scope, adopter UX goals, and established architecture boundaries.
- `.planning/reference/MILESTONE-ARC.md` — v1.39 sequencing and longer-term posture.
- `.planning/reference/milestone-candidates.md` — evidence threshold and roadmap candidate posture.

### Prior evidence and assessment patterns
- `.planning/research/ARCHITECTURE.md` — canonical baseline/index pattern, evidence seams, and anti-patterns.
- `.planning/research/FEATURES.md` — approved assessment dimensions and scope exclusions.
- `.planning/research/SUMMARY.md` — research synthesis, lifecycle/jobs, and remaining evidence gaps.
- `.planning/reference/QUALITY-LEDGER.md` — v1.37 findings, evidence, risk/cost, and disposition pattern.
- `.planning/milestones/v1.37-MILESTONE-AUDIT.md` — bounded v1.37 claims and audit limits.
- `.planning/milestones/v1.37-phases/159-close-v1-37-audit-gaps-coverage-wiring-and-verification-prov/159-EVIDENCE-MATRIX.md` — evidence classes, provenance, boundaries, and chronology limits.
- `.planning/milestones/v1.38-MILESTONE-AUDIT.md` — package-backed proof and release audit boundaries.
- `.planning/milestones/v1.38-phases/160-package-backed-phoenix-proof/COVERAGE.md` — exercised package consumer flows and explicit exclusions.
- `.planning/milestones/v1.38-phases/160-package-backed-phoenix-proof/160-VERIFICATION.md` — exact-SHA service and packaged-consumer verification.
- `.planning/milestones/v1.38-phases/161-release-and-tidy-closeout/161-RELEASE-EVIDENCE.md` — release, publication, package, and hosted evidence.

### Adopter jobs, operations, and ecosystem design guidance
- `guides/jtbd-and-user-flows.md` — adopter jobs and lifecycle flows.
- `guides/golden-path.md` — first-use integration path.
- `guides/sync-modes-and-visibility.md` — inline, manual, and Oban sync behavior and visibility.
- `guides/request-edge-search.md` — Phoenix request-edge and host-context boundary.
- `guides/drift-recovery.md` — drift diagnosis and recovery flows.
- `docs/search-backend-sre.md` — backend and operator reliability boundaries.
- `prompts/search-lib-use-cases-deep-research.md` — search adopter jobs, integration gaps, and successful library precedents.
- `prompts/elixir-search-lib-deep-research.md` — Elixir search-library ecosystem and precedent; historical backend recommendations do not override the current Meilisearch-first project decision.
- `prompts/meileisearch best practices for scrypath deep research.md` — source-of-truth, projection, and operational semantics for the Meilisearch boundary.
- `prompts/elixir-plug-ecto-phoenix-system-design-best-practices-deep-research.md` — Elixir runtime, integration, operations, and Phoenix boundary principles.
- `prompts/ecto-best-practices-deep-research.md` — Ecto schema, Repo, context, transaction, and data ownership principles.
- `prompts/elixir-best-practices-deep-research.md` — idiomatic Elixir library and runtime principles.
- `prompts/phoenix-best-practices-deep-research.md` — Phoenix as an optional web boundary and context-owned application behavior.
- `prompts/elixir-opensource-libs-best-practices-deep-research.md` — OSS library API, documentation, compatibility, and consumer DX principles.
- `prompts/elixir-oss-lib-ci-cd-best-practices-deep-research.md` — CI, release, and supply-chain verification principles.

There is no UI design scope in this phase; brandbook and visual-system references are not applicable.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- The v1.37 quality ledger and Phase 159 evidence matrix provide evidence provenance, limitation, and disposition precedents.
- The v1.38 package coverage, verification, release evidence, and milestone audit provide consumer-shaped, exact-SHA, hosted, and release proof to reuse claim by claim.
- The adopter-flow, sync, request-edge, recovery, and SRE guides provide concrete lifecycle jobs and integration seams to map.

### Established Patterns
- Maintain one capability-by-evidence index that links to canonical proof; avoid duplicating evidence and creating competing ledgers.
- Distinguish not assessed, sufficient evidence, and finding/disposition; an assessment status is not a defect status.
- Keep source-level, automated, service, package-consumer, and hosted evidence distinct, including whether a check is required or advisory.
- Ecto contexts own application orchestration; schemas carry metadata; Phoenix integration is optional. Search writes and indexing tasks are asynchronous boundaries, so enqueue/write success alone does not prove documents are searchable or database/search state is atomic.

### Integration Points
- This phase connects lifecycle jobs and the seven readiness dimensions to existing code, guides, tests, package artifacts, CI receipts, and prior milestone evidence. It does not require a runtime integration or new UI.

</code_context>

<specifics>
## Specific Ideas

- Use the recommended four-role sample and event-triggered freshness policy as the coherent default; the owner approved both recommendations on 2026-09-25.
- Preserve nonclaims visibly: exact-SHA proof is bounded to that SHA/environment; a selected compatibility tuple does not prove every combination; service success and CI enforcement posture are separate facts.
- This is an evidence and maintainer-documentation workflow, not a UI/graphic-design phase. Favor a navigable, concise index with links rather than a broad decorative scorecard.
</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.
</deferred>

---

*Phase: 162-whole-product-evidence-baseline*
*Context gathered: 2026-09-25*
