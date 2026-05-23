# Project Research Summary

**Project:** Scrypath
**Domain:** Ecto-native search-module ergonomics for Phoenix and Elixir apps
**Researched:** 2026-05-23
**Confidence:** HIGH

## Executive Summary

`v1.22 — Composition And Real-App Depth` should be treated as a bounded continuation of the active search-module arc, not as a new product surface. The milestone exists to make the `v1.21` request-edge toolkit reusable across real app flows through plain-data presets, additive scopes, `search_many/2`-aligned composition, and honest metadata reflection for filters, sorts, facets, and paging. The canonical runtime remains `Scrypath.search/3` and `Scrypath.search_many/2`; contexts remain the application boundary; Phoenix remains optional.

The recommended approach is to add one feature-level composition seam above `Scrypath.QueryParams` and below application contexts. Composition should only assemble existing search args, apply deterministic merge rules, and expose data-first metadata that host apps can render. It should not execute queries, expose `%Scrypath.Query{}`, move feature declarations onto schemas, or introduce Phoenix-dependent runtime behavior. This keeps the post-v1.19 guardrail intact: v1.22 deepens one proven arc instead of reopening broad backend, UI, auth, or operations scope.

The main risks are freezing too much abstraction too early, rebuilding a hidden query DSL, and letting “scopes” drift into tenancy, auth, or related-data semantics. Mitigation is straightforward: keep the public seam plain-data and small, lock a short precedence table before metadata work lands, require `search_many/2` parity before API freeze, and make “host-owned, not solved here” language explicit in both requirements and real-app docs.

## Key Findings

### Recommended Stack

v1.22 does not justify a new runtime subsystem. The right stack move is to keep core dependencies flat, correct the public dependency contract around `:telemetry`, and add stronger invariant testing for composition behavior. The milestone is a library-layer composition slice over the existing Meilisearch-first runtime, not a framework or adapter expansion.

**Core technologies:**
- `Elixir ~> 1.17` / current Ecto surface: no milestone pressure to widen runtime support.
- `:telemetry ~> 1.4`: should become a direct dependency because metadata and observability are now part of the public contract.
- `NimbleOptions ~> 1.1`: validate bounded preset, scope, and metadata declarations.
- `Req` and existing backend seam: composition must preserve current transport and Meilisearch-first behavior.
- `Oban` optional path: unchanged; composition must not create queue coupling.
- `StreamData ~> 1.3` test-only: property-test merge, precedence, and metadata round-trip invariants.

### Expected Features

The in-scope feature set is narrow and product-shaped: reuse repeated search flows without changing the runtime story. Presets and scopes must compile to the same plain-data args shape already accepted by contexts, and metadata must tell host apps what they can truthfully render.

**Must have (table stakes):**
- Named plain-data presets over the shipped `QueryParams -> search args -> context -> Scrypath.search/3` path.
- Additive scope composition with deterministic merge rules and visible applied/defaulted criteria.
- Metadata reflection for declared filters, sorts, facets, paging, and capability constraints.
- `search_many/2` composition parity with per-entry presets and honest per-schema behavior.
- Worked real-app examples proving reduced glue without hiding operational boundaries.

**Should have (competitive):**
- A canonical “composition is data” API rather than a behavioral query object.
- Introspectable definition metadata for Phoenix, LiveView, and JSON consumers.
- Boundary-honest tenant-scope injection seam that keeps access policy app-owned.
- Recovery-aware guidance that distinguishes simple preset changes from rebuild/reindex cases.

**Defer / keep out of scope:**
- Public `%Scrypath.Query{}` or any new query DSL / runtime search object.
- Schema-generated runtime search functions or schema-owned UX declarations.
- Phoenix-specific controller/LiveView macros, generated UI components, or form builders.
- Automatic related-data propagation, authz enforcement, or tenant isolation claims.
- Broader backend abstraction, saved-search persistence, or cross-schema merged-relevance facades.

### Architecture Approach

Composition belongs in context-owned feature definition modules, not on Ecto schemas and not in Phoenix helpers. The target flow is `browser params/internal inputs -> Scrypath.QueryParams -> Scrypath.Composition -> context -> Scrypath.search/3 or search_many/2`. Schemas continue to own index-contract metadata only; feature modules own presets, scopes, defaults, and UI metadata.

**Major components:**
1. `Scrypath.Composition` — public build/expand surface for presets, scopes, and composed args.
2. `Scrypath.Composition.Definition` — bounded declaration contract for feature-level definitions.
3. `Scrypath.Composition.Metadata` — framework-agnostic reader for normalized UI capability data.
4. Internal builder/merge modules — isolate precedence, normalization, and `search_many/2` mapping logic.

### Critical Pitfalls

1. **Freezing the wrong abstraction** — keep the seam explainable as “prepare search args, then call the existing runtime.”
2. **Rebuilding a hidden query DSL** — lock one short precedence table and normalize into existing option grammar only.
3. **Scope spill into tenant/auth/related-data semantics** — keep those concerns in host contexts and docs, not in runtime composition.
4. **Phoenix leakage into core** — metadata must stay plain data; rendering and URL ergonomics remain optional wrappers/examples.
5. **Metadata drift from runtime behavior** — derive metadata from canonical declarations and validators, then lock parity with tests and docs contracts.

## Implications for Roadmap

Based on research, suggested phase structure:

### Phase 1: Composition Seam And Contract
**Rationale:** Freeze the smallest public seam before adding metadata or examples. Every later slice depends on stable preset/scope semantics.
**Delivers:** `Scrypath.Composition`, bounded definition shape, plain-data fragments (`defaults` vs `fixed`), deterministic merge rules, applied-args introspection, direct `:telemetry` dependency, and property-style verification of precedence rules.
**Addresses:** Reusable presets, additive scopes, caller-override rules, debug visibility.
**Avoids:** Freezing the wrong abstraction, hidden DSL drift, silent merge behavior.

### Phase 2: Metadata Reflection And Multi-Search Parity
**Rationale:** Once merge semantics are fixed, expose honest metadata from the same declarations and prove the model survives `search_many/2`.
**Delivers:** Framework-agnostic metadata contracts for filters/sorts/facets/paging, applied-state reflection, per-entry composition helpers for `search_many/2`, parity tests, and docs-contract coverage.
**Addresses:** UI metadata exposure, multi-search composition, capability truth for Phoenix/JSON consumers.
**Avoids:** Metadata drift, Phoenix leakage, single-search-only ergonomics.

### Phase 3: Real-App Adoption Proof And Guardrail Docs
**Rationale:** The milestone is complete only when the new seam is shown in realistic app flows and the non-goals are explicit enough to block misuse.
**Delivers:** Canonical real-app composition guide, updated Phoenix/request-edge guidance, at least two worked examples with different app shapes, and explicit “host-owned, not solved here” coverage for tenancy, auth, related-data propagation, and rebuild/reindex boundaries.
**Addresses:** Real-app depth, adoption confidence, bounded milestone narrative.
**Avoids:** Framework magic in examples, overfitting to one dogfood app, false security/operations promises.

### Phase Ordering Rationale

- Composition contract must come first because metadata and docs are downstream of merge semantics.
- Metadata and `search_many/2` belong together because the public API should not freeze around single-search ergonomics alone.
- Real-app examples come last so they validate the shipped seam rather than driving premature abstraction.
- This order preserves the post-v1.19 guardrail by keeping the milestone focused on one library boundary at a time.

### Likely Requirement Categories

- **Composition contract:** definition shape, preset/scope declaration rules, merge precedence, applied-args introspection.
- **Runtime boundary protection:** contexts stay canonical, `%Scrypath.Query{}` stays internal, no schema-owned UX runtime.
- **Metadata contract:** filters, sorts, facets, paging, capability reflection, and applied/default visibility.
- **Multi-search alignment:** `search_many/2` shared/per-entry composition and failure-boundary preservation.
- **Verification and drift gates:** property tests, parity tests, docs contracts, worked-example smoke coverage.
- **Documentation and adoption proof:** real-app guides, explicit non-goals, operational honesty callouts.

### Merge-Blocking Guardrails

- Any proposal that introduces a public query struct, query DSL, preset inheritance tree, or schema-generated runtime search verbs should be rejected from v1.22.
- Any core API that depends on Phoenix, LiveView, Plug connection state, or generated UI widgets should be rejected from v1.22.
- Any composition feature that claims to solve tenant authorization, related-data propagation, or operational recovery automatically should be rejected from v1.22.
- Any metadata surface not derived from canonical declarations/validators, or any design that skips `search_many/2` parity before API freeze, should be rejected from v1.22.
- Any change that broadens backend promises beyond the existing Meilisearch-first seam should be rejected from v1.22.

### Research Flags

Phases likely needing deeper research during planning:
- **None by default for the core milestone slices:** the research quality is already high and the architecture direction is clear.
- **Targeted follow-up only if scope drifts:** if planning tries to add tenant policy, related-data automation, or Phoenix-heavy UI ergonomics, spin that into a separate future research/phase instead of widening v1.22.

Phases with standard patterns (skip `research-phase`):
- **Phase 1:** plain-data composition seam over existing args contract is well-specified by the current research.
- **Phase 2:** metadata parity and `search_many/2` alignment are already documented with clear constraints.
- **Phase 3:** real-app proof is largely a docs/examples/verification exercise, not a missing-architecture problem.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Strong local context and clear “no new runtime subsystem” conclusion; only small dependency corrections are justified. |
| Features | HIGH | Scope, non-goals, and milestone slices are consistent across project context, seed, and feature research. |
| Architecture | HIGH | Boundary placement is crisp: composition above QueryParams, below contexts, schemas remain metadata-only. |
| Pitfalls | HIGH | The major risks are concrete, repeated across files, and directly actionable as merge blockers. |

**Overall confidence:** HIGH

### Gaps to Address

- Exact public naming for “definition”, “preset”, “scope”, and “metadata” should be resolved early in requirements to avoid terminology drift.
- The final metadata shape should be validated against at least two distinct adopter flows so one example does not overdetermine the API.
- Conflict behavior for locked vs user-overridable values should be made explicit in requirements and tests before implementation starts.

## Sources

### Primary (HIGH confidence)
- `.planning/research/STACK.md` — stack constraints, dependency changes, non-additions.
- `.planning/research/FEATURES.md` — in-scope feature set, differentiators, anti-features, MVP slices.
- `.planning/research/ARCHITECTURE.md` — component boundaries, public seam, definition placement, merge semantics.
- `.planning/research/PITFALLS.md` — critical risks, phase warnings, roadmap prevention strategy.
- `.planning/PROJECT.md` — milestone framing, post-v1.19 guardrail, current product boundary.
- `.planning/MILESTONE-ARC.md` — active arc intent and v1.22 sequence placement.
- `.planning/seeds/SEED-002-composition-real-app-depth.md` — milestone trigger and bounded scope.

### Secondary (MEDIUM confidence)
- Phoenix contexts and LiveView docs — support keeping contexts canonical and UI concerns optional.
- Ecto dynamic-query guidance — supports plain-data composition and explicit merge semantics.
- Searchkick, Scout, Meilisearch Rails, and backend docs referenced by the research files — useful comparative evidence for anti-features and UX expectations.

---
*Research completed: 2026-05-23*
*Ready for roadmap: yes*
