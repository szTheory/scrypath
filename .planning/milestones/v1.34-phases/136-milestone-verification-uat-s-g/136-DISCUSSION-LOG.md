# Phase 136: Milestone verification & UAT `[S] [G]` - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-28
**Phase:** 136-milestone-verification-uat-s-g
**Areas discussed:** Binding proof gates, Evidence artifact shape, Milestone audit threshold, Human UAT flow

---

## Binding Proof Gates

| Option | Description | Selected |
|--------|-------------|----------|
| Layered closeout | Mix/LiveView gates + Playwright/axe/computed-style proof + screenshots + human UAT. | ✓ |
| Automation-only closeout | Static contracts, ExUnit/LiveView tests, computed-style, and axe gates only. | |
| Promote full browser bundle to permanent CI | Make all Phase 136 Playwright/browser proof required beyond this milestone. | |

**User's choice:** Discuss/consider all and provide researched, coherent recommendations without pushing decisions back to the user.
**Notes:** Subagent research and local artifact review converged on layered closeout. Automation-only would under-prove gallery/UAT requirements; permanent CI promotion would contradict the current advisory posture for expensive browser proof.

---

## Evidence Artifact Shape

| Option | Description | Selected |
|--------|-------------|----------|
| Reports + manifest, generated evidence ignored | Commit Markdown/JSON summaries and keep PNGs/traces/raw reports as generated artifacts. | ✓ |
| Commit binary gallery assets | Add screenshots directly to git for durable review. | |
| Report-only audit | Skip detailed artifact manifest and rely on command summaries. | |

**User's choice:** Recommendation-first synthesis.
**Notes:** Selected artifact architecture: `136-DUALVERIFY-REPORT.md`, `136-ARTIFACT-MANIFEST.json`, `136-BEFORE-AFTER.md`, `136-MILESTONE-AUDIT.md`, and `136-UAT.md`. This keeps repo hygiene while preserving auditability via paths, counts, checksums, and command provenance.

---

## Milestone Audit Threshold

| Option | Description | Selected |
|--------|-------------|----------|
| Must-fix only for trust/accessibility/theme blockers | Fix failing gates, AA/focus/reduced-motion/stale-asset issues, or visual defects that block trust/JTBD. | ✓ |
| Fix every visual nit before closeout | Treat UAT as another polish phase. | |
| Accept all green automation regardless of perceptual issues | Close if tests pass, even if human review finds trust-impacting visual defects. | |

**User's choice:** Recommendation-first synthesis.
**Notes:** Must-fix thresholds are now explicit in CONTEXT.md. Any source fix requires rerunning affected gates and recapturing affected screenshots. Aesthetic nits that do not affect trust, scanability, accessibility, or parity are deferred.

---

## Human UAT Flow

| Option | Description | Selected |
|--------|-------------|----------|
| Bounded JTBD-based UAT | Dark-first six-surface review, light parity check, system-dark evidence, task nouns/events/verbs. | ✓ |
| Freeform owner click-through | Let reviewer explore without a checklist. | |
| No human UAT | Rely on automated proof and reports. | |

**User's choice:** Recommendation-first synthesis.
**Notes:** UAT is scoped to the operator question: "Can I trust search right now, and where do I go next?" It must inspect Control Room, Posture, Failed Sync, Sync/Drift, Search, Playbooks, theme toggle, command palette, flash, focus, and key seeded states.

---

## Claude's Discretion

- Exact artifact-manifest schema is delegated to planning/execution, provided it includes paths, counts, checksums, source commit, command provenance, and generated-vs-committed status.
- The planner may choose whether final contrast evidence lives inside `136-DUALVERIFY-REPORT.md` or a separate `136-CONTRAST-REPORT.md`.
- The planner may add a thin proof harness if it materially reduces stale-server or missed-command risk.

## Deferred Ideas

- Full system-dark screenshot matrix promotion.
- Permanent required CI promotion for the full browser proof bundle.
- Additional gallery automation or artifact upload workflow.
- New runtime/operator capability, nav IA, or broader admin-product expansion.
