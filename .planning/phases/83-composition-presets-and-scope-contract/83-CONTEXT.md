# Phase 83: Composition Presets And Scope Contract - Context

**Gathered:** 2026-05-23
**Status:** Ready for planning

<domain>
## Phase Boundary

Freeze a bounded plain-data composition seam over the existing `Scrypath.search/3` input shape so host apps can define reusable presets and additive scopes without creating a second query runtime, moving search ownership onto schemas, or turning Phoenix helpers into a framework facade.

This phase is about the single-search composition contract only. It does not expose `%Scrypath.Query{}` publicly, does not make schemas or `Scrypath.Phoenix` own composition, does not introduce generated runtime verbs, and does not claim to solve tenant authorization, related-data propagation, or saved-search persistence.

</domain>

<decisions>
## Implementation Decisions

### Composition contract shape
- **D-01:** The public composition seam should stay plain-data and function-first. The recommended core shape is a fragment envelope such as `%{defaults: ..., fixed: ...}` returned by host-defined code and merged by Scrypath into the existing plain-data search-args vocabulary.
- **D-02:** Presets and scopes should be **context-owned or feature-owned code**, not schema declarations, not Phoenix-only helpers, and not generated runtime APIs. Scrypath should help compose them, not own the host app's feature policy.
- **D-03:** Phase 83 should not expose callback-heavy composition functions as the main public contract. Host callbacks are acceptable as app-internal implementation detail, but the Scrypath-facing seam should remain inspectable plain data.
- **D-04:** Phase 83 should not introduce a behaviour-first extension model or macro DSL as the default public surface. Those shapes add ceremony and long-term API pressure too early for this milestone.

### Precedence and merge rules
- **D-05:** Use a **two-tier precedence model**: overridable `defaults` plus limited `fixed` constraints. Do not build a general-purpose composition algebra.
- **D-06:** `defaults` may be supplied for all public composition fields: `text`, `filter`, `sort`, `page`, `facets`, `facet_filter`, and `per_query`.
- **D-07:** `fixed` constraints are allowed only for `filter` and `facet_filter`. Do not allow fixed `text`, `sort`, `page`, `facets`, or `per_query` in v1.22.
- **D-08:** `text` is default-only: presets/scopes may fill it when absent or blank, but caller-supplied text wins.
- **D-09:** `sort`, `page`, and `facets` use whole-value caller override semantics: defaults may provide a full value, but caller input replaces that full value rather than deep-merging.
- **D-10:** `filter` and `facet_filter` defaults merge by key with caller bias. `fixed` entries lock those keys and must conflict-check rather than silently lose or overwrite policy.
- **D-11:** `per_query` follows the existing bounded public story: defaults may shallow-merge into the map, but caller input wins on overlapping keys. Do not introduce fixed `per_query` constraints.
- **D-12:** Reject surprising unlock semantics. No `nil`, empty list, or similar sentinel should mean “remove a fixed constraint.”
- **D-13:** When caller input conflicts with fixed constraints on the same key, composition should fail explicitly with a stable, field-scoped error rather than silently prefer one side.
- **D-14:** When multiple scopes contribute incompatible fixed constraints on the same key, composition should also fail explicitly. “Last fixed scope wins” is too surprising.

### Visibility and inspectability
- **D-15:** Composition results must expose debug-friendly visibility as part of the same public plain-data result rather than through a second public runtime.
- **D-16:** The minimum viable visibility surface should be stable and coarse-grained: `applied`, `defaulted`, `fixed`, plus optional `sources` and `warnings` keyed in the same public vocabulary as the final search args.
- **D-17:** Do not expose a detailed merge trace, internal precedence graph, backend query structs, or `%Scrypath.Query{}` in the public visibility contract.
- **D-18:** The visibility contract should be useful for host tests, logs, docs examples, and future metadata/UI layers, but it should not pressure Scrypath into becoming an “explain engine.”

### Boundary guardrails
- **D-19:** Keep composition definitions feature-level and context-owned. Scrypath should not re-center search policy on `use Scrypath` schema declarations.
- **D-20:** `Scrypath.Phoenix` must remain request-edge glue only. Composition should stay framework-agnostic and reusable outside Phoenix.
- **D-21:** Do not ship schema-generated search verbs, controller/LiveView macros, or runtime helpers that execute search from composition definitions.
- **D-22:** Do not imply that composition solves tenant-safe access, authorization, or related-data rebuild correctness. Those remain host-owned or future-milestone concerns.

### Decision cadence
- **D-23:** Carry this preference forward in GSD planning and execution for this arc: default to decisive, cohesive recommendations that preserve least surprise, strong DX, and boundary honesty. Escalate back to the user only when a choice materially changes public API shape, semver cost, or milestone scope.

### the agent's Discretion
- Exact public module and function names for the composition seam, as long as they remain literal, small, and data-first.
- Exact result-wrapper shape for the final plain-data composition output, provided it includes the final criteria plus the coarse visibility surface above.
- Exact error code taxonomy for fixed-constraint conflicts, provided the failures stay explicit, stable, and field-scoped.
- Exact internal representation for applying fragments, provided the public contract remains plain data and does not leak internal query structs or a second DSL.

</decisions>

<specifics>
## Specific Ideas

- The desired feel is closer to Ecto and Flop than to a model-magic search mixin: explicit, composable, inspectable, and boring in the best way.
- The strongest “do not do this” signals from ecosystem research were Rails-style hidden scoping/default-scope behavior, callback-heavy realtime magic, and framework-owned search facades that quietly become the real application boundary.
- Searchkick, Laravel Scout, and meilisearch-rails are useful inspiration for ergonomic adoption, but Scrypath should copy their convenience selectively and avoid their pressure toward model-owned search behavior.
- The composition seam should feel like “small reusable plain-data fragments over the canonical runtime,” not like “yet another query builder.”
- If the library ever needs persisted or externally exchanged presets/scopes, that is the one contract decision important enough to justify future re-evaluation. It is not required for this phase.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and milestone guardrails
- `.planning/ROADMAP.md` — Phase 83 goal, success criteria, and milestone sequencing for composition, metadata, and real-app proof
- `.planning/REQUIREMENTS.md` — `CMP-01` through `CMP-04` and the v1.22 scope gates
- `.planning/PROJECT.md` — current product posture, v1.22 guardrails, and the “no facade / no public %Scrypath.Query{}` line
- `.planning/STATE.md` — current milestone state plus the explicit v1.22 scope guard

### Prior phase decisions that remain locked
- `.planning/phases/81-edge-normalization-errors-and-phoenix-wrappers/81-CONTEXT.md` — request-edge grammar, optional Phoenix helper posture, and `handle_params/3`-first boundary decisions
- `.planning/phases/82-docs-examples-and-drift-protection/82-CONTEXT.md` — core-first docs posture, optional Phoenix hierarchy, and boundary-honest story constraints

### Current public runtime and edge seams
- `lib/scrypath.ex` — canonical public runtime entrypoints, current reflection helpers, and explicit boundary language
- `lib/scrypath/search.ex` — current single-search and multi-search runtime behavior, validation/raise posture, and `search_many/2` contract
- `lib/scrypath/query_params.ex` — existing public plain-data contract that composition must stay aligned with
- `lib/scrypath/phoenix.ex` — optional request-edge helper boundary that composition must not absorb
- `lib/scrypath/query.ex` — internal query state reminder; must not become public API
- `lib/scrypath/options.ex` — current validated search option vocabulary and search-field semantics
- `guides/request-edge-search.md` — canonical “params normalize once, contexts stay canonical, Phoenix optional” story
- `guides/phoenix-contexts.md` — contexts as the application boundary
- `guides/phoenix-liveview.md` — URL/`handle_params/3`-owned LiveView search flow
- `guides/multi-index-search.md` — current `search_many/2` merge/failure story that future composition parity must respect
- `guides/per-query-tuning-pipeline.md` — existing public `:per_query` posture and precedence expectations

### Prompt corpus constraints and research lenses
- `prompts/elixir-best-practices-deep-research.md` — function-first, explicit return-shape, anti-magic Elixir library guidance
- `prompts/ecto-best-practices-deep-research.md` — context-boundary, thin-schema, and explicit orchestration guidance
- `prompts/phoenix-best-practices-deep-research.md` — web-layer vs context boundary expectations
- `prompts/phoenix-live-view-best-practices-deep-research.md` — URL-state, `handle_params/3`, and LiveView boundary guidance
- `prompts/elixir-plug-ecto-phoenix-system-design-best-practices-deep-research.md` — process/boundary/runtime discipline for Elixir systems
- `prompts/elixir-search-lib-deep-research.md` — search-library architecture, operational seams, and category strategy
- `prompts/elixir-opensource-libs-best-practices-deep-research.md` — OSS library API discipline and semver/DX expectations
- `prompts/search-lib-use-cases-deep-research.md` — adopter jobs and future-pressure priorities for Scrypath
- `prompts/scrypath-brand-book.md` — calm, exact, non-hype product voice and positioning

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/scrypath/query_params.ex`: stable plain-data vocabulary already accepted by `QueryParams.to_search_args/1`
- `lib/scrypath/search.ex`: canonical runtime that composition must feed instead of replacing
- `lib/scrypath/options.ex`: current validation grammar that constrains what fields composition may emit
- `guides/request-edge-search.md`: already teaches a narrow “edge -> plain data -> context -> search/3” lane that composition should extend rather than fork
- `guides/multi-index-search.md`: existing right-biased shared-vs-entry merge story that should inform future `search_many/2` composition parity

### Established Patterns
- Public Scrypath surfaces stay explicit, function-based, and low-magic
- Contexts remain the application boundary; Phoenix helpers normalize edge state only
- `%Scrypath.Query{}` stays internal normalized runtime state, not public contract
- Search semantics prefer explicit validation failures over silent contract widening

### Integration Points
- Phase 83 should introduce composition as a new plain-data seam that resolves into the same fields already accepted by `Scrypath.search/3`
- The visibility output should be useful to future metadata reflection and `search_many/2` parity work without forcing those concerns into this phase
- Conflict errors and docs examples should plug naturally into the existing field-scoped error/documentation style established by v1.21

</code_context>

<deferred>
## Deferred Ideas

- Persisted or externally exchanged preset/scope definitions
- Schema macros or behaviour-heavy composition frameworks
- Phoenix-owned composition helpers, controller macros, or LiveView runtime facades
- Generated runtime search verbs derived from presets/scopes
- Tenant authorization, access control, and related-data propagation as part of the composition contract
- Saved-search persistence, UI widgets, or broader framework-owned search UX layers

</deferred>

---

*Phase: 83-composition-presets-and-scope-contract*
*Context gathered: 2026-05-23*
