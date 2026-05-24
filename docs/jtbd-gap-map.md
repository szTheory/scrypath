# JTBD gap map

**Audience:** maintainers and repeat adopters updating Scrypath docs or planning future milestones.

**Last reviewed:** 2026-05-24

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
  Strong but not perfectly clean. The example app, verify surface, and readiness artifacts support the claim that the current surface is ready for outside adoption attempts, but the current tree still has support-truth drift that should be reconciled before maintainers overstate how tidy the proof surface is.

## Default next pull

The Phase 87 evidence review concluded that outside-adopter attempts on defended paths face significant friction regarding related data and tenant isolation. 

The current highest-leverage work is:

1. **Association and dependency propagation** (Active next-pull verdict)
2. **Tenant-safe search access story**

Why this now outranks more feature work:

- reviewed outside-adopter evidence confirmed these as primary blockers and painful workarounds
- the repo is already close to diminishing returns on generic ergonomics breadth

## Biggest remaining gaps

These are the highest-leverage gaps relative to what mature search ecosystems teach people to expect.

### 1. Association and dependency propagation semantics

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

### 2. Tenant-safe search access story

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

### 3. High-cardinality facet value search

Scrypath has strong facet filtering and counts, but the user flow for "search within thousands of facet values" is still incomplete.

Why it matters:

- large catalogs quickly outgrow static checklists
- Meilisearch now has a dedicated facet-search endpoint with concrete limits and tradeoffs
- the current facet guide explicitly defers backend facet-value search in favor of client-side filtering

Priority:

- **high** for catalog-heavy apps, lower for admin search

### 4. Autocomplete and suggestion-class flows

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
- likely only worth doing after composition depth, tenant-safe access, and dependency semantics are stronger

## Gaps that are real but lower leverage

- **Request-edge ergonomics**
  This was the old top gap, but `v1.21` materially closed it with `Scrypath.QueryParams`, structured edge errors, and optional `Scrypath.Phoenix` helpers.
- **Composition depth**
  This was the next leverage move after `v1.21`, and `v1.22` materially closed it with `Scrypath.Composition`, metadata reflection, and `compose_many/2` lowering. Future work should not reopen generic composition breadth without outside-adopter evidence.
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

## Updated priority order

1. **Association and dependency propagation**
   Biggest correctness gap for real apps once documents include related data. This is the active next-pull verdict.
2. **Tenant-safe search access story**
   Biggest credibility gap for Phoenix SaaS adopters.
3. **Facet-value search for large filter lists**
   Useful for larger catalogs, but narrower.
4. **Autocomplete and suggestion flows**
   Worth doing later, not before the correctness and SaaS-boundary work lands.

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

In practical terms, Scrypath now looks roughly **mid-to-high 80s done** for its stated v1 scope. That means:

- another generic ergonomics milestone is likely low leverage without outside-adopter evidence
- related-data propagation is the first major remaining correctness wedge
- tenant-safe search access is the first major remaining SaaS-credibility wedge
- most other work is becoming situational rather than category-defining

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

Phase 86 restored the current support/readiness authority at `guides/support-and-compatibility.md` and repaired `mix verify.adopter` so its fast path now runs a real `test/scrypath/readiness_contract_test.exs` seam. The remaining credibility issue is the archive-vs-branch-tip `SearchModule` mismatch, not the support/proof surface.
