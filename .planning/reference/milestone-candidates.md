# Milestone candidates — Scrypath evidence-gated roadmap

**Purpose:** Help `$gsd-new-milestone` select work that improves Scrypath adopters or protects release trust without creating roadmap work for its own sake.
**Reviewed:** 2026-09-25 against v1.37 Code Quality Ratchet and v1.38 Packaged Adopter Proof.
**Current posture:** v1.39 Pre-Operator UI Quality Readiness Ratchet is active in planning; Scrypath 0.3.13 is published and verified.

Use evidence-gated horizons, not calendar commitments. Reassess these candidates at each milestone boundary. See [`../../prompts/scrypath-milestone-ratchet-roadmap.txt`](../../prompts/scrypath-milestone-ratchet-roadmap.txt) for the durable decision guide.

The governing program and explicit **READY FOR OPERATOR UI** exit criteria are in [`PRE-OPERATOR-UI-READINESS.md`](PRE-OPERATOR-UI-READINESS.md); active requirements and phases are in `.planning/REQUIREMENTS.md` and `.planning/ROADMAP.md`.

## Near term — maintenance and trust

**Immediate next step:** assess the whole-product non-UI baseline in Phase 162, then rank findings and evaluate the gate through Phases 163–164. Keep `main` green, maintain package/support/docs truth, review incoming adopter evidence, and release when a warranted change is ready. Routine upkeep that fits a focused patch or quick task does not need a milestone.

Open work when there is a concrete production or security bug, compatibility change, release requirement, support/proof drift, or reviewed adopter report. Require a named outcome, smallest useful slice, and proof plan before adding scope.

## Mid term — bounded, owner-approved wedges

| Candidate | Entry evidence | Boundary |
|---|---|---|
| ScrypathOps operator UX/design polish | Maintainer time is available and a specific operator JTBD, usability/accessibility issue, or repeated workflow friction is identified | Improve the existing optional operator surface; keep runtime/API behavior unchanged unless separately justified. Automate accessibility and behavioral acceptance where reliable; reserve visual judgment for irreducible design choices. |
| Adopter-driven product or documentation gap | Reproducible, reviewed outside-adopter evidence demonstrates a material unmet workflow | Address that workflow only; preserve Meilisearch-first and Ecto-native product boundaries. |
| Proof or release-train repair | Repeated CI/proof drift, concrete release compatibility pressure, or operational failure | Fix the smallest shared cause; measure CI/runtime cost and do not duplicate existing proof. |

**Operator UI timing:** ScrypathOps already received major operator-flow, design-system, and accessibility/theme work in v1.32–v1.34. v1.37 found no confirmed compatible high- or medium-leverage issue within its bounded engineering audit, but the whole-product pre-UI baseline has not run. Do not declare diminishing returns yet. Use the explicit gate in `PRE-OPERATOR-UI-READINESS.md`; once it passes, recommend ScrypathOps as the next strategic focus, subject to maintainer availability.

## Long term — strategic expansion only with evidence

| Candidate | Reopen only when |
|---|---|
| Public backend broadening | Multiple real adopters establish a stable common contract and the value outweighs abstraction and support costs. |
| Autocomplete, suggestions, vector/hybrid retrieval, personalization, or analytics | Reviewed adopter demand establishes a material gap and an explicit scope decision authorizes the capability. |
| New public runtime or reusable UI surfaces | A recurring cross-adopter job cannot be served cleanly by existing APIs and the addition preserves operational honesty and Ecto-first composition. |

These are conditional possibilities, not commitments. Existing scope guards remain authoritative until formally changed.

## Selection and closeout rules

1. Start with the evidence and the affected adopter/operator job. If neither is concrete, stay idle.
2. Check prior requirements, milestone archives, support reports, and existing proof before proposing new runtime/API scope.
3. Prefer the smallest vertical slice with the least maintenance and CI cost that can prove the outcome.
4. Automate software acceptance at the cheapest reliable layer; target zero human UAT. Put recurring checks in CI only when confidence justifies runtime and maintenance cost.
5. Keep serious work PR-first, require exact-commit CI, verify post-merge `main`, and close release/worktree/artifact cleanup when warranted.
6. Refresh this file and `MILESTONE-ARC.md` at milestone close: mark shipped candidates complete, remove stale ideas, record evidence and deferrals, and do not invent a next milestone.

## Shipped context

- **v1.37 Code Quality Ratchet:** hardened runtime safety and architecture, introduced capability-named verification, reduced duplicated CI proof, secured release workflows, and established measured performance evidence. Its quality ledger reports no confirmed compatible high- or medium-leverage non-UI finding left open.
- **v1.38 Packaged Adopter Proof:** Scrypath 0.3.13 passed package-backed Phoenix integration, exact-SHA and post-merge CI, Hex/HexDocs publication, clean consumer compilation, and package-to-tag parity. No human UAT remains pending.
- **v1.32–v1.34:** ScrypathOps design system, operator flows, dual-theme polish, and accessibility proof received dedicated milestones. Additional UI work is deferred by owner time and target evidence.
- Earlier product wedges through v1.36 are recorded in `.planning/MILESTONES.md` and `.planning/milestones/`.

*Provenance: adapted 2026-09-25 from the maintainer's cross-project ratchet prompt; reconciled with `.planning/PROJECT.md`, `.planning/STATE.md`, `.planning/RETROSPECTIVE.md`, v1.37's quality ledger/audit, and v1.38's requirements/audit. Read together with `PRE-OPERATOR-UI-READINESS.md` and the companion guide in `prompts/`.*
