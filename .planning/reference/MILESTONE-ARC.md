# Milestone Arc

## Current arc: Between milestones; readiness follow-up is conditional

**Status:** v1.40 Readiness Evidence Closure is complete and archived across Phases 165–167. No next milestone is approved.
**Current release:** Scrypath 0.3.13, published and parity-verified.
**Readiness:** NOT READY at the dated v1.40 cutoff: condition 2 FAILs because the Phoenix consumer lock retains Mint 1.9.3 with an unresolved High advisory, and condition 6 was UNKNOWN. Final phase-tracking closeout passed on `343e20be66ab0c17f62b95138203c86e868bd1ee`; archive closeout run `36364188674` passed on `d91842b3f45d14f27d2d4d7ad62f0abf56b54ce9`, the peeled `v1.40` tag commit. These later receipts do not change the dated assessment.
**Possible next scope:** a bounded owner-approved follow-up could resolve or explicitly disposition the Mint advisory and make a new dated readiness assessment using the exact-source receipts for condition 6. This is a candidate, not an approved milestone; preserve the historical cutoff and do not repeat passing Phase 165/166 proof.
**Default:** keep `main` green, maintain support/package/proof truth, and release when warranted.

## Near, mid, and long horizons

These are evidence gates, not dated commitments. Refresh them at each milestone boundary.

- **Near — close readiness blockers:** if owner-approved, resolve or explicitly disposition the Phoenix consumer Mint advisory, then create a new dated readiness assessment that can use the final exact-SHA and tag receipts for condition 6. Keep the historical assessment unchanged and choose a quick task or milestone based on the actual work required.
- **Mid — operator UI when ready and available:** only after the readiness gate passes and maintainer time is available, choose one evidenced operator JTBD or accessibility/usability gap. The owner wants this later but has no current UI capacity; no UI work is authorized now.
- **Long — evidence-backed product expansion:** consider broader search/backend/API capabilities only when real adopter evidence demonstrates material demand and explicit scope review permits the change. Do not preserve speculative ideas as commitments.

The current program and **READY FOR OPERATOR UI** gate are maintained in [`PRE-OPERATOR-UI-READINESS.md`](PRE-OPERATOR-UI-READINESS.md). Candidate entry gates are in [`milestone-candidates.md`](milestone-candidates.md); the adapted decision guide is [`../../prompts/scrypath-milestone-ratchet-roadmap.txt`](../../prompts/scrypath-milestone-ratchet-roadmap.txt).

## Why the release train is idle

- v1.37 completed an evidence-led, bounded non-UI engineering ratchet and found no confirmed compatible high- or medium-leverage finding within that scope.
- v1.40 completed tenant/facet contract corrections, named host and repair evidence, and a separate six-condition assessment. The decision remains NOT READY because condition 2 FAILs and condition 6 was UNKNOWN at cutoff. Final closeout passed later; preserve that historical assessment and use the receipt only in a new dated decision.
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

- **v1.40** — Readiness Evidence Closure (Phases 165–167; shipped 2026-09-27; planning-only archive; assessment NOT READY).
- **v1.39** — Pre-Operator UI Quality Readiness Ratchet (Phases 162–164; shipped 2026-09-26; readiness NOT READY).
- **v1.38** — Packaged Adopter Proof (Phases 160–161; shipped 2026-09-25; Scrypath 0.3.13).
- **v1.37** — Code Quality Ratchet (Phases 148–159; shipped 2026-08-26).
- **v1.36** — Dependency Security Remediation (Phases 144–147; shipped 2026-08-25).
- **v1.35** — Brand System & Logo Identity (Phases 137–143; shipped 2026-06-24; archived 2026-07-11).
- **v1.34–v1.32** — ScrypathOps dual-theme quality, design-system, and operator-flow milestones (Phases 116–136).

Earlier milestone history and release details live in `.planning/MILESTONES.md` and `.planning/milestones/`.

*Reviewed 2026-09-28. Provenance: v1.37 quality ledger/audit, v1.38–v1.40 requirements/audits, v1.40 final exact-SHA runs 36361116862 and 36364188674, current `.planning/PROJECT.md` and `.planning/STATE.md`, and the adapted milestone ratchet guide.*
