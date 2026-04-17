# Milestones

## v1.2 Public Release Trust and Operator Visibility (Shipped: 2026-04-17)

**Phases completed:** 7 phases, 13 plans, 22 tasks

**Key accomplishments:**

- Version-anchored Hex package links and a canonical `mix verify.phase11` gate for Release Please, manifest, and local package alignment
- Clean-consumer compile proof and maintainer recovery runbooks enforced through the Phase 11 release gate
- Scrypath-owned task and result seam contracts for Meilisearch and Oban normalization without runtime rewiring
- Seam-owned Meilisearch and Oban operation references wired through sync while preserving the public Meilisearch-first sync contract
- Seam-owned backfill and reindex workflow references with the Meilisearch-first public boundary locked in docs and telemetry
- Root-level sync status reporting with Scrypath-owned backend and queue visibility across manual, inline, and Oban workflows
- Canonical Phase 13 operator verification evidence plus roadmap and requirement repairs grounded in a fresh `mix verify.phase13 --skip-integration` pass
- Canonical Phase 14 verification evidence, repaired milestone bookkeeping, and plan-index aliases grounded in a fresh `mix verify.phase14` pass
- Shipped the first real public Scrypath release as `0.3.0`, then verified the live GitHub release, Hex package, and HexDocs path

---

| Version | Date | Phases | Plans | Status | Notes |
|---------|------|--------|-------|--------|-------|
| `v1.0` | 2026-04-16 | 7 | 25 | Archived | Ecto-native Meilisearch-first indexing core, search, Oban, reindex, Phoenix docs, and repaired verification history. |
| `v1.1` | 2026-04-16 | 3 | 9 | Archived | Release hardening, docs-safety fixes, and launch-readiness evidence chain archived in `.planning/milestones/v1.1-ROADMAP.md`. |
| `v1.2` | 2026-04-17 | 7 | 13 | Archived | Public release trust, operator visibility, internal operations seam, and the first live public release proof archived in `.planning/milestones/v1.2-ROADMAP.md`. |
