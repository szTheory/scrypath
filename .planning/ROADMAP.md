# Roadmap: Scrypath

## Milestones

- [x] `v1.0` shipped on 2026-04-16 — 7 phases, 25 plans, and the full Meilisearch-first v1 surface archived in [.planning/milestones/v1.0-ROADMAP.md](/Users/jon/projects/scrypath/.planning/milestones/v1.0-ROADMAP.md)
- [x] `v1.1` shipped on 2026-04-16 — 3 phases, 9 plans, release hardening and launch-readiness evidence archived in [.planning/milestones/v1.1-ROADMAP.md](/Users/jon/projects/scrypath/.planning/milestones/v1.1-ROADMAP.md)
- [ ] `v1.2` in progress — Phases 11-14 for public release trust, operator visibility, and a narrower internal operations seam

## Active Milestone

### v1.2: Public Release Trust and Operator Visibility

**Milestone Goal:** Turn Scrypath's launch-readiness evidence into a real public release contract and add a small operator surface for status, failure inspection, recovery, and sync-mode guidance without widening the common path or promising a second backend.

## Phases

- [ ] **Phase 11: Public Release Contract** - Validate one real public release path, consumer smoke flow, and maintainer recovery contract.
- [ ] **Phase 12: Internal Operations Seam** - Extract Scrypath-owned operations boundaries under the Meilisearch-first public surface.
- [ ] **Phase 13: Operator Primitives** - Expose status, failure inspection, retry, and reconcile APIs through Scrypath-owned operator types.
- [ ] **Phase 14: Mix Tasks and Guides** - Put thin CLI ergonomics and sync-mode guides on top of the operator surface without widening common search.

## Phase Details

### Phase 11: Public Release Contract
**Goal**: Maintainers can trust the canonical release path because tag, changelog, package version, Hex artifact state, and clean-consumer verification all line up under one repeatable contract.
**Depends on**: Phase 10
**Requirements**: REL-01, REL-02, REL-03
**Success Criteria** (what must be TRUE):
  1. Maintainer can cut a release from the canonical GitHub flow and confirm the tag, changelog, manifest, package version, and Hex artifact all agree.
  2. Maintainer can install the published package in a clean consumer flow, reach HexDocs, and run a basic Scrypath usage path successfully.
  3. Maintainer can follow one documented recovery path for tag or version drift, failed publish attempts, and published-artifact mismatch without ad hoc spelunking.
**Plans**: 2 plans

Plans:
- [ ] 11-01-PLAN.md - Enforce version/tag/manifest/package alignment with a canonical `mix verify.phase11` gate.
- [ ] 11-02-PLAN.md - Add clean-consumer smoke proof and maintainer recovery runbooks to the Phase 11 release contract.

### Phase 12: Internal Operations Seam
**Goal**: Scrypath's sync and reindex internals depend on a Scrypath-owned operations seam instead of direct Meilisearch task payloads, while keeping Meilisearch as the only public backend and preserving backend-native power boundaries.
**Depends on**: Phase 11
**Requirements**: SEAM-01, SEAM-02
**Success Criteria** (what must be TRUE):
  1. Internal sync and reindex flows exchange Scrypath-owned operation results and references instead of raw Meilisearch task payloads.
  2. Operator-facing internals can inspect lifecycle state without assuming Oban-only execution or exposing backend-specific admin shapes.
  3. Existing Meilisearch-first public behavior still works after the seam extraction, with no new second-backend promise implied by the API.
**Plans**: TBD

### Phase 13: Operator Primitives
**Goal**: Operators can inspect sync state, failed work, and recovery actions through durable Scrypath APIs that stay explicit about eventual consistency and drift.
**Depends on**: Phase 12
**Requirements**: OPS-01, OPS-02, OPS-03
**Success Criteria** (what must be TRUE):
  1. Operator can inspect a schema's current sync state and see pending work, failed work, and last successful activity where Scrypath can know it.
  2. Operator can inspect failed async or manual work and retry it through Scrypath APIs without reading backend-native task payloads directly.
  3. Operator can run a reconcile or recovery workflow that makes drift and reindex state legible instead of pretending automatic healing happened.
  4. Operator-facing results use Scrypath-owned structs or stable maps that are consistent across inline, Oban-backed, and manual workflows where the data exists.
**Plans**: TBD

### Phase 14: Mix Tasks and Guides
**Goal**: Maintainers and operators get thin Mix task ergonomics and explicit operational guides that sit on top of the operator APIs while keeping backend-native search power namespaced.
**Depends on**: Phase 13
**Requirements**: OPS-04, SEAM-03
**Success Criteria** (what must be TRUE):
  1. Operator can run documented `mix scrypath.*` commands for status, failed work inspection, retry, reconcile, and reindex visibility without the CLI becoming its own product surface.
  2. Developer can choose inline, Oban, or manual sync modes from first-class guides that explain consistency, failure handling, and recovery tradeoffs plainly.
  3. Backend-native Meilisearch power remains clearly namespaced outside the common `Scrypath.search/3` contract after the operator docs and CLI land.
  4. Maintainer-facing docs explain how the operator APIs, Mix tasks, and release contract fit together for early production support.
**Plans**: TBD

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 11. Public Release Contract | 0/2 | Not started | - |
| 12. Internal Operations Seam | 0/TBD | Not started | - |
| 13. Operator Primitives | 0/TBD | Not started | - |
| 14. Mix Tasks and Guides | 0/TBD | Not started | - |

## Backlog

- Additional backend support after the release contract and operator surface prove the common path against real Meilisearch adoption.
- Richer backend-native search power after users validate where the current common path is too narrow.
- Deeper operator tooling for drift inspection and recovery once real-world maintainer workflows surface the right abstractions.

---
*Last updated: 2026-04-16 after creating the v1.2 roadmap*
