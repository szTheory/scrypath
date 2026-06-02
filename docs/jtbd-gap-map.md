# JTBD gap map

**Audience:** maintainers and repeat adopters updating Scrypath docs or planning future milestones.

**Last reviewed:** 2026-05-31

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

v1.27 and v1.28 then closed the adopter contract hardening and realistic demo/admin proof wedges. v1.29 is now complete as a bounded contract-repair and proof-hardening closeout, not feature breadth:

1. Fan-out declaration repair is verified so `use Scrypath, fan_outs:` exposes `__scrypath__(:fan_outs)`.
2. The v1.28 ecommerce E2E readiness regression guard verifies category probes preserve tenant scope.
3. Roadmap/JTBD truth is refreshed for the repair closeout, and the repo returns to maintenance-and-evidence mode.

Why this now outranks more feature work:

- the highest-risk product gaps identified by prior evidence are now shipped
- the remaining concrete gaps are shipped-contract and proof-quality gaps, not new user-facing breadth
- the repo is now close enough to done that generic ergonomics breadth is likely overbuilding
- the remaining confidence gap is outside-adopter evidence and proof stability, not another in-repo feature wedge

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
- future feature breadth should reopen only through [scope-and-reopen-policy](../guides/scope-and-reopen-policy.md): a **concrete production bug**, **reviewed outside-adopter evidence**, or a **deliberate strategic product decision**

Priority:

- **very high** as a decision input, but it should produce patch-sized work unless evidence proves otherwise

### 2. Maintenance-and-evidence mode

v1.29 closed the remaining shipped-contract repair wedge. The default pull is now release/support truth, proof stability, and outside-adopter evidence.

Why it matters:

- release and support truth are higher leverage than speculative new surface
- proof stability tells maintainers whether advisory lanes should stay advisory, be fixed, or eventually be promoted by policy
- maintenance mode keeps Scrypath honest while real adoption catches up

Current state:

- v1.29 repairs generated `__scrypath__(:fan_outs)` reflection for `use Scrypath, fan_outs:`
- v1.29 guards the category-filtered readiness probe so it merges with, rather than replaces, the tenant filter
- `phase105-e2e` remains advisory until explicit release-policy approval and stability evidence justify promotion

Priority:

- **very high** as the default operating mode
- should not expand into new runtime categories

### 3. Closed: contract repair and proof hardening

Scrypath has a strong related-data and realistic E2E story, and v1.29 tightened the shipped-contract details needed before the repo can mostly stop.

Why it matters:

- adopters should be able to use `use Scrypath, fan_outs:` instead of hand-writing reflection for ordinary searchable fan-out schemas
- tenant/category proof must not accidentally weaken tenant scope inside the E2E harness
- stale post-v1.26 ranking docs can mislead future milestone selection

Closed state:

- `Scrypath.sync_related/3` is real and documented
- v1.29 repairs generated `__scrypath__(:fan_outs)` reflection for `use Scrypath, fan_outs:`
- v1.29 guards the category-filtered readiness probe so it merges with, rather than replaces, the tenant filter
- v1.29 aligns roadmap/JTBD truth and closes TRUTH-01 through `mix verify.phase108`

Priority:

- **closed** as the v1.29 bounded repair wedge

### 4. Planning truth freshness

The v1.20 `Scrypath.SearchModule` archive/code mismatch is resolved as archive-correction, but some ranking docs still carried post-v1.26 priorities after v1.27/v1.28 shipped.

Why it matters:

- future milestone selection depends on knowing what is actually shipped
- stale ranking docs lower confidence and waste planning tokens

Current state:

- `.planning/todos/search-module-archive-code-drift.md` is resolved
- current public docs do not route adopters through `Scrypath.SearchModule`
- post-v1.28 planning should point at contract repair/proof hardening before any feature work

Priority:

- **high** as maintenance truth cleanup, not as a user-facing feature

### 5. Autocomplete and suggestion-class flows

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
- **Adopter contract hardening** — closed by v1.27 with contract freeze, support/proof boundary reconciliation, and trust gates.
- **Realistic demo/admin proof** — closed by v1.28 with mountable admin UI, multi-tenant ecommerce example, storefront/operator E2E, and advisory real-services CI.

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

Future reopening for these non-goals should still route through [scope-and-reopen-policy](../guides/scope-and-reopen-policy.md) and use the same three triggers: **concrete production bug**, **reviewed outside-adopter evidence**, or **deliberate strategic product decision**.

The repo's current discipline here is correct. Mature ecosystems show that widening too early creates confusing abstractions and weakens the core indexing/sync story.

## Updated priority order

1. **Maintenance-and-evidence mode**
   Keep release/support truth, required gates, focused proof commands, and advisory proof posture coherent after v1.29.
2. **Outside-adopter evidence**
   Use real integration attempts to decide whether future work is a bugfix, docs patch, or no-op.
3. **Release and planning truth maintenance**
   Keep the release train, docs/support truth, and roadmap/JTBD rankings coherent.
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

In practical terms, Scrypath now looks roughly **92-94% done** for its stated v1 scope. That means:

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

The `v1.20` `Scrypath.SearchModule` mismatch is resolved as archive-correction: branch tip does not ship that module and future milestone planning must not assume it exists. The remaining credibility issues are narrower: keep shipped fan-out declarations ergonomic, keep v1.28 E2E tenant proof honest, and continue treating outside-adopter evidence as the only reason to reopen major feature breadth.
