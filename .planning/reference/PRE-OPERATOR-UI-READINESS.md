# Pre-Operator UI Quality Readiness Program

**Status:** APPROVED STRATEGIC INTENT — NOT STARTED
**Readiness:** NOT READY — whole-product baseline not yet assessed
**Last reconciled:** 2026-09-25, following v1.38 Packaged Adopter Proof
**Purpose:** Identify and close worthwhile non-UI gaps before ScrypathOps becomes the next strategic focus. Establish an evidence-backed, durable gate for saying the non-UI work has reached diminishing returns.

This program records the owner's approved direction. It is not an active milestone: no v1.39 requirements or roadmap have been created. Use `.planning/MILESTONE-CONTEXT.md` when starting the formal GSD milestone so this intent survives context resets.

## Current evidence

- **v1.37 Code Quality Ratchet** covered runtime safety, internal architecture, test/verification commands, CI efficiency, supply chain/release proof, and measured performance. Its ledger found no confirmed compatible high- or medium-leverage issue in that bounded non-UI scope. It did not claim to audit every dimension of adopter or product readiness.
- **v1.38 Packaged Adopter Proof** verified package-backed Phoenix flows, exact-SHA and post-merge CI, Hex/HexDocs, clean consumer compilation, and package-to-tag parity. Scrypath 0.3.13 is published; no human UAT is pending.
- **v1.32–v1.34** provided substantial ScrypathOps operator-flow, design-system, dual-theme, and accessibility work. Additional operator UI work is intentionally sequenced after this program's exit gate and maintainer availability.
- Existing evidence is an input to the baseline, not a reason to rerun every gate or assume every area is complete.

## Program sequence

### Near term: whole-product non-UI baseline

Review existing code, tests, documentation, planning archives, and hosted evidence. Map important adopter jobs and the failure boundaries they depend on. Assess:

1. Public API consistency, ergonomics, compatibility, and error behavior.
2. Core indexing and search correctness, including writes/deletes, inline/manual/Oban synchronization, related data, tenancy, search, facets, federation, settings, and recovery.
3. Ecto, Oban, Meilisearch, Phoenix, and packaged-consumer seams, including representative supported version/runtime combinations.
4. Operational honesty, observability, backfill/reindex safety, failure reporting, and supportability.
5. First-hour and ongoing developer experience, documentation, examples, diagnostics, and adopter issue intake.
6. Security, privacy, dependency health, configuration boundaries, and release/supply-chain integrity.
7. Architecture, readability, maintainability, measured performance, and test/CI signal-to-cost.

Use a capability-by-evidence matrix. For every area, record relevant user job, existing proof/source, whether proof is sufficient/current, gaps or uncertainty, and disposition. Do not repeat passing tests or re-run service proof without a decision-relevant reason.

### Mid term: evidence-ranked gap closure

For each finding, record: evidence and provenance; affected adopter/operator job; impact and frequency; likelihood/confidence; compatibility/security/data-integrity risk; implementation and regression cost; CI runtime/maintenance cost; and recommendation.

- Address critical and high-impact risks first.
- Take medium-leverage improvements when evidence supports the user value and lifecycle cost.
- Group related findings into small GSD milestones with independent outcomes and automated acceptance evidence.
- Defer low-impact, speculative, controversial, or high-churn findings with a concise reason and revisit trigger.
- Consider bounded runtime/API changes when repeated adopter evidence supports them. Review the existing scope authority explicitly; capability classes it prohibits require a separate owner-approved scope change before planning implementation.

### Long term: readiness transition and conditional strategy

When the exit gate below passes, recommend ScrypathOps as the next strategic focus. Later public backend breadth, new runtime categories, autocomplete/suggestions, vector/hybrid retrieval, personalization, analytics, or reusable UI/product surfaces remain conditional on real adopter evidence and explicit scope decisions. Do not treat them as committed roadmap items.

## Diminishing-return exit gate

Keep readiness **NOT READY** until all of the following have evidence in this record or linked artifacts:

1. Every baseline dimension above has been assessed; evidence coverage and known limits are visible.
2. Every critical, high, or medium-leverage finding is closed with verification or explicitly accepted with rationale and an owner decision. There are no unresolved findings at those levels.
3. Important adopter workflows have appropriate automated proof for the claims being made. The goal is zero routine human verification/UAT; external credentials, permissions, product decisions, or physical-world checks are the only expected handoffs.
4. Required CI remains green and lean. Recurring service/E2E proof runs in CI only where its repeat confidence justifies its runtime and maintenance cost; more expensive lower-frequency evidence may remain advisory or scheduled.
5. Remaining non-UI opportunities are low-leverage, speculative, unsupported, or more costly than their likely benefit, each with a recorded disposition.
6. Release, package, support, and planning truth are current, with no task-owned cleanup or verification debt hidden at closeout.

When all six pass, change **Readiness** to **READY FOR OPERATOR UI**, date the decision, link the baseline/closure evidence, and state any accepted risks. This is the explicit point to tell the owner: “The non-UI work has reached the agreed diminishing-return threshold; ScrypathOps is ready to be the next focus.” It is a readiness recommendation, not an automatic UI start; maintainer availability still governs timing.

## Operating rules

- Keep public behavior stable by default. Any proposed compatibility or API change needs evidence, impact analysis, and explicit placement within or change to the scope guard.
- Map acceptance claims before implementation to the cheapest reliable layer: unit/property, contract/seam, integration, smoke/browser/accessibility, or exact-SHA hosted proof.
- Use property-based tests for named high-risk input spaces/invariants where they add meaningful coverage; do not add tests or CI jobs without decision value.
- Shift verification left and automate recurring checks only when recurrence, risk reduction, and diagnostics justify their cost.
- Preserve the green-main, PR-first posture for serious work; release when warranted; clean task-owned worktrees, branches, services, and artifacts.
- Reconcile this record, candidate list, milestone arc, PROJECT, STATE, and retrospective evidence at each milestone boundary. Remove stale candidates rather than building a backlog of imagined work.

## Provenance and related sources

Owner direction captured 2026-09-25 from the adapted Scrypath milestone-ratchet request and follow-up clarification. The owner selected the exit threshold of no unresolved high/medium-leverage non-UI gaps and authorized evidence-backed bounded runtime/API work subject to explicit scope review.

- `.planning/PROJECT.md` — product scope and automation-first verification policy.
- `.planning/STATE.md` — active/idle milestone status and next action.
- `.planning/reference/milestone-candidates.md` — evidence-gated portfolio candidates.
- `.planning/reference/MILESTONE-ARC.md` — near/mid/long posture.
- `.planning/reference/QUALITY-LEDGER.md` and `.planning/milestones/v1.37-*`, `.planning/milestones/v1.38-*` — prior evidence.
- `.planning/MILESTONE-CONTEXT.md` — handoff for formal milestone initialization.
