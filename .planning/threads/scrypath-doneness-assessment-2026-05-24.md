# Scrypath Done-Ness Assessment — 2026-05-24

## Purpose

Durable summary of the repo-grounded assessment that opened `v1.23`.

Use this thread when future milestone conversations start drifting toward more
internal breadth without revisiting whether Scrypath is already close to done
for its stated scope.

## Current call (updated 2026-05-25 — post-v1.24)

- **Rough done-%:** ~91–93% (was 86% before v1.23 and v1.24 shipped)
- **Territory:** finish the last 2 narrow wedges, then seriously evaluate stopping
- **Default next pull:** AUTH-01 — tenant-safe search guide + `tenant_field:` schema option

## Why the library already looks strong

- First-schema and first-search adoption is real.
- Sync semantics are explicit and honest across `:inline`, `:manual`, and `:oban`.
- Phoenix integration through contexts is real and well-defended.
- Facets, multi-index search, request-edge normalization, and bounded composition are all real public surfaces.
- Operator recovery is a real product surface, not an appendix.
- Related-data propagation (`sync_related/3`) shipped v1.24 — the biggest correctness gap is closed.
- **Ahead of all comparable libs (Searchkick, Scout, meilisearch-rails) on:** operator recovery, admin UI, facets, federation, per-query tuning, and related-data. None of the comparables have solved tenant-safe search either.

## Highest-leverage remaining gaps (reranked post-v1.24)

1. **Tenant-safe search guidance + `tenant_field:` declaration** — AUTH-01
   - The filter merge order bug (`Keyword.merge` silently drops tenant guard) is a real data leak waiting to happen to first adopters.
   - Scope: `guides/multitenancy.md` + `tenant_field:` schema option + `schema_capabilities/1` reflection — 2–3 phases.
   - NOT: process-dict magic, automatic filter injection, or tenant token generation (host-owned by design).
2. **Facet value vocabulary search (`search_facet_values/4`)** — B4
   - Wraps Meilisearch's native `/facet-search` endpoint (stable since v1.3). The settings layer already emits the right config.
   - Guide explicitly says "deferred" — needs to be filled.
   - Scope: small (4–6 impl tasks, 2–3 test tasks). `FacetSearchResult` + `FacetHit` structs, telemetry span, guide update.
   - Real pain at 200+ distinct values per facet; client-side filtering breaks down there.
3. **Autocomplete / suggestions** — moderate gap; only after B1+B4 and only with adopter evidence.

## Work that is likely near diminishing returns

- More generic ergonomics breadth
- More Phoenix helper sugar (QueryParams + Composition + Phoenix helpers already cover this)
- Deeper OPSUI productization (no adopter evidence it's blocking)
- Multi-backend expansion
- Soft-delete awareness / conditional indexing hooks (minor, Scout has these, but not a blocking gap)
- Highlighting wrappers (Searchkick has it, but not expected from this lib)

## Concrete drift status (updated)

- `v1.20` archive claims `Scrypath.SearchModule` — confirmed NOT in tree as of 2026-05-25. Documented in `/docs/jtbd-gap-map.md`. Planning debt only; not a product gap for users today.
- `guides/support-and-compatibility.md` — **RESTORED** at v1.23. Guide exists, 5.2 KB.
- `test/scrypath/readiness_contract_test.exs` — **RESTORED** at v1.23. `mix verify.adopter` points to a real test again.
- SEED-001 (query toolkit) and SEED-002 (composition depth) — **both shipped** (v1.21 and v1.22). Seeds are stale.

## Decision rule for future milestone selection (updated)

- AUTH-01 is the right next pull — scope is thin and the footgun (filter merge order / silent data leak) is concrete enough to justify opening without additional adopter evidence.
- After AUTH-01: `search_facet_values/4` in a tight 1-milestone slot.
- After that: evaluate stopping. Autocomplete only with adopter evidence.
- Do not open OPSUI breadth, multi-backend, or generic ergonomics milestones.
