# Phase 32: Planning and state hygiene - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.  
> Decisions are captured in **`032-CONTEXT.md`**.

**Date:** 2026-04-18  
**Phase:** 32 — Planning and state hygiene  
**Areas discussed:** UAT gap row; Quick-task stubs; Where reasons live; Milestone sequencing (all four, research-synthesized)

**Method:** Three parallel research passes (OSS planning hygiene; UAT gap / shift-left; spike & quick-task artifact lifecycle) plus maintainer synthesis. *Note: `gsd-sdk query` helpers were unavailable in-session; todo cross-reference was skipped.*

---

## 1. UAT gap row (Phase 18 / `18-UAT.md`)

| Approach | Description | Selected |
|----------|-------------|----------|
| Delete `18-UAT.md` | Remove historical UAT map | |
| Terminalize STATE only | Mark row resolved/obsolete with pointers to verification + audit | ✓ |
| Open GitHub issue | Track as product debt | |

**User's choice:** One-shot playbook — keep `18-UAT.md` as evidence; terminalize `STATE` row; fix any other doc that still lists Phase 18 as an open UAT gap.  
**Notes:** Aligns with “close gaps with evidence, not vibes” and single owner for open vs closed.

---

## 2. Quick-task rows (`260416-eoj`, `260416-if2`)

| Approach | Description | Selected |
|----------|-------------|----------|
| Leave `pending_triage` | Keeps dual state with `SUMMARY.md` | |
| Terminalize + pointer to SUMMARY | Obsolete/resolved with path | ✓ |
| New GitHub issues | Mirror completed work | |

**User's choice:** Terminalize immediately; keep `.planning/quick/...` trees; no issues for completed stubs.  
**Notes:** Matches ADR-like permanence + explicit `status` frontmatter pattern.

---

## 3. Where terminal reasons live

| Approach | Description | Selected |
|----------|-------------|----------|
| STATE only | Single ledger | Partial |
| STATE + REQUIREMENTS flip | Traceability without prose duplication | ✓ |
| Issues-first | Off-repo tracking | |

**User's choice:** STATE canonical prose for triage; REQUIREMENTS checkbox + table cell when closing AUDT-01; issues only for real follow-ups.

---

## 4. Milestone close sequencing

| Approach | Description | Selected |
|----------|-------------|----------|
| Scatter updates | Edit files across weeks | |
| Atomic hygiene pass | STATE + REQUIREMENTS + audit in one commit/PR | ✓ |

**User's choice:** One atomic commit/PR for closure; refresh `v1.6-MILESTONE-AUDIT.md` in same window.

---

## Claude's Discretion

Exact terminal **label** strings (`obsolete` vs `resolved`) left to planner if semantics match D-08..D-12.

## Deferred Ideas

None recorded.
