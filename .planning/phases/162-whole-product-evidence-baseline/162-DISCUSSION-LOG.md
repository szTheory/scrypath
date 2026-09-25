# Phase 162: Whole-Product Evidence Baseline - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-25
**Phase:** 162-Whole-Product Evidence Baseline
**Areas discussed:** Representative adopter roles and boundaries; Evidence freshness and sufficiency

---

## Representative adopter roles and boundaries

| Option | Description | Selected |
|--------|-------------|----------|
| Capability-only inventory | Trace individual public capabilities and evidence, but does not by itself show lifecycle handoffs. | |
| One canonical Phoenix application | Consumer-shaped end-to-end proof, but can overrepresent Phoenix and omit operator/release jobs. | |
| Bounded lifecycle sample | Four role lenses with explicit lifecycle stages and integration seams. | ✓ |

**User's choice:** Accepted the recommended four-role approach: first-hour application integrator, application feature owner, production operator/platform owner, and library maintainer/releaser. The downstream searcher is an outcome of the feature owner's job; host authorization and presentation remain host responsibilities.
**Notes:** User requested subagent research with pros/cons/tradeoffs, ecosystem idioms and precedents, and a coherent DX-focused recommendation. A typed GSD advisor researcher compared this decision against the project authority, prior evidence, guides, and relevant prompts.

---

## Evidence freshness and sufficiency

| Option | Description | Selected |
|--------|-------------|----------|
| Fixed age windows | Simple policy, but age does not reliably indicate validity. | |
| Rerun the whole portfolio | Broad snapshot, but adds recurring cost and conflicts with selective reuse policy. | |
| Claim-specific, event-triggered | Evidence is sufficient for a bounded claim; relevant change triggers narrow revalidation. | ✓ |

**User's choice:** Accepted the recommended claim-specific sufficiency and event-triggered freshness policy, with visible provenance, boundaries, limitations, and narrow revalidation after relevant changes.
**Notes:** No blanket age windows, whole-suite reruns, new required CI lanes, or routine human UAT. Missing proof remains insufficient or unknown, not a defect by inference. A typed GSD advisor researcher compared the alternatives and relevant verification idioms.

---

## the agent's Discretion

- Choose an artifact structure and identifiers that keep one readable canonical baseline index and link to detailed evidence.
- Choose narrow, decision-relevant inspections or reruns consistent with project scope and verification cost.

## Deferred Ideas

None.
