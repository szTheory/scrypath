# Phase 98: Surface Reconciliation and Adopter Flow Clarity - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in `98-CONTEXT.md`; this log preserves alternatives considered.

**Date:** 2026-05-27
**Phase:** 98-surface-reconciliation-and-adopter-flow-clarity
**Areas discussed:** Surface wording strictness, proof-boundary detail placement, intake evidence/escalation clarity, phase-98 gate shape

---

## Surface wording strictness and authority boundaries

| Option | Description | Selected |
|--------|-------------|----------|
| Route-only everywhere | Entry docs mostly route to canonical guide, minimal inline contract text | |
| Layered strictness | Canonical full policy in support guide; concise fixed restatements in entry surfaces; route to owner | ✓ |
| Broad restatement everywhere | Each major surface carries full contract wording | |

**User's choice:** Layered strictness (decisive recommendation selected)
**Notes:** Chosen to balance discoverability and drift resistance. This keeps one canonical owner while preserving one-hop clarity in `README.md` and `CONTRIBUTING.md`.

---

## Proof-boundary detail placement (fast vs live)

| Option | Description | Selected |
|--------|-------------|----------|
| Duplicate full runbook broadly | Repeat command/env details across all surfaces | |
| Support-guide-only canonicalization | Put all proof details in support guide | |
| Two-tier canonical model | Policy in support guide, live runbook in example README, executable truth in verify task | ✓ |

**User's choice:** Two-tier canonical model (decisive recommendation selected)
**Notes:** Chosen for least surprise and operational honesty. Prevents env matrix drift while keeping local runbook details at the runnable surface.

---

## Outside-adopter intake evidence and escalation clarity

| Option | Description | Selected |
|--------|-------------|----------|
| Docs-only tightening | Improve prose/checklists but keep flexible intake shape | |
| Structured evidence + explicit routing matrix | Deterministic required evidence fields and class-to-action routing | ✓ |
| Automation-heavy triage tooling | Add higher automation/bot-driven triage now | |

**User's choice:** Structured evidence + explicit routing matrix (decisive recommendation selected)
**Notes:** Chosen for actionable maintainer triage without adding unnecessary phase-98 operational complexity.

---

## Phase-98 verify gate strictness

| Option | Description | Selected |
|--------|-------------|----------|
| Maximal monolithic strictness | Broad hard-fail prose parity checks everywhere | |
| Layered strict core | Focused hard gate on high-risk contract tokens and parity points | ✓ |
| Minimal advisory-only gate | Light checks now, defer most enforcement later | |

**User's choice:** Layered strict core (decisive recommendation selected)
**Notes:** Chosen to keep trust hardening strong while avoiding brittle/noisy CI behavior that harms release-train stability.

---

## Cross-ecosystem lessons applied

- Keep quick-start surfaces concise and route to deeper canonical docs (observed in successful search-library docs patterns).
- Preserve explicit consistency-mode boundaries (fast vs live proof) and avoid implying stronger guarantees than verified.
- Avoid duplicated authoritative policy text across multiple surfaces; duplicate pointers, not full policy bodies.
- Prefer stable token/anchor checks for docs contracts over paragraph snapshots to reduce false-positive CI churn.

## Claude's Discretion

- Exact final wording and anchor labels per surface while preserving locked decisions.
- Test placement across existing docs/readiness suites versus any new phase-98-focused tests.
- Final issue-template or intake-template shape details provided required evidence fields and routing semantics remain explicit.

## Deferred Ideas

- Automation-heavy intake triage bots (beyond phase-98 scope needs).
- Broader repository-wide prose linting outside the high-risk contract map.

