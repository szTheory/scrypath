# Milestone Arc

## Current arc: v1.41 Readiness Gate Follow-Through

**Status:** v1.40 is complete and archived across Phases 165–167. The nine-requirement v1.41 scope was approved on 2026-09-28. Phases 168 and 169 are complete. Phase 170 delivered the selected documentation and factual closeout tooling through PR #87; its final-source attestation and terminal readiness decision remain pending.
**Current release:** Scrypath 0.3.13, published 2026-09-25 and parity-verified. Release Please PR #83 proposes 0.3.14 for the integrated fixes and docs, but remains open and blocked because the required approving review has not been submitted. No 0.3.14 tag, GitHub Release, or Hex package is claimed.
**Public `main`:** `87d74259a9f569c6b11c8d9481f5465a172c70ba` includes the Phase 169 fixes and merged Phase 170 PR #87. Exact-main CI run `36795877117` succeeded; its path-scoped workflow skipped ecommerce E2E, so no fresh full E2E pass is claimed. The current required branch checks and source-specific receipts remain distinct from readiness approval.
**Readiness:** The latest terminal assessment remains v1.40's dated NOT READY result: condition 2 FAIL and condition 6 UNKNOWN at its cutoff. Issue [#86](https://github.com/szTheory/scrypath/issues/86) is the sole authority for a later dated decision; it currently has no Phase 170 terminal comment. No six-condition judgments or READY/NOT READY decision are inferred from green jobs.
**Local checkout:** This planning workspace retains accumulated history and unrelated user edits. The clean final evidence ref is independently based on refreshed public `main`; only the exact planning snapshot in `170-CLOSEOUT.md` is intended for transport. Never push the accumulated planning branch as a delivery unit.
**Mounted-readiness fix:** Phase 168 delivered the startup-readiness correction through PR #82. The current source and exact-SHA receipts are owned by the Phase 168 reports; the older local-only status described in prior notes is superseded.
**Privacy:** PR [#81](https://github.com/szTheory/scrypath/pull/81) cleaned the current tree. The history rewrite preserved every file path and mode across public refs and changed only personal-path text in planning documents; no source code changed. All 12 public branch refs and 28 tags, plus local refs, now point to scrubbed history. Fresh scans found no personal home-directory value on those refs. GitHub's pull-request refs retain the value in 68 histories; the owner declined a Support request and accepts this residual. The exact personal path is excluded from this record.
**Approved v1.41 scope:** remediate Mint in all four maintained graphs, with necessary HPAX changes, effective package-graph proof and economical recurring audits; deliver the mounted-readiness fix and known tenant/facet runtime corrections; disposition a finite bot cohort; consolidate confirmed docs drift; evaluate the warranted patch through the existing release gates; and retain a source-bounded terminal six-condition decision. Use clean public-main PR bases and preserve historical outcomes. See [synthesis and change ledger](../research/v1.41/SUMMARY.md).
**Default:** keep `main` green, maintain support/package/proof truth, and release when warranted.

## Near, mid, and long horizons

These are evidence gates, not dated commitments. Refresh them at each milestone boundary.

- **Near — approved v1.41:** Phases 168 and 169 delivered the security, verification and library fixes. Phase 170 delivered focused docs and closeout tooling; the exact-source attestation and terminal readiness decision remain. No new product capability is selected.
- **Release:** 0.3.13 remains current. Planning-only changes do not warrant publication. PR #83 is the authorized normal patch path for the integrated fixes and docs, conditional on its required review and all existing release, package and parity gates. Keep its blocked status explicit until those gates pass or the maintainer records a deferral.
- **Mid — operator UI when ready and available:** only after a fresh readiness assessment passes all six conditions, maintainer time is available, and a separate scope decision approves a concrete operator JTBD or accessibility/usability improvement. A passing gate recommends this focus; it does not automatically start it.
- **Long — evidence-backed product expansion:** consider broader search/backend/API capabilities only when real adopter evidence demonstrates material demand and explicit scope review permits the change. Do not preserve speculative ideas as commitments.

The current program and **READY FOR OPERATOR UI** gate are maintained in [`PRE-OPERATOR-UI-READINESS.md`](PRE-OPERATOR-UI-READINESS.md). Candidate entry gates are in [`milestone-candidates.md`](milestone-candidates.md); the adapted decision guide is [`../../prompts/scrypath-milestone-ratchet-roadmap.txt`](../../prompts/scrypath-milestone-ratchet-roadmap.txt).

## Why a release is not forced

- v1.37 completed an evidence-led, bounded non-UI engineering ratchet and found no confirmed compatible high- or medium-leverage finding within that scope.
- v1.40 completed tenant/facet contract corrections, named host and repair evidence, and a separate six-condition assessment. The decision remains NOT READY because condition 2 FAILs and condition 6 was UNKNOWN at cutoff. Final closeout passed later; preserve that historical assessment and use the receipt only in a new dated decision.
- v1.38 completed package-backed Phoenix adopter proof and published Scrypath 0.3.13 with exact-SHA CI, green post-merge `main`, Hex/HexDocs, consumer compile, and package-to-tag parity. Later library fixes and selected Phase 170 docs/tooling have since been delivered to public `main`; their source and package identities remain separate from the still-blocked 0.3.14 release candidate.
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
4. The owner explicitly approves a bounded strategic wedge, such as an evidence-only readiness follow-up or documentation clarity audit. Operator UI remains gated on a passing readiness assessment and owner availability.

Before recommending the next GSD command, put its required intent, scope, decisions, and evidence in durable planning artifacts. Phase 168 is next under the approved v1.41 roadmap; never route into historical phases 162–164.

## Completed milestone sequence (latest)

- **v1.40** — Readiness Evidence Closure (Phases 165–167; shipped 2026-09-27; planning-only archive; assessment NOT READY).
- **v1.39** — Pre-Operator UI Quality Readiness Ratchet (Phases 162–164; shipped 2026-09-26; readiness NOT READY).
- **v1.38** — Packaged Adopter Proof (Phases 160–161; shipped 2026-09-25; Scrypath 0.3.13).
- **v1.37** — Code Quality Ratchet (Phases 148–159; shipped 2026-08-26).
- **v1.36** — Dependency Security Remediation (Phases 144–147; shipped 2026-08-25).
- **v1.35** — Brand System & Logo Identity (Phases 137–143; shipped 2026-06-24; archived 2026-07-11).
- **v1.34–v1.32** — ScrypathOps dual-theme quality, design-system, and operator-flow milestones (Phases 116–136).

Earlier milestone history and release details live in `.planning/MILESTONES.md` and `.planning/milestones/`.

*Reviewed 2026-09-28. Provenance: v1.37 quality ledger/audit, v1.38–v1.40 requirements/audits, v1.40 final exact-SHA runs 36361116862 and 36364188674, Hex package metadata, public GitHub main/CI/PR state, local branch comparison, privacy scan, current `.planning/PROJECT.md` and `.planning/STATE.md`, and the adapted milestone ratchet guide.*
