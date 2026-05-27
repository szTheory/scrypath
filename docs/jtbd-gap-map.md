# JTBD gap map

**Audience:** maintainers and repeat adopters updating Scrypath docs or planning future milestones.

**Last reviewed:** 2026-05-27

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
  Strong. Facets, hierarchical facets, disjunctive counts, scoped search, and high-cardinality facet value search are present and documented.
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
  Strong but not complete. The example app, verify surface, and readiness artifacts support the claim that the current surface is ready for outside adoption attempts. The remaining evidence gap is reviewed outside-adopter usage, not another in-repo feature wedge.
- **Public website launch surface**
  Strong. The GitHub Pages homepage routes evaluators, adopters, and operators into the existing docs and example app without duplicating HexDocs.

## Default next pull

The Phase 87 evidence review concluded that outside-adopter attempts on defended paths faced significant friction around related data and tenant isolation. v1.24 through v1.26 closed the planned product wedges that followed from that evidence.

The current highest-leverage work is maintenance, not feature breadth:

1. Ship the coherent Release Please patch train for v1.25/v1.26 work.
2. Gather reviewed outside-adopter evidence on the defended path.
3. Reconcile the v1.20 `Scrypath.SearchModule` archive/code drift so planning truth stops overstating shipped surface.

Why this now outranks more feature work:

- the highest-risk product gaps identified by prior evidence are now shipped
- the repo is now close enough to done that generic ergonomics breadth is likely overbuilding
- the remaining confidence gap is outside use, release truth, and planning truth

## Biggest remaining gaps

These are the highest-leverage remaining gaps relative to what mature search ecosystems teach people to expect.

### 1. Outside-adopter evidence

Scrypath has defended in-repo proof, but not enough reviewed external use to justify new breadth confidently.

Why it matters:

- real app integration is where docs, defaults, and operational assumptions fail
- evidence should decide whether the next work is a bugfix, docs patch, or no-op
- more in-repo feature work without evidence now risks overbuilding

Current state:

- `guides/outside-adopter-intake.md` defines the evidence path
- `mix verify.adopter` and the Phoenix example defend the in-repo route

Priority:

- **very high** as a decision input, but it should produce patch-sized work unless evidence proves otherwise

### 2. Planning truth drift

The v1.20 archive claims a `Scrypath.SearchModule` layer, while the current checkout does not expose it.

Why it matters:

- future milestone selection depends on knowing what is actually shipped
- archive/code disagreement lowers confidence and wastes planning tokens

Current state:

- the mismatch is documented in this file and `.planning/todos/search-module-archive-code-drift.md`
- current public docs do not route adopters through `Scrypath.SearchModule`

Priority:

- **high** as maintenance truth cleanup, not as a user-facing feature unless salvage proves the layer should return

### 3. Autocomplete and suggestion-class flows

Scrypath has solid core search and facet value typeahead, but not a general first-class suggestion/autocomplete API.

Why it matters:

- many teams mentally benchmark search libraries against Searchkick-style delight
- these flows are visible product features, even if not core sync infrastructure

Priority:

- **medium**
- only worth doing with outside-adopter evidence

### Closed former top gaps

- **Association and dependency propagation** — closed by v1.24 with `Scrypath.sync_related/3`, `RelatedWorker`, the related-data guide, and Phoenix example fan-out proof.
- **Tenant-safe search access** — closed by v1.25 with `tenant_field:`, `schema_capabilities/1` reflection, `tenant_scope:`, and the multitenancy guide.
- **High-cardinality facet value search** — closed by v1.26 with `Scrypath.search_facet_values/4`, `FacetSearchResult`, Meilisearch `/facet-search` routing, and LiveView examples.

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

1. **Release follow-through**
   Ship the coherent patch train for v1.25/v1.26 work before opening new feature work.
2. **Outside-adopter evidence**
   Use real integration attempts to decide whether future work is a bugfix, docs patch, or no-op.
3. **Planning truth drift**
   Reconcile the v1.20 `Scrypath.SearchModule` archive/code mismatch.
4. **Autocomplete and suggestion flows**
   Open only with outside-adopter evidence; otherwise treat as adjacent product polish.

## Diminishing-returns line

Scrypath starts to feel "feature-complete enough" for its category once five conditions are true at the same time:

1. A Phoenix/Ecto adopter can get first search working quickly.
2. They can choose sync semantics without being misled.
3. They can build normal search, facets, and multi-index flows without dropping to backend-native code for common cases.
4. They can explain and recover from drift, failed work, backfill, and reindex without reading internal source.
5. They have a credible app-edge ergonomics story and a credible related-data reindex story.

The repo now satisfies those conditions well on the defended Meilisearch-first surface, with the remaining caveat that outside-adopter evidence is still thin.

That means the likely diminishing-returns boundary is:

- **before** multi-backend expansion
- **before** vectors or hybrid retrieval
- **before** deep OPSUI productization
- **before** search-adjacent delight features become the main story

In practical terms, Scrypath now looks roughly **93-95% done** for its stated v1 scope. That means:

- another generic ergonomics milestone is likely low leverage without outside-adopter evidence
- release and adoption evidence matter more than feature breadth
- most other work is situational rather than category-defining

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
