# Milestone Arc

## Current arc: Between milestones; readiness follow-up is conditional

**Status:** v1.39 Pre-Operator UI Quality Readiness Ratchet is complete and archived across Phases 162–164. No next milestone is approved.
**Current release:** Scrypath 0.3.13, published and parity-verified.
**Readiness:** NOT READY; conditions 3 and 6 are UNKNOWN in the dated assessment. The final closeout later passed on `dc400b2b57aec0ca6b0ef16c9477d266fd41a433`, which is the peeled `v1.39` tag commit; use it only in a new dated condition 6 reassessment.
**Possible next scope:** condition 3 evidence review/closure and a dated reassessment of conditions 3 and 6. This is a candidate, not an approved milestone; inspect the existing receipts first and avoid repeating passing proof.
**Default:** keep `main` green, maintain support/package/proof truth, and release when warranted.

## Near, mid, and long horizons

These are evidence gates, not dated commitments. Refresh them at each milestone boundary.

- **Near — close evidence gaps:** if owner-approved, assess the bounded claims behind readiness condition 3 and use the final exact-SHA/tag/cleanup receipts for a new condition 6 review. Keep missing evidence separate from product defects; choose a quick task or milestone based on the actual work required.
- **Mid — operator UI when ready and available:** only after the readiness gate passes and maintainer time is available, choose one evidenced operator JTBD or accessibility/usability gap. The owner wants this later but has no current UI capacity; no UI work is authorized now.
- **Long — evidence-backed product expansion:** consider broader search/backend/API capabilities only when real adopter evidence demonstrates material demand and explicit scope review permits the change. Do not preserve speculative ideas as commitments.

The current program and **READY FOR OPERATOR UI** gate are maintained in [`PRE-OPERATOR-UI-READINESS.md`](PRE-OPERATOR-UI-READINESS.md). Candidate entry gates are in [`milestone-candidates.md`](milestone-candidates.md); the adapted decision guide is [`../../prompts/scrypath-milestone-ratchet-roadmap.txt`](../../prompts/scrypath-milestone-ratchet-roadmap.txt).

## Why the release train is idle

- v1.37 completed an evidence-led, bounded non-UI engineering ratchet and found no confirmed compatible high- or medium-leverage finding within that scope.
- v1.39 completed the whole-product readiness assessment; the decision remains NOT READY because conditions 3 and 6 are UNKNOWN. The final closeout passed after the dated cutoff, so condition 6 needs a new assessment rather than a retroactive edit.
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
4. The owner explicitly approves a bounded strategic wedge, such as an evidence-only readiness follow-up. Operator UI remains gated on a passing readiness assessment and owner availability.

Before recommending the next GSD command, put its required intent, scope, decisions, and evidence in durable planning artifacts. No phase is active; do not route into historical phases 162–164.

## Completed milestone sequence (latest)

- **v1.39** — Pre-Operator UI Quality Readiness Ratchet (Phases 162–164; shipped 2026-09-26; readiness NOT READY).
- **v1.38** — Packaged Adopter Proof (Phases 160–161; shipped 2026-09-25; Scrypath 0.3.13).
- **v1.37** — Code Quality Ratchet (Phases 148–159; shipped 2026-08-26).
- **v1.36** — Dependency Security Remediation (Phases 144–147; shipped 2026-08-25).
- **v1.35** — Brand System & Logo Identity (Phases 137–143; shipped 2026-06-24; archived 2026-07-11).
- **v1.34–v1.32** — ScrypathOps dual-theme quality, design-system, and operator-flow milestones (Phases 116–136).

Earlier milestone history and release details live in `.planning/MILESTONES.md` and `.planning/milestones/`.

*Reviewed 2026-09-26. Provenance: v1.37 quality ledger/audit, v1.38 and v1.39 requirements/audits, final exact-SHA run 36257182675, current `.planning/PROJECT.md` and `.planning/STATE.md`, and the adapted milestone ratchet guide.*
