# Milestone Context: Pre-Operator UI Quality Readiness Ratchet

**Status:** Owner-approved strategic intent; formal milestone requirements and roadmap not yet initialized.
**Source:** `.planning/reference/PRE-OPERATOR-UI-READINESS.md`

## Goal

Assess Scrypath's non-UI quality and adopter readiness across the whole product, then close the evidence-backed critical, high, and medium-leverage gaps in bounded milestones. Establish an auditable diminishing-return gate that identifies when ScrypathOps operator UI should become the next strategic focus.

## Agreed scope and preferences

- Begin with a holistic, evidence-led baseline. Reuse v1.37 and v1.38 proof where current and relevant; do not assume their bounded audits cover every quality dimension.
- Assess API/DX, core behavior, Ecto/Oban/Meilisearch/Phoenix/package integration, operational workflows, docs/examples/support, compatibility, security/privacy/dependencies, architecture/readability/performance, tests, and CI cost.
- After the baseline, rank findings by adopter impact, severity/frequency, confidence, implementation/regression cost, and recurring verification cost. Create later milestones only for worthwhile confirmed gaps.
- Evidence-backed bounded runtime/API improvements are allowed when repeated adopter need supports them and existing scope guards are explicitly reviewed. A prohibited capability needs a separate owner-approved scope decision.
- Target zero routine human verification/UAT. Prefer the cheapest reliable automated proof and add recurring CI only when its confidence justifies runtime and maintenance cost.
- Do not start operator UI work as part of the pre-UI ratchet. ScrypathOps is the intended next focus after readiness is declared and maintainer time is available.

## Exit threshold

Mark **READY FOR OPERATOR UI** only after every non-UI dimension has been assessed, no critical/high/medium-leverage gap remains unresolved, important adopter claims have suitable automated evidence, CI/release/planning truth is healthy, and all remaining non-UI opportunities are dispositioned as low-leverage, speculative, unsupported, or higher-cost than likely benefit.

The current readiness status is **NOT READY — baseline not yet assessed**. See the readiness record for the full criteria and evidence ledger structure.
