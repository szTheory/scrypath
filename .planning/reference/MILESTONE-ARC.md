# Milestone Arc

## Current arc: Release train idle

**Status:** no active milestone
**Current default pull:** keep `main` green, maintain release/support truth, and only reopen milestone work when concrete evidence or an explicit owner-approved wedge justifies it

## Why this is the active posture

`v1.23` through `v1.35` closed the last planned high-leverage wedges from prior evidence and owner-approved polish:

- support-truth reconciliation and outside-adopter intake (`v1.23`)
- related-data propagation (`v1.24`)
- tenant-safe access (`v1.25`)
- facet-value vocabulary search (`v1.26`)
- adopter contract hardening (`v1.27`)
- realistic demo app and admin UI proof (`v1.28`)
- contract repair and proof hardening (`v1.29`)
- release trust and evidence maintenance (`v1.30`)
- adoption-evidence demo hardening (`v1.31`)
- admin UI/UX design-system cleanup (`v1.32`)
- admin UI insane polish (`v1.33`)
- both-themes dark-signature and AA gate (`v1.34`)
- brand system and logo identity (`v1.35`)

Scrypath remains in a near-done band for its stated Meilisearch-first Phoenix/Ecto scope. Default planning should optimize for trust, maintenance, proof stability, and support truth rather than additional breadth.

## Operating lanes

- **Maintenance lane (default):** keep `main` green, finish release follow-through, maintain support/docs truth, and process outside-adopter evidence.
- **Evidence lane:** maintain realistic demo, deterministic proof, Docker/dev DX, and maintainer UAT paths without changing Scrypath runtime scope.
- **Feature lane (only when reopened):** use PR-scoped milestones with explicit wedge boundaries; merge only after green PR CI and scope review.
- **Silence lane:** when no release, support, proof, bug, adopter, or explicit strategic signal exists, do not manufacture a milestone.

## Planning-truth note

`v1.35` shipped directly in commit `fcb8fc7`, not through GSD plan artifacts. Phases 137-143 are archived from direct evidence. Do not reopen them or synthesize missing phase directories for phases 138-143.

`v1.20` SearchModule archive claims were reconciled on 2026-05-27 via archive-correction: branch tip does not ship `Scrypath.SearchModule`, and planning now treats those claims as historical milestone narrative only.

Decision record: `.planning/todos/search-module-archive-code-drift.md` (resolved)

## Active milestone

- None.

## Completed milestone sequence (latest)

- **v1.35** - Brand System & Logo Identity (shipped: 2026-06-24; archived: 2026-07-11)
- **v1.34** - Both-Themes Perfection - Dark Signature + AA Gate (shipped: 2026-06-29; archived: 2026-07-11)
- **v1.33** - Admin UI Insane Polish (shipped: 2026-06-03)
- **v1.32** - Admin UI/UX Design System Cleanup (shipped: 2026-06-01)
- **v1.31** - Adoption Evidence Demo Hardening (UAT passed: 2026-06-01)
- **v1.30** - Release Trust and Evidence Maintenance (shipped + archived: 2026-06-01)
- **v1.29** - Contract Repair and Proof Hardening (shipped + archived: 2026-05-31)
- **v1.28** - Realistic Demo App & Admin UI Proof (shipped + archived: 2026-05-31)
- **v1.27** - Adopter Contract Hardening (shipped + archived: 2026-05-30)
- **v1.26** - Facet Value Vocabulary Search (shipped + archived: 2026-05-26)
- **v1.25** - Tenant-Safe Search Access (shipped + archived: 2026-05-26)
- **v1.24** - Related-Data and Dependency Propagation (shipped + archived: 2026-05-25)
- **v1.23** - Outside-Adopter Evidence and Support-Truth Reconciliation (shipped + archived: 2026-05-24)

For earlier sequence detail, see `.planning/MILESTONES.md` and `.planning/milestones/`.

## Reopen criteria for a future feature milestone

Open a new feature milestone only when at least one of the following is true:

1. reviewed outside-adopter evidence shows a concrete unmet flow,
2. a concrete production bug demands non-patch milestone work,
3. release compatibility change requires bounded feature-depth adaptation,
4. the owner explicitly approves a bounded strategic wedge.

Without one of those signals, default posture is no new feature milestone.
