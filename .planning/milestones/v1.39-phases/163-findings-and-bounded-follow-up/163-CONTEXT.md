# Phase 163: Findings and Bounded Follow-up - Context

**Gathered:** 2026-09-25
**Status:** Ready for planning

<domain>
## Phase Boundary

Turn the Phase 162 claim-level evidence baseline into evidence-led classifications, qualitative ranks, explicit dispositions, and only those separately scoped follow-up candidates that have a concrete adopter/operator outcome, scope authority, and automated acceptance. Keep evidence gaps distinct from defects and opportunities. This phase does not implement new product/runtime scope or decide readiness; Phase 164 owns the six-condition readiness gate.

</domain>

<decisions>
## Implementation Decisions

### Materiality and classification
- **D-01:** A material finding must be a confirmed behavior defect or a substantiated Scrypath-owned risk affecting a named integrator, feature-owner, operator, or maintainer job. Require observed/reproducible behavior or specific authoritative evidence of an affected risk; an unverified source-level concern remains an observation.
- **D-02:** Keep evidence gaps linked to their Phase 162 baseline claims and investigate only when additional evidence could change a decision. Missing or stale proof remains a gap, not a defect or severity-ranked finding.
- **D-03:** Record confidence separately from impact and severity. Lower confidence can trigger targeted evidence gathering, but must not numerically cancel a credible severe consequence.

### Qualitative rank
- **D-04:** Use the gate-aligned labels **Critical / High / Medium-leverage / Low**. Apply outcome- and risk-based definitions with a concise rationale; do not use a weighted numeric score.
- **D-05:** Show impact, frequency/exposure, confidence, applicable compatibility/security/privacy/data-integrity/operational risks, implementation and regression cost, and recurring verification cost distinctly. A credible severe consequence can warrant a high rank even when frequency is low. Cost informs remedy choice and CI placement; it never lowers severity.
- **D-06:** Describe costs qualitatively and include measured runtime or maintenance evidence when available. Do not require speculative hour estimates.
- **D-07:** Every material finding receives an explicit `closed`, `accepted`, `deferred`, or `rejected` disposition with supporting evidence or rationale. Accepted risk requires an owner decision; deferred work requires an owner and event-based revisit trigger. Preserve the readiness boundary: Phase 164 alone makes the gate decision.

### Bounded follow-up qualification
- **D-08:** Group findings only when they share a named adopter/operator outcome, approved scope boundary, and automated proof flow. Split findings whose risk, owner boundary, or acceptance proof is materially different.
- **D-09:** Create a separate follow-up milestone when a finding needs a coordinated, bounded outcome across multiple tasks. A contained fix or routine maintenance item can remain in the focused patch/PR lane.
- **D-10:** Rank sets urgency, not automatic roadmap eligibility. A candidate needs decision-relevant evidence, a concrete user outcome, authorized scope, and workable automated acceptance. For medium/low-leverage work, value must justify implementation, regression, and ongoing maintenance cost. Follow existing explicit scope-guard review for any potentially prohibited API/runtime capability.
- **D-11:** Record why each non-qualifying observation does not warrant a candidate beside its linked baseline claim; do not create a speculative standing backlog. Material deferred findings still keep their owner and revisit trigger.

### Automated acceptance
- **D-12:** Keep a claim-to-proof record with each selected finding/candidate rather than creating a phase-wide manifest or separate CI lane catalogue before demonstrated need.
- **D-13:** Map each user-visible acceptance claim to the cheapest reliable automated layer with an observable outcome. Use unit/property or contract/seam proof when it establishes the claim; add integration, package/service, browser, or exact-SHA hosted proof only when the claim crosses that boundary.
- **D-14:** Promote a check to recurring CI only when repeated regression risk and confidence gained justify recurring runtime and maintenance cost, and the check is reliable, isolated, and diagnosable. Record the comparison when adding a lane or changing its trigger/blocking status; otherwise keep CI economics with the claim.
- **D-15:** A compact claim-to-proof entry includes the user outcome, scope/boundary and exclusions, fixture and oracle, selected proof layer and command, relevant environment/version and exact-SHA/hosted receipt, invalidation trigger, and applicable timeout, diagnostics, isolation, and cleanup details. Software acceptance has no routine human UAT.

### the agent's Discretion
- Choose a navigable source-linked findings/disposition artifact that preserves Phase 162 as the canonical evidence index; cross-reference baseline claim IDs rather than duplicating receipts.
- Choose concise rank definitions, claim IDs, column names, and grouping layout consistent with the decisions above.
- Inspect or rerun only the narrow evidence needed to resolve a decision-relevant uncertainty; do not create a new scorecard, broad rerun, mandatory CI lane, or tooling schema without demonstrated value.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.** The Phase 163 goal and requirements are in ROADMAP.md and REQUIREMENTS.md; the roadmap has no separate Canonical refs block.

### Scope and decision authority
- `.planning/REQUIREMENTS.md` — FIND-01 through CLOSE-02 requirements, exclusions, and v1.39 scope.
- `.planning/ROADMAP.md` — Phase 163 goal, requirements, success criteria, and Phase 164 boundary.
- `.planning/PROJECT.md` — product scope, readiness posture, scope authority, green-main/PR-first release posture, and automation-first verification policy.
- `.planning/reference/PRE-OPERATOR-UI-READINESS.md` — approved readiness dimensions, finding practices, milestone qualification posture, and six-condition gate.
- `.planning/reference/milestone-candidates.md` — evidence threshold, bounded-candidate rules, routine-maintenance lane, and no-invented-backlog policy.
- `.planning/reference/MILESTONE-ARC.md` — v1.39 sequencing and longer-term posture.
- `.planning/milestones/v1.27-phases/97-canonical-contract-freeze-and-scope-guard/97-SCOPE-GUARD.md` — authority for prohibited scope classes and explicit scope review.
- `.planning/STATE.md` — active phase, milestone status, and continuity posture.

### Evidence baseline and prior triage patterns
- `.planning/phases/162-whole-product-evidence-baseline/162-BASELINE.md` — canonical claim/evidence index, open evidence questions, IDs, boundaries, and limitations.
- `.planning/phases/162-whole-product-evidence-baseline/162-CONTEXT.md` — locked role, freshness, evidence, and boundary decisions from Phase 162.
- `.planning/phases/162-whole-product-evidence-baseline/check_baseline.py` — automated baseline integrity and coverage checks; reuse only if relevant to the selected artifact.
- `.planning/reference/QUALITY-LEDGER.md` — prior qualitative issue, evidence, cost, and disposition precedent.
- `.planning/milestones/v1.37-MILESTONE-AUDIT.md` — bounded claims and audit limitations from the prior quality ratchet.
- `.planning/milestones/v1.37-phases/159-close-v1-37-audit-gaps-coverage-wiring-and-verification-prov/159-EVIDENCE-MATRIX.md` — provenance, evidence classes, and chronology limits.
- `.planning/milestones/v1.38-MILESTONE-AUDIT.md` — packaged adopter proof and release audit boundaries.
- `.planning/milestones/v1.38-phases/160-package-backed-phoenix-proof/COVERAGE.md` — package-backed scenarios and explicit exclusions.
- `.planning/milestones/v1.38-phases/160-package-backed-phoenix-proof/160-VERIFICATION.md` — exact-SHA package/service results and limits.
- `.planning/milestones/v1.38-phases/161-release-and-tidy-closeout/161-RELEASE-EVIDENCE.md` — exact release, publication, and package evidence.
- `.planning/milestones/v1.38-MILESTONE-AUDIT.md` — v1.38 closeout claims and limits.

### Project-specific architecture and maintainer guidance
- `CONTRIBUTING.md` — existing verification commands and project workflow.
- `guides/jtbd-and-user-flows.md` — adopter roles and lifecycle jobs to use when stating findings and outcomes.
- `guides/golden-path.md` — first-use adopter flow.
- `guides/sync-modes-and-visibility.md` — synchronization states and the queue/task/visible-search boundary.
- `guides/drift-recovery.md` — operator diagnosis and recovery workflow.
- `guides/request-edge-search.md` — optional Phoenix request-edge and host-context boundary.
- `docs/search-backend-sre.md` — Meilisearch/operator reliability responsibilities and limits.
- `prompts/scrypath-milestone-ratchet-roadmap.txt` — durable evidence-gated roadmap, verification, CI, and release decision guide.
- `prompts/elixir-opensource-libs-best-practices-deep-research.md` — idiomatic Elixir library ergonomics, API and operational clarity.
- `prompts/search-lib-use-cases-deep-research.md` — search adopter jobs, integration gaps, and precedent.
- `prompts/elixir-search-lib-deep-research.md` — Elixir search-library ecosystem; current project decisions supersede historical recommendations.
- `prompts/meileisearch best practices for scrypath deep research.md` — source-of-truth, projection, and operational semantics at the backend seam.
- `prompts/elixir-oss-lib-ci-cd-best-practices-deep-research.md` — OSS CI/CD, release, and workflow security practices.
- `prompts/elixir-plug-ecto-phoenix-system-design-best-practices-deep-research.md` — Elixir/Phoenix runtime and integration boundaries.
- `prompts/ecto-best-practices-deep-research.md` — Ecto ownership, Repo, transaction, and context boundaries.
- `prompts/elixir-best-practices-deep-research.md` — idiomatic Elixir design and maintenance patterns.
- `prompts/phoenix-best-practices-deep-research.md` — Phoenix as an optional web boundary and host-owned behavior.

### External design precedents consulted
- [GitHub milestones](https://docs.github.com/en/issues/using-labels-and-milestones-to-track-work/about-milestones) — grouping related work under a user-described milestone outcome.
- [OpenTelemetry versioning and stability](https://opentelemetry.io/docs/specs/otel/versioning-and-stability/) — explicit public compatibility/stability boundaries for a widely reused library.
- [GitLab Unified Security Risk Management](https://handbook.gitlab.com/handbook/security/security-observations-risk-management/) — distinct risk treatment and accountable owner approval for accepted risk.
- [Phoenix testing guide](https://github.com/phoenixframework/phoenix/blob/main/guides/testing/testing.md) and [Phoenix CI workflow](https://github.com/phoenixframework/phoenix/blob/main/.github/workflows/ci.yml) — focused test selection and bounded integration/version lanes.
- [GitHub Actions workflow syntax](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax) — recurring workflow controls and cost-aware lane configuration.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- Phase 162's `162-BASELINE.md` is the sole canonical source for capability claims and evidence receipts; link claim IDs and avoid copying provenance into a competing ledger.
- `162-BASELINE.md`'s open questions (including C-09 through C-11, C-15 through C-17, C-19, and C-21) are evidence questions only; use their recorded user jobs and limitations as the Phase 163 triage input.
- `.planning/reference/QUALITY-LEDGER.md` and the Phase 159 evidence matrix provide prior issue rationale, evidence-boundary, cost, and disposition patterns.
- Phase 160 coverage/verification and Phase 161 release evidence provide bounded package/service and exact-SHA examples; neither implies universal coverage.
- `check_baseline.py` provides existing automated integrity checks for the baseline artifact; inspect before reuse rather than introducing a parallel schema/checker.

### Established Patterns
- Keep one canonical evidence index and link to source receipts; distinguish evidence sufficiency/freshness from defect status.
- Use claim-specific invalidators and targeted evidence gathering rather than blanket age limits or reruns.
- Keep evidence layer and CI posture distinct; advisory success is not a required-gate claim.
- Ecto/application ownership and the named Scrypath integration seam matter: do not attribute host authorization or policy gaps to Scrypath.
- Plan acceptance before implementation; software acceptance is automated, with recurring CI justified by confidence versus cost.

### Integration Points
- This is a maintainer-facing evidence and planning phase. It connects baseline claim IDs to classification, rank, disposition, candidate scope, and acceptance proof; it needs no runtime, public API, backend, or UI integration.

</code_context>

<specifics>
## Specific Ideas

- Keep uncertainty visible without treating it as a defect: e.g., C-16/C-17 currently lack end-to-end recovery/cutover receipts; that absence alone does not establish broken recovery.
- A reproducible failure on a named Scrypath-owned boundary can become a material finding; a host-owned authorization or policy responsibility remains outside Scrypath scope unless separate evidence establishes otherwise.
- Possible grouped recovery proof must establish report → selected mutation → visible result; destructive index cutover may need its own candidate if its risk or oracle differs.
- External research favored shared-outcome milestones with separate risk/proof boundaries, accountable acceptance of risk, and bounded test/version lanes. The discussion explicitly treated visual/UI design as not applicable to this maintainer workflow.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 163-findings-and-bounded-follow-up*
*Context gathered: 2026-09-25*
