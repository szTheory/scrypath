# Scrypath Done-Ness Assessment — 2026-05-24

## Purpose

Durable summary of the repo-grounded assessment that opened `v1.23`.

Use this thread when future milestone conversations start drifting toward more
internal breadth without revisiting whether Scrypath is already close to done
for its stated scope.

## Current call (updated 2026-05-27 — post-v1.26)

- **Rough done-%:** ~93–95% (was 86% before v1.23 and ~91–93% after v1.24)
- **Territory:** near-done; diminishing returns are here unless outside adopters produce concrete evidence
- **Default next pull:** release/adoption-evidence/planning-truth maintenance, not feature work

## Why the library already looks strong

- First-schema and first-search adoption is real.
- Sync semantics are explicit and honest across `:inline`, `:manual`, and `:oban`.
- Phoenix integration through contexts is real and well-defended.
- Facets, multi-index search, request-edge normalization, and bounded composition are all real public surfaces.
- Operator recovery is a real product surface, not an appendix.
- Related-data propagation (`sync_related/3`) shipped v1.24 — the biggest correctness gap is closed.
- Tenant-safe shared-index search shipped v1.25 with explicit `tenant_scope:` enforcement.
- Facet value vocabulary search shipped v1.26 with `Scrypath.search_facet_values/4`.
- **Ahead of all comparable libs (Searchkick, Scout, meilisearch-rails) on:** operator recovery, admin UI, facets, federation, per-query tuning, related-data, and explicit tenant-scope safety.

## Highest-leverage remaining gaps (reranked post-v1.26)

1. **Outside-adopter evidence loop**
   - The repo has strong in-repo proof, but the remaining confidence gap is real use outside the maintained example.
   - Scope: review Class A/B evidence through `guides/outside-adopter-intake.md`; fix only evidence-backed bugs or doc gaps.
2. **Release follow-through**
   - v1.25/v1.26 functionality should ship through Release Please as `0.3.8` before any new feature milestone.
   - Scope: keep required checks green, merge the release PR when coherent, and verify post-publish parity.
3. **SearchModule archive/code reconciliation**
   - The v1.20 archive still claims a `Scrypath.SearchModule` layer that branch tip does not expose.
   - Scope: recover it only if salvage proves it is real and still worth publishing; otherwise correct archive language.
4. **Autocomplete / suggestions**
   - Moderate gap, but now below the evidence threshold. Open only if an adopter needs it.

## Work that is likely near diminishing returns

- More generic ergonomics breadth
- More Phoenix helper sugar (QueryParams + Composition + Phoenix helpers already cover this)
- Deeper OPSUI productization (no adopter evidence it's blocking)
- Multi-backend expansion
- Soft-delete awareness / conditional indexing hooks (minor, Scout has these, but not a blocking gap)
- Highlighting wrappers (Searchkick has it, but not expected from this lib)
- Autocomplete/suggestion APIs without adopter evidence

## Concrete drift status (updated)

- `v1.20` archive claims `Scrypath.SearchModule` — confirmed NOT in tree as of 2026-05-27. Documented in `/docs/jtbd-gap-map.md`. Planning debt only; not a product gap for users today.
- `guides/support-and-compatibility.md` — **RESTORED** at v1.23. Guide exists, 5.2 KB.
- `test/scrypath/readiness_contract_test.exs` — **RESTORED** at v1.23. `mix verify.adopter` points to a real test again.
- SEED-001 (query toolkit) and SEED-002 (composition depth) — **both shipped** (v1.21 and v1.22). Seeds are stale.

## Decision rule for future milestone selection (updated)

- Do not open a new feature milestone by default.
- Ship the current release train, reconcile planning truth, and gather outside-adopter evidence.
- Autocomplete/suggestions only with adopter evidence.
- Do not open OPSUI breadth, multi-backend, vector/hybrid, or generic ergonomics milestones.
