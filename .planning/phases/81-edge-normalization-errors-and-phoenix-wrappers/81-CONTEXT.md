# Phase 81: Edge normalization errors and Phoenix wrappers - Context

**Gathered:** 2026-05-22
**Status:** Ready for planning

<domain>
## Phase Boundary

Add one-time request-edge normalization semantics plus optional thin Phoenix helpers for controller, form, URL, and LiveView flows on top of the Phase 80 public query toolkit contract.

This phase clarifies how browser-shaped params become the existing plain-data Scrypath search-args shape, how invalid edge input is reported, and how Phoenix consumers round-trip and render that state. It does not create a second runtime, does not move search orchestration out of app contexts, does not expose `%Scrypath.Query{}` as public API, and does not widen into UI widgets, macros, controller facades, or schema-generated verbs.

</domain>

<decisions>
## Implementation Decisions

### Normalization grammar
- **D-01:** Phase 81 should adopt a conservative Plug-native browser grammar, not a rich query DSL. Accept only request shapes Plug already decodes predictably and that ordinary Phoenix forms/URLs naturally produce.
- **D-02:** Canonical text input is `q`, with `text` accepted as a compatibility alias. Normalize once into the existing `Scrypath.QueryParams` plain-data shape.
- **D-03:** Canonical pagination input is `page[number]` and `page[size]`, parsed from positive integer strings with explicit defaults/limits preserved by the normalized contract.
- **D-04:** Canonical facet input is `facets[]` for repeated facet names.
- **D-05:** Canonical filter input is `filter[field]` for a scalar value and `filter[field][]` for repeated values. `facet_filter` follows the same scalar-or-repeated-value shape.
- **D-06:** Canonical sort input should optimize for the common case with `sort[field]` plus `sort[dir]`. If multi-sort is supported in this phase, use only explicit indexed entries such as `sort[0][field]` and `sort[0][dir]`; do not rely on ambiguous nested-list decoding.
- **D-07:** Ignore unrelated top-level params outside Scrypath-owned namespaces. Inside owned namespaces, validate strictly and report structured errors rather than silently dropping malformed or unknown nested keys.
- **D-08:** Do not introduce a predicate/operator mini-language in this phase. Keep public edge semantics narrow: equality, repeated-value membership, and the existing runtime-compatible search options only.
- **D-09:** `per_query` is not part of the primary browser-friendly grammar for this phase. Do not widen the public edge around advanced Meilisearch tuning just to make Phoenix examples feel shorter.

### Error contract
- **D-10:** Invalid request-edge input should become an expected non-raising result, not an exception. Phase 81 should introduce a public normalize/cast path that returns `{:ok, query_params}` or `{:error, error_map}`.
- **D-11:** The core public error contract should be aggregate and field-scoped, not first-error-only and not a literal `%Ecto.Changeset{}`.
- **D-12:** The error payload should contain:
  - `form_errors` for root-level issues such as unknown params or mutually exclusive combinations
  - `field_errors` keyed by top-level public fields such as `:q`, `:filter`, `:sort`, `:page`, `:facets`, and `:facet_filter`
  - `errors` as a flat machine-readable list for tests, logging, and adapters
- **D-13:** Each issue should include stable machine-readable metadata, at minimum `code`, `message`, `path`, and `meta`; `field` is useful when the issue belongs to one top-level field.
- **D-14:** Do not freeze Ecto-specific changeset semantics into the core edge contract. A Phoenix/Ecto adapter may project Scrypath errors into `to_form/2`-friendly tuples, but the core contract stays framework-light.
- **D-15:** Keep request-edge normalization errors clearly separate from later schema-specific runtime validation or backend/search errors.

### Phoenix helper surface
- **D-16:** Ship one optional Phoenix namespace with plain helper functions only. The default recommended public shape is `Scrypath.Phoenix`, not macros and not controller mixins.
- **D-17:** Phoenix helpers may bridge normalized Scrypath data into:
  - `Phoenix.Component.to_form/2`-friendly values and errors
  - verified-route query params / URL round-tripping
  - very thin `from_params` convenience that delegates to the core normalizer
- **D-18:** Phoenix helpers must not execute searches, call app contexts, own socket lifecycle transitions, or become the canonical runtime path.
- **D-19:** Do not ship public controller helpers, `use Scrypath.Phoenix`, generated components, or styled search widgets in this phase.
- **D-20:** Keep helper naming literal and boring. The surface should read as param/form/url helpers, not as a Phoenix search framework.

### LiveView flow
- **D-21:** The canonical LiveView pattern is `handle_params/3` first. URL params are the shareable source of truth for search state.
- **D-22:** `handle_event/3` should only collect transient UI intent and compute/push the next URL state with `push_patch/2` or equivalent navigation. It should not be a second search execution path.
- **D-23:** `handle_params/3` should be the single place that:
  - reads URL params
  - normalizes them once through the Scrypath edge contract
  - assigns attempted values plus field-scoped errors for rendering
  - calls the app context when normalization succeeds
- **D-24:** On normalization failure, LiveView should render the attempted state and field errors directly without searching and without collapsing errors into flash-only messaging.
- **D-25:** Phoenix helpers may support form-friendly value/error shaping and URL param round-tripping for LiveView, but they must not hide state transitions behind macros or opaque callbacks.

### Decision cadence
- **D-26:** Bias toward decisive, conservative defaults during planning and implementation. Only escalate choices that materially affect public API shape, milestone boundary honesty, or future semver cost.

### the agent's Discretion
- Exact function names inside the chosen plain-function Phoenix namespace, as long as they stay literal and narrow.
- Exact issue-code taxonomy, provided codes stay stable, obvious, and scoped to request-edge failures.
- Exact defaulting behavior for blank/absent optional params, provided it is explicit and documented.
- Exact projection helper names for Phoenix forms/JSON, provided they remain adapters over the same core error contract.

</decisions>

<specifics>
## Specific Ideas

- The public browser grammar should feel like ordinary Phoenix/Plug params, not like a search DSL the user has to learn before a simple form works.
- The shipped story should be: params normalize once, contexts still search, Phoenix stays optional, and helpers only reduce repetitive glue.
- Great DX here means a controller or LiveView can render all invalid fields in one pass, with path-aware errors and no ad hoc branching by transport.
- When convenience conflicts with Scrypath's operational honesty or boundary clarity, prefer the more explicit shape.
- Carry this preference forward in GSD planning for this phase: default to coherent recommendations unless the decision is unusually high impact.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and milestone guardrails
- `.planning/ROADMAP.md` — Phase 81 scope and success criteria for edge normalization, structured errors, Phoenix helpers, and LiveView flows
- `.planning/PROJECT.md` — v1.21 guardrails, non-goals, and the public toolkit / optional Phoenix wrapper product posture
- `.planning/STATE.md` — current milestone state, archive-drift warning, and the narrow-balanced posture for v1.21
- `.planning/REQUIREMENTS.md` — `QTK-02`, `QTK-03`, `PHX-01`, and `PHX-02`

### Phase 80 baseline
- `.planning/phases/80-public-query-toolkit-contract/80-RESEARCH.md` — current public query toolkit contract baseline and anti-goals
- `.planning/phases/80-public-query-toolkit-contract/80-PATTERNS.md` — live pattern map for `Scrypath.QueryParams` and Phoenix guidance
- `.planning/phases/80-public-query-toolkit-contract/80-VERIFICATION.md` — explicitly deferred nested browser-param normalization work now assigned to Phase 81

### Existing runtime and docs seams
- `lib/scrypath/query_params.ex` — current public plain-data toolkit facade
- `lib/scrypath/query_params/caster.ex` — current top-level cast behavior and raise-on-invalid nested-shape seam that Phase 81 replaces
- `lib/scrypath/options.ex` — existing runtime search-option grammar that normalized output must continue feeding
- `lib/scrypath/search.ex` — existing common runtime path and current raise-vs-error patterns
- `lib/scrypath.ex` — public runtime entrypoint docs and current `Scrypath.QueryParams` positioning
- `test/scrypath/query_params_test.exs` — current contract coverage and explicit nested-request-shape deferral
- `test/support/docs/phoenix_example_case.ex` — live examples of the Phoenix glue this phase is intended to replace

### Phoenix boundary guidance
- `guides/phoenix-contexts.md` — contexts remain the application boundary
- `guides/phoenix-liveview.md` — current LiveView boundary guidance
- `guides/phoenix-controllers-and-json.md` — controller translation boundary
- `guides/faceted-search-with-phoenix-liveview.md` — current URL/`handle_params/3`-driven faceted-search guidance

### Prompt corpus constraints
- `prompts/elixir-best-practices-deep-research.md` — Elixir library API and error-surface best practices
- `prompts/ecto-best-practices-deep-research.md` — Ecto-aligned contract and validation guidance
- `prompts/phoenix-best-practices-deep-research.md` — Phoenix boundary and request-edge integration guidance
- `prompts/phoenix-live-view-best-practices-deep-research.md` — LiveView URL-state and form behavior guidance
- `prompts/elixir-plug-ecto-phoenix-system-design-best-practices-deep-research.md` — system-level design tradeoffs across Plug/Ecto/Phoenix
- `prompts/elixir-search-lib-deep-research.md` — search-library-specific product and API tradeoffs
- `prompts/elixir-opensource-libs-best-practices-deep-research.md` — OSS surface-area and compatibility guidance
- `prompts/search-lib-use-cases-deep-research.md` — adopter use cases and ergonomics pressure
- `prompts/scrypath-brand-book.md` — product voice and category posture

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/scrypath/query_params.ex`: current public facade and stable plain-data return shape that Phase 81 should preserve
- `lib/scrypath/query_params/caster.ex`: existing cast seam where nested browser-param normalization can land without creating a second runtime
- `lib/scrypath/options.ex`: canonical search-option grammar and schema-specific validation boundary
- `test/support/docs/phoenix_example_case.ex`: current fixture-level examples for controller, API controller, and LiveView request-edge glue
- `guides/faceted-search-with-phoenix-liveview.md`: current documented URL/LiveView flow to align with rather than replace

### Established Patterns
- Public Scrypath API surfaces are small, explicit, and function-based rather than macro-heavy or facade-heavy
- `Scrypath.search/3` remains the canonical execution path; helpers should prepare data for it, not compete with it
- Contexts own orchestration in guides and examples; web-layer code translates params and renders results
- Phase 80 deliberately kept `Scrypath.QueryParams` data-only and framework-light; Phase 81 should deepen that seam, not fork it

### Integration Points
- Core normalization should continue feeding `Scrypath.QueryParams.to_search_args/1` and then the existing `Scrypath.search/3` path
- Phoenix adapters should sit above the core normalizer and below host-app contexts
- LiveView support should connect at param/form/url boundaries, not at search execution or socket lifecycle ownership

</code_context>

<deferred>
## Deferred Ideas

- Rich predicate/operator DSLs at the public edge
- Public controller wrappers or macros such as `use Scrypath.Phoenix`
- Reusable rendered search components or widget layers
- Event-only LiveView abstractions that treat socket assigns as the canonical search state
- Public browser-friendly expansion of advanced `per_query` tuning

</deferred>

---

*Phase: 81-edge-normalization-errors-and-phoenix-wrappers*
*Context gathered: 2026-05-22*
