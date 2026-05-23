# JTBD gap map

**Audience:** maintainers and repeat adopters updating Scrypath docs or planning future milestones.

**Last reviewed:** 2026-05-22

This document answers four questions:

1. What user jobs does Scrypath already serve well?
2. Where are the biggest remaining user-flow gaps?
3. What should be prioritized next if feature work reopens?
4. When does more JTBD work start producing diminishing returns?

The goal is to keep future doc updates and milestone planning anchored in the current repo surface, not in wishful archive memory.

## Current shipped flow map

### Adopter flows that are strong today

- **First indexed schema and first search**
  Strong. The README, golden path, example app, and Phoenix guides all support the "get one schema searchable" job clearly.
- **Explicit sync mode choice**
  Strong. The inline, Oban, and manual semantics are well explained and intentionally honest about visibility.
- **Phoenix integration through contexts**
  Strong. The library consistently teaches context-owned orchestration with thin controllers and LiveView.
- **Catalog-style faceted search**
  Strong. Facets, hierarchical facets, disjunctive counts, and scoped search are present and documented.
- **Multi-index or federated search**
  Strong. `search_many/2`, `:all` expansion, federation weights, and partial-failure honesty are present.
- **Operator triage and recovery**
  Strong. Status, failed work, reconcile, backfill, and reindex form a real recovery surface instead of an afterthought.

### Operator and maintainer flows that are strong today

- **Terminal-first incident triage**
  Strong. The `mix scrypath.*` tasks and drift docs create a coherent CLI recovery path.
- **Optional OPSUI inspection**
  Strong enough for v1. The shell reflects triage priorities honestly and stays secondary to core library adoption.
- **Adopter proof and support contract**
  Strong. The example app, verify surface, and readiness artifacts support the claim that the current surface is ready for outside adoption attempts.

## Biggest remaining gaps

These are the highest-leverage gaps relative to what mature search ecosystems teach people to expect.

### 1. Search-edge ergonomics for Phoenix apps

Scrypath's runtime is strong, but the app-edge story still asks adopters to hand-roll a lot of request-param normalization and repeated context glue.

Why it matters:

- this is where search feels "easy" or "fiddly"
- it affects every day-two Phoenix integration
- Searchkick and Laravel Scout both earn mindshare by compressing the app-facing ceremony

Repo status:

- planning artifacts claim a `Scrypath.SearchModule` layer shipped in `v1.20`
- the checked-out code does not currently expose that layer
- treat this as an unresolved repo/planning mismatch, not current product truth

Priority:

- **highest**, if internal feature work reopens

### 2. Association and dependency propagation semantics

Scrypath is honest about projection and sync, but it does not yet present a strong public story for "this parent record should be reindexed when related data changes."

Why it matters:

- real apps project associated data into documents
- mature libraries repeatedly run into "related update did not resync the document"
- Hibernate Search shows how valuable explicit reindex dependency rules can be

Current state:

- projection is explicit and does not auto-load associations
- this avoids magic, but leaves a common real-world job underexplained

Priority:

- **very high**, especially if outside adopters start projecting joins, counts, tags, or ownership metadata

### 3. Tenant-safe search access story

Scrypath has index-prefix language and operator examples, but not yet a strong end-to-end job story for shared-index multi-tenant access.

Why it matters:

- SaaS adopters often need search isolation, not just environment partitioning
- Meilisearch's current tenant-token model is a real, first-class solution area
- "just prefix the index" is not the same as authorization

Current state:

- repo docs mention prefixes and operator flags
- the public mental model does not yet teach a clear tenant-scope story

Priority:

- **high** for B2B SaaS credibility

### 4. High-cardinality facet value search

Scrypath has strong facet filtering and counts, but the user flow for "search within thousands of facet values" is still incomplete.

Why it matters:

- large catalogs quickly outgrow static checklists
- Meilisearch now has a dedicated facet-search endpoint with concrete limits and tradeoffs
- the current facet guide explicitly defers backend facet-value search in favor of client-side filtering

Priority:

- **high** for catalog-heavy apps, lower for admin search

### 5. Autocomplete and suggestion-class flows

Scrypath has solid core search, but not yet a first-class user flow for:

- typeahead
- autocomplete
- "did you mean"
- suggestion-oriented UI patterns

Why it matters:

- many teams mentally benchmark search libraries against Searchkick-style delight
- these flows are not the core sync problem, but they are highly visible product features

Priority:

- **medium**
- likely only worth doing after edge ergonomics and dependency semantics are stronger

## Gaps that are real but lower leverage

- **OPSUI deeper productization**
  Useful, but the repo already treats core library and honest operator visibility as the v1 line. More admin-surface work is not the highest leverage for adopters.
- **Heavier browser E2E for OPSUI**
  Valuable only if existing stubbed and integration proof keeps missing real regressions.
- **More maintainer workflow tooling**
  Helpful for repo velocity, but mostly irrelevant to the Hex consumer's job-to-be-done.

## Explicit non-goals unless outside evidence changes

These should stay out of the default roadmap pull until real adoption pressure says otherwise:

- public multi-backend parity
- vector or hybrid retrieval
- personalization
- analytics-heavy search product features
- trying to turn Scrypath into a full hosted-search platform

The repo's current discipline here is correct. Mature ecosystems show that widening too early creates confusing abstractions and weakens the core indexing/sync story.

## Recommended priority order if product work reopens

1. **Search-edge ergonomics**
   A thin, explicit app-facing layer for common Phoenix search flows is the cleanest next leverage move.
2. **Association and dependency propagation**
   This is the biggest correctness gap once adopters move beyond flat documents.
3. **Tenant-safe search access story**
   Important for SaaS credibility and easy to misunderstand if left implicit.
4. **Facet-value search for large filter lists**
   Strong category fit for Meilisearch-backed catalog apps.
5. **Autocomplete and suggestion flows**
   Valuable, but should not outrun the operational and integration core.

## Diminishing-returns line

Scrypath starts to feel "feature-complete enough" for its category once five conditions are true at the same time:

1. A Phoenix/Ecto adopter can get first search working quickly.
2. They can choose sync semantics without being misled.
3. They can build normal search, facets, and multi-index flows without dropping to backend-native code for common cases.
4. They can explain and recover from drift, failed work, backfill, and reindex without reading internal source.
5. They have a credible app-edge ergonomics story and a credible related-data reindex story.

The repo already satisfies the first four well on the defended Meilisearch-first surface.

That means the likely diminishing-returns boundary is:

- **before** multi-backend expansion
- **before** vectors or hybrid retrieval
- **before** deep OPSUI productization
- **before** search-adjacent delight features become the main story

In practical terms, once Scrypath closes the app-edge ergonomics and related-data propagation gaps, most remaining JTBD work becomes situational rather than category-defining.

## External reference points

These ecosystems still look like the right calibration points for future gap reviews:

- **Searchkick**
  Strong benchmark for sync strategy breadth, reindex ergonomics, and search UX expectations.
- **Laravel Scout**
  Strong benchmark for a thin integration layer over an explicit driver seam.
- **Meilisearch documentation**
  Important for current task semantics, facet search, tenant tokens, and index-swap workflows.
- **meilisearch-rails**
  Useful for ORM integration lessons around background updates, deletes, and rebuild flows.
- **Hibernate Search**
  Strong reference for explicit indexing dependency and mass-indexing depth.

## Update protocol

When revisiting this document:

1. Re-read the current README, guide map, architecture doc, and example app.
2. Re-check the roadmap and milestone files for any newly claimed flows.
3. Compare planning claims against the checked-out code before treating them as shipped truth.
4. Re-scan the external reference points for any major ecosystem changes that alter the leverage ranking.
5. Update the priority order only when repo truth or outside evidence materially changed.

## Current repo caveat

The planning archive currently claims a thin `Scrypath.SearchModule` layer shipped in `v1.20`, while the checked-out code does not expose that layer. Keep future JTBD docs and milestone decisions grounded in the code surface until that mismatch is reconciled.
