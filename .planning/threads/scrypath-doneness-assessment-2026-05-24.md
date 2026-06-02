# Scrypath Done-Ness Assessment — 2026-05-24

## Purpose

Durable summary of the repo-grounded assessment that opened `v1.23`.

Use this thread when future milestone conversations start drifting toward more
internal breadth without revisiting whether Scrypath is already close to done
for its stated scope.

## Current call (updated 2026-05-31 — post-v1.29)

- **Rough done-%:** ~96–98% for Scrypath's stated Meilisearch-first, Ecto-native, Phoenix-friendly scope.
- **Territory:** effectively done for the original product promise; diminishing returns are now the default for internal feature expansion.
- **Default next pull:** release, maintenance, support truth, proof stability, and outside-adopter evidence. Do not open a feature milestone just because more polish is imaginable.
- **Strategic lane:** only reopen product-building when a concrete production bug, reviewed outside-adopter evidence, or an explicit strategic wedge justifies it.

## Why the library already looks strong

- First-schema and first-search adoption is real.
- Sync semantics are explicit and honest across `:inline`, `:manual`, and `:oban`.
- Phoenix integration through contexts is real and well-defended.
- Facets, multi-index search, request-edge normalization, and bounded composition are all real public surfaces.
- Operator recovery is a real product surface, not an appendix.
- Related-data propagation (`sync_related/3`) shipped v1.24 — the biggest correctness gap is closed.
- Tenant-safe shared-index search shipped v1.25 with explicit `tenant_scope:` enforcement.
- Facet value vocabulary search shipped v1.26 with `Scrypath.search_facet_values/4`.
- Adopter contract hardening shipped v1.27, including install/support/proof coherence and trust gates.
- Realistic demo/admin proof shipped v1.28, including the e-commerce host app, mountable ops engine proof, and advisory real-services E2E lane.
- Contract repair and proof hardening shipped v1.29, including generated fan-out reflection and tenant-preserving ecommerce readiness regression proof.
- **Ahead of all comparable libs (Searchkick, Scout, meilisearch-rails) on:** operator recovery, admin UI, facets, federation, per-query tuning, related-data, and explicit tenant-scope safety.

## Highest-leverage remaining gaps (reranked post-v1.29)

1. **Outside-adopter evidence loop**
   - The repo has strong in-repo proof, but the remaining confidence gap is real use outside the maintained example.
   - Scope: review Class A/B evidence through `guides/outside-adopter-intake.md`; fix only evidence-backed bugs or doc gaps.
2. **Release follow-through**
   - Current accumulated functionality should ship through the release train before any new feature milestone.
   - Scope: keep required checks green, merge the release PR when coherent, and verify post-publish parity.
3. **Autocomplete / suggestions**
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

- `v1.20` archive claimed `Scrypath.SearchModule` — resolved as archive-correction and must not drive future feature selection.
- `guides/support-and-compatibility.md` — **RESTORED** at v1.23. Guide exists, 5.2 KB.
- `test/scrypath/readiness_contract_test.exs` — **RESTORED** at v1.23. `mix verify.adopter` points to a real test again.
- SEED-001 (query toolkit) and SEED-002 (composition depth) — **both shipped** (v1.21 and v1.22). Seeds are stale.

## Decision rule for future milestone selection (updated post-v1.29)

- Do not open a new feature milestone by default.
- If the prompt is generic "what next?", answer with maintenance/release/evidence posture, not a generated backlog.
- Ship the current release train, keep proof/support truth current, and gather outside-adopter evidence.
- Autocomplete/suggestions only with adopter evidence.
- Do not open OPSUI breadth, multi-backend, vector/hybrid, or generic ergonomics milestones.
- Super-duper polish belongs later and should be patch-sized unless it fixes a concrete adopter problem.
