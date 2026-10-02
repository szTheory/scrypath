# Phase 168: Dependency Security and Reliable Verification - Context

**Gathered:** 2026-09-28
**Status:** Planning complete; five plans verified, ready to execute
**Provenance:** Transcribed from the maintainer-approved v1.41 roadmap and specialist review, followed by the request to preserve context and advance directly to the next concrete GSD step. This is a handoff of approved decisions, not a new discussion or implementation plan. Approval commit: `c14fd9c`; research commit: `d6fa8ab`.

<domain>
## Phase Boundary

Deliver MINT-01, MINT-02, MINT-03 and DELIV-01: remediate all four maintained dependency graphs, deliver the mounted-readiness correction, prove the actual resolved graphs and prevent recurring audit omissions economically. Selected changes must reach verified public `main`. Planning is complete with five checked plans across four waves; implementation has not started.
</domain>

<decisions>
## Approved Decisions

### Security and effective dependency proof
- **D-01:** Cover root, Phoenix example, ecommerce example and standalone Ops locks. Target Mint 1.11.0+ after refreshing official advisories; include necessary compatible HPAX/subtree changes. Do not substitute ignores or inferred risk acceptance for remediation.
- **D-02:** Prove actual resolved dependencies after Phoenix package staging and reject unexpected Hex-lock drift while allowing the intended Scrypath provenance substitution. Reuse appropriate root/backend, both Phoenix modes, mounted ecommerce and standalone Ops evidence. Ops is absent from manual closeout dispatches; obtain its applicable PR/main result.
- **D-03:** Audit the explicit four-graph inventory in the existing advisory lane, with a cheap omission guard. Preserve locks, report each graph and any ignored/incomplete result, propagate failure, avoid a duplicate root scan and measure incremental fetch/runtime cost. Keep repository-only orchestration outside the shipped package surface. Add no required CI job, broad matrix or exploit suite.

### Delivery and source identity
- **D-04:** Deliver the existing mounted-readiness fix early with focused regression and mounted behavior proof. Use a clean refreshed public-main base through supported GSD isolation. Preserve unrelated local changes; never push the accumulated unpublished branch as the delivery unit.
- **D-05:** Completion requires selected fixes merged with required candidate checks and green post-merge evidence, plus the named advisory/path-selected proof. Keep candidate, merge-ref, squash-main, local-package and published-package identities distinct. Prepared PRs or blocked merges remain incomplete delivery; do not fabricate trust-gate approval.
- **D-06:** Preserve the Ecto-first/Meilisearch-first library boundary and host-owned locks. No new direct Mint dependency policy, public capability, compatibility promise or UI implementation is selected. Ops dependency remediation does not authorize operator UI work.

### Planner Discretion
- Choose coherent PR grouping, whether startup stabilization precedes the security slice, supported isolation setup, audit orchestration, package-lock proof implementation and focused automated verification commands.
- Start from the completed upstream review. Phase 168 research and plan checking are recorded in `168-RESEARCH.md` and the five checked plans; refresh mutable facts before acting and do not repeat the milestone fanout or whole-product assessment.
- Existing code/proof may be reused after relevant-source comparison. Choose checks for meaningful happy, failure and boundary behavior and recurring confidence per runtime cost.
</decisions>

<canonical_refs>
## Canonical References

Read these before planning; paths are repository-relative.

- `.planning/REQUIREMENTS.md` — MINT-01/02/03 and DELIV-01 acceptance boundaries.
- `.planning/ROADMAP.md` — Phase 168 criteria, dependencies and later-phase boundaries.
- `.planning/STATE.md` — current position, preserved local changes and source/evidence limits.
- `.planning/research/v1.41/SUMMARY.md` — approved synthesis, alternatives, change ledger and downstream discretion.
- `.planning/research/v1.41/SECURITY-REVIEW.md` — official advisory provenance, four-graph inventory and proof gaps; use current requirement numbering from REQUIREMENTS.md.
- `.planning/research/v1.41/DELIVERY-REVIEW.md` — dated branch inventory, existing fixes and public-main delivery constraints.
- `.planning/debug/resolved/ecommerce-mounted-readiness.md` — existing local diagnosis and focused evidence, currently uncommitted; do not assume it is present in a clean public-main checkout.
- `CONTRIBUTING.md` and `docs/releasing.md` — existing verification and delivery procedures.
- `prompts/scrypath-milestone-ratchet-roadmap.txt` — durable maintenance, automation and diminishing-return principles.
- `prompts/elixir-oss-lib-ci-cd-best-practices-deep-research.md` and `prompts/elixir-opensource-libs-best-practices-deep-research.md` — relevant ecosystem guidance; current source, approved scope and primary advisories take precedence over older suggestions.
</canonical_refs>

<deferred>
## Later Work

- Phase 169: tenant/facet fix delivery, remaining owned-delta dispositions and finite bot PR cohort.
- Phase 170: focused docs, warranted patch/parity and durable terminal six-condition readiness decision.
- Operator UI: only after a fresh passing gate, maintainer availability and separate scope approval.

Do not delay the Phase 168 security correction for bulk historical planning reconciliation or bot triage.
</deferred>
