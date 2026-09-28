# Phase 167: Dated Readiness and Closeout - Context

**Gathered:** 2026-09-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Produce a new, uniquely dated, source-bounded assessment of the approved six-condition pre-operator-UI readiness gate and reconcile v1.39 closeout, package/release, support, planning, and current task-owned cleanup truth. Keep source-evidence dates distinct from the new assessment date. Preserve Phase 164's condition 3/6 UNKNOWN rows and overall NOT READY decision as historical evidence. The new assessment records what its sources support; missing or insufficient evidence may leave a condition UNKNOWN and readiness NOT READY. A passing result recommends a later ScrypathOps focus but does not authorize or start UI work. Phase 167 adds no product capability, forced Hex release, broad matrix, routine human UAT, or new required CI lane.

</domain>

<decisions>
## Implementation Decisions

### Readiness gate and evidence semantics
- **D-01:** Use the six condition definitions and operating rules in `.planning/reference/PRE-OPERATOR-UI-READINESS.md` without redefining or weakening them. Evaluate each condition independently as PASS, FAIL, or UNKNOWN. Missing, stale, or insufficient evidence is UNKNOWN; evidence that contradicts a condition is FAIL.
- **D-02:** Keep the prior Phase 164 dated assessment, including its condition 3/6 UNKNOWN entries and overall NOT READY decision, unchanged. Record evidence dates separately from the new assessment date. Overall readiness is READY FOR OPERATOR UI only if all six current conditions pass and no unresolved Critical, High, or Medium-leverage finding remains; otherwise it is NOT READY.
- **D-03:** Treat structural checkers as record-shape validation only. They do not establish source truth, semantic completeness, owner approval, or readiness. Link evidence to the exact source, scenario, and receipt identity, and state the claim boundary and freshness limit for each claim.

### Condition 3 and v1.40 workflow evidence
- **D-04:** Reconcile Phase 165 and 166 receipts only within their named contracts and workflows. Phase 166's host-membership, local package-artifact, repair-to-visible-search, and C-09 freshness records are evidence for their stated scenarios; they do not prove arbitrary host authorization, public Hex installation, all deletion/recovery semantics, or general production guarantees.
- **D-05:** Reuse the historical C-09 hard-delete receipt only after a relevant-path freshness comparison against the new assessment source. If an invalidator exists, use targeted fresh evidence or record the bounded claim as UNKNOWN. Recheck freshness at the final Phase 167 source SHA as required for final closeout; do not edit tracked artifacts merely to record the external result.
- **D-06:** Keep the 11 unresolved probe rows and six descriptor-less prohibitions from Phase 166 visible and within the already-approved six-condition meanings. They are not additional gate criteria and must not be promoted into passes or defects without evidence.

### Condition 6 and exact-source closeout
- **D-07:** Trace archived v1.39 closeout, package/release, support, and planning claims to their actual source identities, distinguishing the planning tag from package version and closeout receipt. Explicitly disposition the observed release-reference mismatch, the accepted v1.39 planning metadata debt, and only Phase 167-owned cleanup or verification debt. Preserve unrelated local state and historical records.
- **D-08:** Bind every v1.40 software acceptance claim to automated, scenario-specific evidence at its exact source SHA. The named advisory-lane scenario must pass for its recorded source while remaining advisory. Use the existing exact-SHA closeout topology and its two-stage candidate/final-source discipline; do not add a required service lane, broaden the matrix, or require routine human UAT.

### the agent's Discretion
- Choose a concise dated assessment and cleanup-inventory layout consistent with the existing readiness authority and Phase 164 record.
- Choose focused structural/source checks and links that validate the new record without presenting them as semantic readiness proof.
- Inventory task-owned worktree, branch, generated output, temporary file, service, and verification state using repository ownership evidence; do not classify pre-existing or unrelated state as Phase 167 debt.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and product authority
- `.planning/ROADMAP.md` — Phase 167 goal, acceptance criteria, and fixed boundary.
- `.planning/REQUIREMENTS.md` — GATE-04, CLOSE-03, VERIFY-02 contracts and v1.40 exclusions.
- `.planning/PROJECT.md` — current v1.40 scope, readiness posture, accepted metadata debt, and automation-first policy.
- `.planning/STATE.md` — Phase 165/166 handoffs, exact-source evidence status, and unresolved rows passed to Phase 167.
- `.planning/reference/PRE-OPERATOR-UI-READINESS.md` — authoritative six conditions, status meanings, operating rules, and unchanged Phase 164 assessment.

### Historical assessment and closeout records
- `.planning/milestones/v1.39-phases/164-readiness-gate-and-reconciliation/164-CONTEXT.md` — locked gate semantics, evidence limits, and closeout decisions from Phase 164.
- `.planning/milestones/v1.39-phases/164-readiness-gate-and-reconciliation/164-01-SUMMARY.md` — Phase 164 assessment and task-owned cleanup precedent.
- `.planning/milestones/v1.39-phases/164-readiness-gate-and-reconciliation/164-VERIFICATION.md` — Phase 164 verification claims and limits.
- `.planning/milestones/v1.39-phases/164-readiness-gate-and-reconciliation/check_readiness.py` and `test_check_readiness.py` — structural assessment checker and its focused tests; neither certifies evidence truth.
- `.planning/milestones/v1.39-MILESTONE-AUDIT.md` — accepted v1.39 planning metadata debt and its exact disposition.
- `.planning/milestones/v1.39-ROADMAP.md` and `.planning/milestones/v1.39-REQUIREMENTS.md` — archived v1.39 scope and release/planning identities.
- `.planning/milestones/v1.38-phases/161-release-and-tidy-closeout/161-RELEASE-EVIDENCE.md` — exact-source package and publication receipt reused by the historical assessment.

### v1.40 acceptance evidence
- `.planning/phases/165-public-tenant-and-facet-contracts/165-CONTEXT.md` — public tenant/facet boundaries and evidence limits.
- `.planning/phases/165-public-tenant-and-facet-contracts/165-02-SUMMARY.md` — reproduced facet correction and its service/package follow-up.
- `.planning/phases/166-host-tenant-and-repair-evidence/166-CONTEXT.md` — host, repair, package, and C-09 reuse decisions.
- `.planning/phases/166-host-tenant-and-repair-evidence/166-EVIDENCE.md` and `.planning/phases/166-host-tenant-and-repair-evidence/166-EVIDENCE.json` — exact scenario, source, task, job, and claim-boundary records.
- `.planning/phases/166-host-tenant-and-repair-evidence/166-03-SUMMARY.md`, `.planning/phases/166-host-tenant-and-repair-evidence/166-VERIFICATION.md`, and `.planning/phases/166-host-tenant-and-repair-evidence/166-SOURCE-AUDIT.md` — completion, source review, and remaining Phase 167 handoff.

### Repository verification and release practice
- `prompts/scrypath-milestone-ratchet-roadmap.txt` — project-specific readiness, release, closeout, and repository-hygiene guidance.
- `prompts/elixir-oss-lib-ci-cd-best-practices-deep-research.md` — OSS CI/release guidance consulted for the exact-source evidence boundary.
- `CONTRIBUTING.md` — canonical closeout command, exact-SHA candidate/final procedure, and required/advisory lane definitions.
- `.github/workflows/ci.yml` — required, advisory, and exact-SHA closeout-attestation workflow topology.
- `scripts/ci_monitor.cjs` — hosted closeout orchestration and source-selection behavior.
- `guides/support-and-compatibility.md` — current published support contract to reconcile.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `.planning/milestones/v1.39-phases/164-readiness-gate-and-reconciliation/check_readiness.py` and its Python tests validate the previous dated record's structure and safe local evidence links.
- `test/scrypath/readiness_contract_test.exs` protects the canonical support-guide routing and existing support/verification documentation contract.
- `scripts/ci_monitor.cjs` and the `closeout-attestation` job in `.github/workflows/ci.yml` provide the existing exact-SHA hosted closeout path.
- Phase 166's Markdown/JSON evidence pair preserves scenario-specific host, package-artifact, repair, and historical-delete receipt identities.

### Established Patterns
- Keep one authoritative readiness program with separately dated assessment sections and links to canonical evidence rather than duplicating receipts.
- Record the inspected source identity, relevant-path freshness comparison, scenario/receipt identity, dates, limits, and ownership for each claim.
- The advisory `phoenix-example` job can supply evidence for its exact source without becoming a required merge gate. Required closeout remains bounded to the existing required jobs plus coverage and attestation.
- The readiness structural checker proves only the declared record contract; source review and scenario evidence establish the separate claims.

### Integration Points
- The dated assessment joins the readiness authority, Phase 162/163 baseline and finding records, Phase 165/166 acceptance evidence, v1.39 release/package/support identities, current CI workflow, and Phase 167 cleanup inventory.
- Changes are planning/evidence and verification work; no Scrypath runtime API or backend integration is in scope.

</code_context>

<specifics>
## Specific Ideas

- Keep the source date and assessment date separate, and preserve Phase 164's historical rows and decision verbatim.
- Reassess current condition 3/6 evidence using Phase 166's exact-source receipts and their explicit limits; do not assume the new result is READY.
- Record exact final-source closeout and current task-owned cleanup without rewriting prior assessments, tags, receipts, or unrelated workspace state.
- A READY result remains a recommendation for a later focus; maintainer availability and a separate scope decision still govern any ScrypathOps work.

</specifics>

<deferred>
## Deferred Ideas

No new ideas were added. Operator UI, auth/tenant-authorization product work, public backend abstraction, broad compatibility matrices, new required service lanes, routine human UAT, and a forced Hex release remain outside this phase.

</deferred>

---

*Phase: 167-dated-readiness-and-closeout*
*Context gathered: 2026-09-27*
