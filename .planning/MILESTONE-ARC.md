# Milestone Arc

## Current arc: Maintenance and adoption evidence

**Status:** no active milestone (post-v1.26 maintenance mode)  
**Current default pull:** release train + outside-adopter evidence + planning-truth reconciliation

## Why this is the active posture

`v1.23` through `v1.26` closed the last planned high-leverage wedges from prior evidence:

- support-truth reconciliation and outside-adopter intake (`v1.23`)
- related-data propagation (`v1.24`)
- tenant-safe access (`v1.25`)
- facet-value vocabulary search (`v1.26`)

Scrypath now sits in a near-done band for its stated Meilisearch-first Phoenix/Ecto scope, so default planning should optimize for trust and maintenance rather than additional breadth.

## Operating lanes

- **Maintenance lane (default):** keep `main` green, finish release follow-through, maintain support/docs truth, and process outside-adopter evidence.
- **Feature lane (only when reopened):** use PR-scoped milestones with explicit wedge boundaries; merge only after green PR CI.

## Planning-truth note

`v1.20` SearchModule archive claims were reconciled on 2026-05-27 via archive-correction: branch tip does not ship `Scrypath.SearchModule`, and planning now treats those claims as historical milestone narrative only.

Decision record: `.planning/todos/search-module-archive-code-drift.md` (resolved)

## Completed milestone sequence (latest)

- **v1.26** — Facet Value Vocabulary Search (shipped + archived: 2026-05-26)
- **v1.25** — Tenant-Safe Search Access (shipped + archived: 2026-05-26)
- **v1.24** — Related-Data and Dependency Propagation (shipped + archived: 2026-05-25)
- **v1.23** — Outside-Adopter Evidence and Support-Truth Reconciliation (shipped + archived: 2026-05-24)

For earlier sequence detail, see `.planning/MILESTONES.md` and `.planning/milestones/`.

## Reopen criteria for a future feature milestone

Open a new feature milestone only when at least one of the following is true:

1. reviewed outside-adopter evidence shows a concrete unmet flow,
2. a concrete production bug demands non-patch milestone work,
3. release compatibility change requires bounded feature-depth adaptation.

Without one of those signals, default posture is no new feature milestone.
