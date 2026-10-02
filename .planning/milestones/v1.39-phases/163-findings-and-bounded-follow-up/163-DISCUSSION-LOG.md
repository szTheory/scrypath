# Phase 163: Findings and Bounded Follow-up - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-25
**Phase:** 163-Findings and Bounded Follow-up
**Areas discussed:** Materiality threshold, Rank vocabulary, Follow-up grouping, Acceptance evidence detail

---

## Materiality threshold

| Option | Description | Selected |
|--------|-------------|----------|
| Confirmed defect or substantiated Scrypath-owned risk affecting a named job | Require observed/reproducible behavior or specific authoritative evidence of an affected risk. | ✓ |
| Also rank decision-relevant evidence gaps, but label them separately | Makes missing proof a ranked risk category. | |
| Rank defects, risks, evidence gaps, and opportunities together | One status/rank stream for unlike observations. | |

**User's choice:** Confirmed defect or substantiated Scrypath-owned risk affecting a named job.
**Follow-up choices:** Keep evidence gaps linked to baseline claims; investigate only if evidence could change a decision. Require observed/reproducible behavior or specific authoritative evidence to substantiate a defect/risk. Record confidence separately so it cannot numerically cancel severity.
**Notes:** Preserve gaps and opportunities as distinct classifications; don't promote a source-level suspicion into a confirmed finding.

---

## Rank vocabulary

| Option | Description | Selected |
|--------|-------------|----------|
| Critical / High / Medium-leverage / Low | Gate-aligned qualitative bands. | ✓ |
| Critical / High / Medium / Low | Conventional severity labels, but not exact gate wording. | |
| Numeric score with named severity bands | Weighted formula intended to increase apparent repeatability. | |

**User's choice:** Critical / High / Medium-leverage / Low, assigned through outcome/risk definitions and a concise rationale, without a formula.
**Follow-up choices:** A credible severe consequence can set a high band while frequency remains separate. Record cost qualitatively, adding concrete measurements when available.
**Notes:** Keep impact, frequency, confidence, applicable risk, implementation/regression cost, and recurring verification cost visible. Cost informs remedy and CI placement but does not lower severity.

---

## Follow-up grouping

| Option | Description | Selected |
|--------|-------------|----------|
| Group by shared user outcome, scope, and proof flow; split distinct risks | Each group must have common purpose and a common automated proof boundary. | ✓ |
| One finding per milestone | Isolates work but may duplicate planning and verification. | |
| Group mainly by code area or subsystem | Organizes by implementation location rather than user outcome. | |

**User's choice:** Group by outcome/scope/proof; split distinct risks.
**Follow-up choices:** Create a separate milestone for coordinated bounded work across multiple tasks. Rank sets urgency but not eligibility; require evidence, outcome, authorized scope, and practical automated acceptance. Keep non-qualifying reasons beside linked claims instead of a speculative backlog.
**Notes:** Routine/contained fixes can stay in the patch/PR lane. Medium/low-leverage work needs evidence that user value justifies lifecycle cost. Explicit scope-guard review still applies to prohibited capability classes.

---

## Acceptance evidence detail

| Option | Description | Selected |
|--------|-------------|----------|
| Claim-to-proof record with each selected finding/candidate | Keeps the user outcome, scope, and proof linked without new shared machinery. | ✓ |
| Machine-readable acceptance manifest for all candidates | Adds a global validation schema up front. | |
| Separate CI lane catalogue and promotion log | Tracks lane economics independently from each claim. | |

**User's choice:** Keep a claim-to-proof record with each selected finding/candidate.
**Follow-up choices:** Use the cheapest reliable layer with an observable outcome; integration/hosted proof only where needed. Promote to recurring CI only if repeated risk and confidence gained justify cost and the check is reliable/diagnosable. Include outcome, boundary, fixture/oracle, proof layer/command, and relevant receipt/operating details.
**Notes:** Do not add routine human UAT. Record a separate lane comparison only when CI is added or a trigger/blocking status changes.

---

## Research synthesis

Three advisor-researcher subagents compared the materiality/rank, milestone-grouping, and acceptance-evidence decisions across the project prompts and relevant OSS, Elixir/Phoenix, operations, compatibility, security, and DX perspectives. Consulted precedents include [GitHub milestones](https://docs.github.com/en/issues/using-labels-and-milestones-to-track-work/about-milestones), [OpenTelemetry stability](https://opentelemetry.io/docs/specs/otel/versioning-and-stability/), [GitLab risk management](https://handbook.gitlab.com/handbook/security/security-observations-risk-management/), [Phoenix testing guidance](https://github.com/phoenixframework/phoenix/blob/main/guides/testing/testing.md), and [Phoenix CI](https://github.com/phoenixframework/phoenix/blob/main/.github/workflows/ci.yml). The phase is maintainer-facing; UI/graphic design was not applicable.

## the agent's Discretion

- Choose a navigable source-linked findings/disposition artifact and concise IDs/columns while preserving Phase 162 as the canonical evidence index.
- Inspect/re-run only evidence needed for a decision; add no scorecard, schema, broad rerun, or recurring gate without demonstrated value.

## Deferred Ideas

None.
