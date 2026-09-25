# Milestone Arc

## Current arc: Release train idle

**Status:** no active milestone; v1.38 Packaged Adopter Proof is complete and archived.
**Current release:** Scrypath 0.3.13, published and parity-verified.
**Approved next strategic initiative:** establish whole-product non-UI quality readiness before further ScrypathOps work. No milestone is active; create its formal GSD requirements and roadmap from `.planning/MILESTONE-CONTEXT.md`.
**Default:** keep `main` green, maintain support/package/proof truth, and release when warranted.

## Near, mid, and long horizons

These are evidence gates, not dated commitments. Refresh them at each milestone boundary.

- **Near — baseline and urgent gaps:** formally start the approved readiness milestone, inventory non-UI quality dimensions against existing evidence, and close worthwhile critical/high-impact gaps. Keep normal maintenance and release hygiene active.
- **Mid — evidence-ranked ratchet:** group confirmed high/medium-leverage non-UI gaps into bounded milestones; allow evidence-backed runtime/API changes after explicit scope review. Defer lower-return work with rationale.
- **Long — readiness transition and conditional expansion:** when the readiness gate passes, recommend ScrypathOps as next focus, subject to owner availability. Broader backend/API/search capabilities remain evidence-gated and require explicit scope decisions.

The current program and **READY FOR OPERATOR UI** gate are maintained in [`PRE-OPERATOR-UI-READINESS.md`](PRE-OPERATOR-UI-READINESS.md). Candidate entry gates are in [`milestone-candidates.md`](milestone-candidates.md); the adapted decision guide is [`../../prompts/scrypath-milestone-ratchet-roadmap.txt`](../../prompts/scrypath-milestone-ratchet-roadmap.txt).

## Why the release train is idle

- v1.37 completed an evidence-led, bounded non-UI engineering ratchet and found no confirmed compatible high- or medium-leverage finding within that scope. The broader readiness assessment is still outstanding.
- v1.38 completed package-backed Phoenix adopter proof and published Scrypath 0.3.13 with exact-SHA CI, green post-merge `main`, Hex/HexDocs, consumer compile, and package-to-tag parity.
- Prior product and operator-surface milestones closed the known planned wedges. More polishing is possible, but possibility alone is not evidence.

## Operating lanes

- **Maintenance:** keep required checks lean and green; maintain release, support, docs, and adopter truth.
- **Evidence:** use the existing realistic Phoenix adopter and service-backed proof where they cover meaningful boundaries; add recurring CI only when its confidence justifies cost.
- **Feature:** start only for a concrete bug, reviewed adopter evidence, compatibility need, or bounded owner-approved strategic wedge. Use PR-first work and exact-commit proof.
- **Silence:** when no qualifying signal exists, do not manufacture a milestone.

## Reopen criteria

Open a new milestone when at least one applies:

1. Reviewed outside-adopter evidence identifies a concrete unmet flow.
2. A production or security issue needs work beyond a focused patch.
3. A release or dependency compatibility change requires bounded feature-depth adaptation.
4. The owner explicitly approves a bounded strategic wedge. The pre-operator UI readiness ratchet is now owner-approved; its first milestone still needs formal GSD requirements and a roadmap.

Before recommending the next GSD command, put its required intent, scope, decisions, and evidence in durable planning artifacts. The readiness initiative remains inactive until the formal milestone cycle initializes it.

## Completed milestone sequence (latest)

- **v1.38** — Packaged Adopter Proof (Phases 160–161; shipped 2026-09-25; Scrypath 0.3.13).
- **v1.37** — Code Quality Ratchet (Phases 148–159; shipped 2026-08-26).
- **v1.36** — Dependency Security Remediation (Phases 144–147; shipped 2026-08-25).
- **v1.35** — Brand System & Logo Identity (Phases 137–143; shipped 2026-06-24; archived 2026-07-11).
- **v1.34–v1.32** — ScrypathOps dual-theme quality, design-system, and operator-flow milestones (Phases 116–136).

Earlier milestone history and release details live in `.planning/MILESTONES.md` and `.planning/milestones/`.

*Reviewed 2026-09-25. Provenance: v1.37 quality ledger/audit, v1.38 requirements/audit, current `.planning/PROJECT.md` and `.planning/STATE.md`, and the adapted milestone ratchet guide.*
