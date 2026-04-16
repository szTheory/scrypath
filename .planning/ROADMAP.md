# Roadmap: Scrypath

## Milestones

- [x] `v1.0` shipped on 2026-04-16 — 7 phases, 25 plans, and the full Meilisearch-first v1 surface archived in [.planning/milestones/v1.0-ROADMAP.md](/Users/jon/projects/scrypath/.planning/milestones/v1.0-ROADMAP.md)

## Active Milestone

**v1.1 — Release Hardening and Public Launch Readiness**

Goal: harden the shipped v1 surface until README examples, Meilisearch edge cases, and maintainer release flows feel trustworthy enough for broader public adoption.

### Phase 8: Reliability and Contract Hardening

**Goal:** Remove edge-case ambiguity from the Meilisearch and shared sync contracts so hard failures stay explicit and no-op paths are well-defined.
**Requirements:** `HARD-01`, `HARD-02`, `HARD-03`
**Plans:** 3 plans
Plans:
- [x] `08-01-PLAN.md` — Harden Meilisearch task normalization and inline wait contract tests.
- [x] `08-02-PLAN.md` — Define shared empty-batch no-op semantics and telemetry coverage.
- [x] `08-03-PLAN.md` — Keep live reliability verification narrow and add the phase verification Mix task.
**Success criteria:**
1. Inline task waiting handles malformed payloads and terminal error states through stable explicit result tuples.
2. Shared sync/delete batch entrypoints document and implement defined empty-input behavior.
3. The focused reliability test surface covers the former confidence gaps without introducing flaky expectations.

### Phase 9: Public Docs and Example Safety

**Goal:** Make the public adoption path copy-paste safe by removing misleading install guidance and hardening Phoenix examples around real request shapes.
**Requirements:** `DOCS-01`, `DOCS-02`, `DOCS-03`
**Success criteria:**
1. The README install path reflects the real consumer contract and no longer asks users to pin internal transport dependencies.
2. The Phoenix JSON example models safe invalid-page handling instead of crash-prone parsing.
3. Fixture-backed docs tests exercise real Phoenix string-keyed attrs for the LiveView/context publish path.

### Phase 10: Launch Verification and Release Confidence

**Goal:** Close the remaining launch-readiness gaps so maintainers can trust the release path and point to current evidence for the hardened surface.
**Requirements:** `SHIP-01`, `SHIP-02`
**Success criteria:**
1. The maintainer release flow is verified end to end around CI checks, package metadata, and GitHub Actions Hex publishing.
2. The milestone artifacts clearly capture what was hardened and how launch readiness was verified.
3. Scrypath can enter broader public adoption without unresolved milestone bookkeeping gaps around the hardening work.

**Coverage:** 8 requirements mapped across 3 phases. All covered.

## Backlog

- Additional backend support after the launch-readiness milestone proves the common contract against real Meilisearch adoption.
- Richer backend-native search power after users validate where the current common path is too narrow.
- Deeper operator tooling for drift inspection and recovery once real-world maintainer workflows surface the right abstractions.

---
*Last updated: 2026-04-16 after starting milestone v1.1*
