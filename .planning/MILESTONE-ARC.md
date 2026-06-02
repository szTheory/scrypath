# Milestone Arc

## Current arc: Admin UI/UX design-system cleanup

**Status:** active v1.32 milestone
**Current default pull:** finish the bounded existing-admin UI cleanup and verification pass, then return to maintenance unless new evidence appears

## Why this is the active posture

`v1.23` through `v1.28` closed the last planned high-leverage wedges from prior evidence:

- support-truth reconciliation and outside-adopter intake (`v1.23`)
- related-data propagation (`v1.24`)
- tenant-safe access (`v1.25`)
- facet-value vocabulary search (`v1.26`)
- adopter contract hardening (`v1.27`)
- realistic demo app and admin UI proof (`v1.28`)

Scrypath now sits in a near-done band for its stated Meilisearch-first Phoenix/Ecto scope, so default planning should optimize for trust and maintenance rather than additional breadth.

The current bounded v1.32 wedge is not new product breadth: make the existing ScrypathOps `/ops` shell and mounted `/admin/search/*` demo admin surface easier to understand, more polished, and better covered while preserving the advisory posture for live/browser proof.

## Operating lanes

- **Maintenance lane (default):** keep `main` green, finish release follow-through, maintain support/docs truth, and process outside-adopter evidence.
- **Evidence lane:** maintain the realistic demo, deterministic browser proof, Docker/dev DX, and maintainer UAT path without changing Scrypath runtime scope.
- **Admin UI polish lane (active v1.32):** clean up existing operator/admin screens, component primitives, mounted asset contracts, and verification without adding runtime capabilities.
- **Feature lane (only when reopened):** use PR-scoped milestones with explicit wedge boundaries; merge only after green PR CI.

## Planning-truth note

`v1.20` SearchModule archive claims were reconciled on 2026-05-27 via archive-correction: branch tip does not ship `Scrypath.SearchModule`, and planning now treats those claims as historical milestone narrative only.

Decision record: `.planning/todos/search-module-archive-code-drift.md` (resolved)

## Active milestone

- **v1.32** — Admin UI/UX Design System Cleanup (active: 2026-06-01)

## Completed milestone sequence (latest)

- **v1.31** — Adoption Evidence Demo Hardening (UAT passed: 2026-06-01)
- **v1.30** — Release Trust and Evidence Maintenance (shipped + archived: 2026-06-01)
- **v1.29** — Contract Repair and Proof Hardening (shipped + archived: 2026-05-31)
- **v1.28** — Realistic Demo App & Admin UI Proof (shipped + archived: 2026-05-31)
- **v1.27** — Adopter Contract Hardening (shipped + archived: 2026-05-30)
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
