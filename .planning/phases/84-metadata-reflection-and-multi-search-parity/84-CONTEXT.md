# Phase 84: Metadata reflection and multi-search parity - Context

**Gathered:** 2026-05-23
**Status:** Ready for planning

<domain>
## Phase Boundary

Expose honest, framework-agnostic search capability metadata from the same declarations and validators that already define Scrypath runtime behavior, and extend the Phase 83 plain-data composition seam so host apps can assemble `search_many/2` flows without a second DSL or widened runtime semantics.

This phase is about reflection shape, metadata density, and composition parity for multi-search. It does not create generated UI widgets, does not make Phoenix or schemas own runtime behavior, does not publish `%Scrypath.Query{}`, does not blend per-schema multi-search boundaries into one fake global contract, and does not imply that tenant policy, authorization, or related-data propagation are solved by metadata or composition.

</domain>

<decisions>
## Implementation Decisions

### Metadata API shape
- **D-01:** Use a two-layer reflection model, not a single monolithic surface:
  - canonical schema capability metadata under `Scrypath`
  - derived current-state metadata from composition and attempted inputs
- **D-02:** Schema metadata is the source of truth for what a schema supports. Composition metadata is an overlay for what is active, defaulted, fixed, or unsupported for a specific call.
- **D-03:** Do not make composition the canonical source of filter, sort, facet, or paging capability truth. It must derive from the same declarations and validators that already back runtime behavior.
- **D-04:** Keep both surfaces plain-data and function-based. No macros, generated schema runtime verbs, or Phoenix-shaped return types.

### Capability metadata detail
- **D-05:** The reflected payload should be medium-density, not a shallow family summary and not a high-density UI status graph.
- **D-06:** Split the metadata envelope into:
  - `capabilities` for declaration-backed support and limits
  - `resolved` for call-specific state
  - a small explicit advisory area for host-owned concerns
- **D-07:** `capabilities` should cover filters, sorts, facets, paging, and engine/runtime limits that are true before caller input is applied.
- **D-08:** `resolved` should carry the same public vocabulary already established by composition and query-param work: `applied`, `defaulted`, `fixed`, and `unsupported` where relevant.
- **D-09:** `fixed` and `defaulted` must remain distinct everywhere. A fixed constraint is policy; a default is an overridable starting point.
- **D-10:** `unsupported` should appear only when Scrypath is reflecting an attempted caller or composed payload against a schema. It must stay field-scoped and explicit rather than collapsing into omission or generic booleans.
- **D-11:** Do not ship a per-control or widget-shaped metadata graph in this phase. Scrypath should describe truthful capability/state data, not own UI semantics.

### Multi-search composition shape
- **D-12:** Preserve the existing `search_many/2` executor and tuple/shared-option contract. Phase 84 adds lowering helpers, not a new runtime entrypoint or multi-search DSL.
- **D-13:** Support both shared and per-entry composition, but asymmetrically:
  - per-entry composition is the canonical unit
  - shared composition may lower `defaults` only into shared opts
- **D-14:** Do not support shared `fixed` composition for `search_many/2`. That would introduce new conflict semantics above today’s right-biased shared-vs-entry merge and increase semver/surprise cost.
- **D-15:** Per-entry composition should lower to the existing tuple shape `{schema, text, keyword_opts}` after normal single-search composition.
- **D-16:** Shared composition should lower only into the existing shared search-option vocabulary. It must not create a shared `text` abstraction because `search_many/2` has no shared text slot today.
- **D-17:** Multi-search-only rails stay outside composition:
  - `federation_weight`
  - `global_schemas`
  - `max_schemas`
  - federation limits and timeouts
  - backend/runtime config
- **D-18:** Keep `:all` honest. Shared defaults may apply to raw `{:all, text, opts}` entries, but `:all` should not pretend to be a schema-specific composed entry before expansion.

### Parity and failure visibility
- **D-19:** Metadata must represent unsupported capabilities explicitly per schema or per entry. Never imply support through silence when a host could reasonably mistake omission for availability.
- **D-20:** `search_many/2` reflection should stay entry-scoped by default. Do not produce a merged union capability surface across schemas.
- **D-21:** If any shared summary exists, it must be clearly secondary and lossy relative to per-entry metadata.
- **D-22:** Keep per-entry boundaries visible for applied/defaulted/fixed/unsupported state as well as capability support. Multi-search should remain honest about differences between schemas.
- **D-23:** Treat tenant policy, authorization, and related-data propagation as labeled host-owned concerns in metadata/docs, never as implied capability gaps Scrypath is about to solve.
- **D-24:** Reserve tuple/raise failures for execution and invalid declarations. Reflection should communicate parity and unsupported states through inspectable data, not by turning ordinary UI questions into noisy runtime branching.

### Decision cadence
- **D-25:** Carry this preference forward in downstream planning and execution for this arc: default to decisive, cohesive recommendations that optimize for least surprise, strong DX, calm explicit APIs, and alignment with the project vision. Escalate only when a choice materially changes public API shape, future semver cost, or milestone scope.

### the agent's Discretion
- Exact public function names and module placement for schema metadata and derived reflection helpers, provided the canonical-vs-derived split stays obvious.
- Exact payload key names beneath `capabilities`, `resolved`, and the host-owned advisory section, provided they remain small, plain, and framework-agnostic.
- Exact lowering helper names for shared and per-entry multi-search composition, provided `search_many/2` remains the only executor and no second DSL appears.
- Exact `unsupported` reason taxonomy, provided it is stable, field-scoped, and honest about why a capability does not apply.

</decisions>

<specifics>
## Specific Ideas

- The desired feel is closer to Flop-style Elixir reflection than to Searchkick-style model magic: explicit capability data, explicit validated state, and host-owned rendering.
- The strongest coherent shape is:
  - schema metadata answers “what is allowed”
  - composition/reflection answers “what this call resolved to”
  - `search_many/2` keeps those answers per entry instead of pretending there is one universal search form
- Searchkick, meilisearch-rails, and Laravel Scout are useful DX references, but their biggest footgun for Scrypath is library-owned magic that quietly becomes the real application boundary. This phase should preserve Scrypath’s calmer context-owned posture.
- Successful ecosystems batch normal per-query objects for multi-search rather than inventing a second language. Scrypath should follow that pattern and keep lowering explicit.
- Great DX here means Phoenix, LiveView, JSON, and non-Phoenix hosts can all inspect the same plain metadata contract without Scrypath implying a UI layer.
- Shift this preference left within the GSD workflow for this product area: prefer coherent, high-confidence recommendations by default and surface alternatives only when they matter to semver or scope.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and locked requirements
- `.planning/ROADMAP.md` — Phase 84 goal, success criteria, and dependency on Phase 83
- `.planning/REQUIREMENTS.md` — `META-01`, `META-02`, `META-03`, `MSCH-01`, and `MSCH-02`
- `.planning/PROJECT.md` — product posture, Ecto-native UX priority, and operational honesty guardrails
- `.planning/STATE.md` — current milestone posture and active phase state

### Prior phase decisions that remain locked
- `.planning/phases/83-composition-presets-and-scope-contract/83-CONTEXT.md` — plain-data composition seam, defaults/fixed rules, visibility vocabulary, and host-owned boundary decisions
- `.planning/phases/82-docs-examples-and-drift-protection/82-CONTEXT.md` — core-first docs posture, optional Phoenix hierarchy, and boundary-honest public story constraints
- `.planning/phases/81-edge-normalization-errors-and-phoenix-wrappers/81-CONTEXT.md` — request-edge grammar, structured error posture, and Phoenix/LiveView boundary decisions

### Phase 84 design contract
- `.planning/phases/84-metadata-reflection-and-multi-search-parity/84-UI-SPEC.md` — visual/interaction contract for metadata-heavy examples and parity honesty

### Current public runtime and reflection seams
- `lib/scrypath.ex` — existing public reflection helpers and boundary language
- `lib/scrypath/schema.ex` — schema declaration storage and `__scrypath__/1` metadata seam
- `lib/scrypath/options.ex` — canonical validator logic for filter, sort, facet, and paging capability truth
- `lib/scrypath/composition.ex` — public composition seam and current visibility vocabulary
- `lib/scrypath/search.ex` — canonical `search/3` and `search_many/2` execution semantics and error/failure boundaries
- `lib/scrypath/multi_search/entries.ex` — shared-vs-entry precedence, `:per_query` merge rules, and multi-search rails
- `lib/scrypath/query_params.ex` — public request-edge plain-data vocabulary aligned with current search fields
- `guides/multi-index-search.md` — canonical per-entry, federation, `:all`, and partial-failure honesty story
- `guides/request-edge-search.md` — current edge-to-runtime boundary story
- `guides/faceted-search-with-phoenix-liveview.md` — facet capability semantics and host-rendered UI expectations
- `guides/per-query-tuning-pipeline.md` — shared vs per-entry merge expectations and public query option posture

### Prompt corpus constraints and research lenses
- `prompts/elixir-best-practices-deep-research.md` — explicit function-first Elixir API guidance and anti-magic posture
- `prompts/ecto-best-practices-deep-research.md` — context-boundary, thin-schema, and orchestration guidance
- `prompts/phoenix-best-practices-deep-research.md` — Phoenix optional-adapter and context-first architecture guidance
- `prompts/phoenix-live-view-best-practices-deep-research.md` — URL-state and host-owned LiveView behavior guidance
- `prompts/elixir-plug-ecto-phoenix-system-design-best-practices-deep-research.md` — system-level boundary and runtime design guidance
- `prompts/elixir-search-lib-deep-research.md` — search-library architecture and category-shaping guidance
- `prompts/elixir-opensource-libs-best-practices-deep-research.md` — OSS API discipline, semver, and DX guidance
- `prompts/search-lib-use-cases-deep-research.md` — adopter jobs, ecosystem lessons, and anti-facade warnings
- `prompts/scrypath-brand-book.md` — calm, exact, Ecto-native positioning and product voice

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/scrypath.ex`: existing small reflection surface that can grow without introducing schema-generated runtime APIs
- `lib/scrypath/schema.ex`: canonical declaration store for fields, filterable, faceting, sortable, settings, and document metadata
- `lib/scrypath/options.ex`: current validator truth source for allowed filters, sorts, facets, and paging semantics
- `lib/scrypath/composition.ex`: existing public result vocabulary with `applied`, `defaulted`, `fixed`, `sources`, and `warnings`
- `lib/scrypath/multi_search/entries.ex`: already encodes the right-biased shared-vs-entry precedence story Phase 84 must preserve
- `guides/multi-index-search.md`: already teaches per-schema boundaries, no merged-facets illusion, and honest federation language

### Established Patterns
- Public Scrypath APIs stay explicit, function-based, plain-data, and low-magic
- Schema declarations define capability truth; contexts own orchestration; Phoenix remains optional glue
- `%Scrypath.Query{}` stays internal normalized runtime state
- `search_many/2` preserves per-entry behavior and failure boundaries rather than flattening schemas into one global search abstraction
- Visibility contracts should help tests, logs, docs, and host UIs without becoming a generated control system

### Integration Points
- New schema metadata helpers should derive directly from the same declaration and validation seams already used by `search/3`
- Derived reflection should sit beside composition and attempted input shaping, not inside backend adapters or Phoenix helpers
- Multi-search parity should be implemented as lowering into the existing tuple/shared-option contract rather than widening `search_many/2`
- Phase 84 tests should prove parity between:
  - schema declarations
  - validator truth
  - composition visibility
  - `search_many/2` entry reflection

</code_context>

<deferred>
## Deferred Ideas

- Generated UI widgets or first-party Phoenix form/control components
- Persisted saved-search contracts or a UI-shaped per-control metadata graph
- Shared `fixed` policy semantics for multi-search composition
- A merged global capability surface across multi-search schemas
- Making tenant policy, authorization, or related-data propagation part of the metadata or composition promise

</deferred>

---

*Phase: 84-metadata-reflection-and-multi-search-parity*
*Context gathered: 2026-05-23*
