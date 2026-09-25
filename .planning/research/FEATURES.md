# Feature Landscape

**Domain:** Whole-product non-UI quality and adopter-readiness assessment for an established Ecto-native Elixir search library
**Researched:** 2026-09-25
**Confidence:** HIGH for the audit scope and gate (owner-approved program); MEDIUM for individual evidence sufficiency until the baseline inspects the linked artifacts and current code.

> This research informs audit scope only. It does not add product capabilities or requirements. The formal milestone requirements must be derived from the approved readiness program and concrete findings, not from this feature inventory.

## Table Stakes

For this readiness assessment, “table stakes” means capability areas and evidence needed to make a credible whole-product readiness decision. These are dimensions to assess, not assertions that gaps exist.

| Capability / evidence area | Why expected | Assessment complexity | Notes |
|---|---|---:|---|
| Public API contract and developer ergonomics | An Ecto-native library must make its supported APIs, compatibility expectations, and errors understandable and stable for adopters. | Medium | Inspect public docs, API tests, compatibility evidence, and error behavior. Do not expose internal structs or invent new public surface. |
| Indexing and search lifecycle correctness | The core promise depends on correct writes, deletes, search, and lifecycle operations across supported flows. | High | Assess declared schemas/projections, inline/manual/Oban synchronization, related data, tenancy, search/facets/federation, settings, and recovery against existing tests and integration evidence. Reuse proof where it covers the claim. |
| Supported ecosystem and packaged-consumer seams | Ecto/Phoenix teams need the library to compose with supported Ecto, Oban, Meilisearch, runtime, and published-package environments. | High | v1.38 covers package-backed Phoenix scenarios and release parity, but the program requires checking representative supported combinations and seams beyond that package proof. |
| Operational honesty and recoverability | Eventual consistency and failed work must be visible, bounded, and recoverable without misleading operators or adopters. | Medium | Assess observability, failure reporting, backfill/reindex safety, recovery guidance, and supportability; rely on executable evidence or documented contracts as appropriate. |
| First-hour and ongoing adopter experience | Minimal setup and Phoenix-friendly adoption are central product values; examples and intake must help users diagnose real issues. | Medium | Assess setup path, documentation/examples, diagnostics, support and issue intake, and whether published instructions match executable behavior. |
| Security, privacy, dependency and release integrity | Search data, credentials, dependency graphs, and release artifacts cross trust boundaries and need explicit evidence. | High | Review configuration boundaries, secret handling, dependency health, workflow permissions, package provenance, and release/source parity. Reconcile prior audits before commissioning repeated checks. |
| Architecture, maintainability, measured performance, and verification signal | Long-term reliability depends on understandable boundaries, evidence-led optimization, and CI whose recurring cost buys meaningful confidence. | High | Assess architecture/readability, relevant performance measurements, test coverage and signal quality, CI runtime/maintenance cost, and existing required/advisory lane boundaries. Do not promote speculative benchmarks or duplicate proof. |
| Capability-by-evidence ledger and decision record | Readiness is not auditable unless each area records the adopter job, source/proof, freshness/sufficiency, uncertainty, and disposition. | Medium | This is the baseline artifact pattern required by the program; it allows reuse without treating prior evidence as universal coverage. |
| Evidence-ranked bounded gap closure and automated acceptance | Closing worthwhile gaps requires prioritization and deterministic proof tied to each acceptance claim. | High | For confirmed findings, record provenance, affected job, impact/frequency, confidence, compatibility/security/data risk, implementation/regression cost, CI cost, and recommendation. Prioritize critical/high risks, then evidence-supported medium-leverage work. |
| Explicit diminishing-return gate | The strategic transition must be based on assessed dimensions, resolved or explicitly accepted material findings, suitable automated workflow proof, lean green CI, dispositioned remaining opportunities, and clean release/support/planning truth. | Medium | Keep status NOT READY until every gate condition is evidenced. Passing recommends ScrypathOps as the next focus; it does not automatically start UI work. |

## Differentiators

| Capability / evidence practice | Value proposition | Assessment complexity | Notes |
|---|---|---:|---|
| Reuse v1.37 and v1.38 evidence selectively | Avoids redundant proof while expanding from bounded engineering/package audits to whole-product adopter readiness. | Medium | v1.37 addressed runtime safety, architecture, test/verification commands, CI efficiency, supply-chain/release proof, and measured performance. v1.38 established package-backed Phoenix proof and publication/parity evidence. Verify claim-level coverage and currency before reuse. |
| Lifecycle-oriented capability matrix | Connects code/tests/docs/hosted evidence to actual adopter jobs and failure boundaries rather than producing an abstract quality score. | Medium | Build the matrix from the seven named program dimensions; show limits and unknowns. |
| Evidence-weighted dispositions | Prevents speculative polish from becoming roadmap debt while preserving a route for proven adopter/API gaps. | Medium | Close, accept with explicit rationale/owner decision, defer with reason and revisit trigger, or reject as unsupported/out of scope. Scope-guarded capability classes require explicit owner-approved scope change before implementation planning. |
| Verification matched to claim and cost | Gives maintainers recurring confidence without burdening every change with expensive duplicate lanes. | Medium | Map claims to the cheapest reliable layer; use CI for recurring checks when confidence justifies runtime and maintenance cost; keep costly lower-frequency proof advisory or scheduled when appropriate. |

## Anti-Features

| Anti-feature | Why avoid | What to do instead |
|---|---|---|
| Treat the readiness assessment as a new product-feature roadmap | The approved intent is a baseline, evidence-ranked closure, and a decision gate; no new customer-facing capability is named. | Derive implementation slices only from confirmed findings and the accepted program requirements. |
| Assume v1.37/v1.38 imply all whole-product dimensions are ready | Both are bounded efforts; neither claims full adopter-readiness coverage. | Reuse evidence per claim, record uncovered boundaries, freshness, and limits. |
| Re-run every passing test or service lane by default | Repeated proof without a decision-relevant question adds time and CI cost without necessarily increasing confidence. | Identify the precise uncovered claim first, then select the smallest proof that resolves it. |
| Add speculative API/runtime breadth or prohibited retrieval/backend categories | This would exceed the approved audit and collide with existing scope authority. | Keep public behavior stable by default; consider runtime/API gaps only when supported by reviewed evidence and explicit scope-guard review. |
| Turn every observation into a milestone or required CI job | Possibility and local polish are not evidence of adopter value; excess gates can weaken signal and slow the release train. | Rank by impact, likelihood/confidence, risk, implementation/regression cost, and CI lifecycle cost; defer or reject low-value items with rationale. |
| Declare READY based on subjective sign-off or pending routine UAT | The repository policy requires machine-verifiable acceptance and no routine human UAT. | Automate software acceptance; hand off only irreducible credentials, permissions, product decisions, or physical-world checks. |
| Treat readiness approval as automatic authorization to begin operator UI work | The exit gate is a recommendation; maintainer availability still governs timing. | Record the readiness decision and recommendation; schedule operator UI separately when appropriate. |

## Feature Dependencies

```text
Evidence inventory and capability-by-evidence matrix
  → sufficiency/freshness assessment and visible uncertainty
  → evidence-ranked finding ledger and explicit dispositions
  → bounded remediation slices (only where evidence supports action)
  → automated acceptance evidence and clean closeout
  → all six exit-gate conditions evidenced
  → READY FOR OPERATOR UI recommendation (not automatic UI execution)
```

Prior milestone evidence is an input to the inventory, not a prerequisite for accepting every readiness claim:

```text
v1.37 quality ledger / audit ─┐
                              ├→ claim-level reuse, gap identification, and freshness check
v1.38 package/release proof ──┘
```

## MVP Recommendation

Prioritize:

1. Build the whole-product capability-by-evidence baseline across the seven named non-UI dimensions, using existing v1.37/v1.38 proof only where it directly supports a current claim.
2. Create an auditable findings ledger that distinguishes confirmed gaps, uncertainty, accepted risk, defer/reject rationale, and scope-guard review needs.
3. Close only evidence-backed critical/high and worthwhile medium-leverage gaps in bounded slices, with acceptance claims mapped to automated proof before implementation.
4. Evaluate the six explicit program exit conditions and preserve NOT READY until each condition has linked evidence and no unresolved critical/high/medium-leverage finding remains.

Defer: new public APIs, backend/search breadth, reusable UI surfaces, broad CI promotion, and additional ScrypathOps UI implementation. These are not readiness capabilities established by the program and remain subject to existing scope guards, adopter evidence, and separate decisions.

## Sources

- `.planning/reference/PRE-OPERATOR-UI-READINESS.md` — approved program dimensions, evidence-ranked closure, operating rules, and six-condition exit gate (primary authority).
- `.planning/PROJECT.md` — milestone target features, product boundaries, automation-first verification policy, current status, and v1.37/v1.38 summaries.
- `.planning/reference/QUALITY-LEDGER.md` — v1.37 findings, evidence and dispositions, final proof, and explicit excluded UI judgment.
- `.planning/milestones/v1.38-REQUIREMENTS.md` — package-backed adopter proof scope and completed requirements.
- `.planning/reference/MILESTONE-ARC.md` — near/mid/long horizons and readiness transition posture.
- `.planning/reference/milestone-candidates.md` — evidence gates, conditional candidates, and selection/closeout rules.

*Research boundary: local planning sources were used because this work defines an internal audit scope from owner-approved project evidence, not an external product/ecosystem comparison. No new requirements are implied by this landscape.*
