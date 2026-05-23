# Phase 83: Composition Presets And Scope Contract - Research

**Researched:** 2026-05-23
**Domain:** Elixir plain-data composition over existing `Scrypath.search/3` search args [VERIFIED: codebase grep]
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
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

### Deferred Ideas (OUT OF SCOPE)
- Persisted or externally exchanged preset/scope definitions
- Schema macros or behaviour-heavy composition frameworks
- Phoenix-owned composition helpers, controller macros, or LiveView runtime facades
- Generated runtime search verbs derived from presets/scopes
- Tenant authorization, access control, and related-data propagation as part of the composition contract
- Saved-search persistence, UI widgets, or broader framework-owned search UX layers
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| CMP-01 | Apps can define named presets as plain-data composition fragments that expand into the existing `Scrypath.search/3` input shape without exposing `%Scrypath.Query{}` or creating a second public query runtime. | Use a data-only fragment envelope plus a resolver that returns canonical `{text, keyword_opts}`-compatible data and never calls `Scrypath.Search` directly. [VERIFIED: codebase grep] |
| CMP-02 | Apps can apply additive scopes with deterministic precedence rules that distinguish caller-overridable defaults from fixed constraints. | Implement a staged merge pipeline with explicit key ownership and conflict errors for `fixed` collisions on `filter` and `facet_filter`. [CITED: https://hexdocs.pm/elixir/1.18.0/Keyword.html] [CITED: https://hexdocs.pm/elixir/1.18/Map.html] |
| CMP-03 | Composition results expose debug-friendly applied/defaulted search criteria so host apps and tests can see what actually reached the canonical runtime. | Return final criteria plus coarse metadata buckets (`applied`, `defaulted`, `fixed`, optional `sources`/`warnings`) in the same public vocabulary. [VERIFIED: .planning/phases/83-composition-presets-and-scope-contract/83-CONTEXT.md] |
| CMP-04 | Composition definitions stay feature-level and context-owned rather than moving product UX declarations onto Ecto schemas or Phoenix helpers. | Keep the seam in a small library module and keep host presets/scopes as plain functions or module attributes in app contexts/features, not schemas or `Scrypath.Phoenix`. [VERIFIED: codebase grep] |
</phase_requirements>

## Summary

Phase 83 should add one new public composition seam, not a new runtime. `Scrypath.search/3` is already the canonical single-search execution path, `Scrypath.QueryParams` already converts request-edge input into one stable plain-data shape, and `%Scrypath.Query{}` is explicitly internal, so the safest implementation is a resolver that accepts host-owned fragments and returns the same plain data that `QueryParams.to_search_args/1` and `Scrypath.search/3` already expect. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/elixir/keywords-and-maps.html]

The merge discipline matters more than new abstractions. Elixir keyword lists preserve order and allow duplicate keys, while maps replace duplicates with the latest value, so Phase 83 should normalize composition inputs before merging and then apply field-specific rules instead of relying on generic `Keyword.merge/2` everywhere. This is especially important for `filter` and `facet_filter`, where the user explicitly wants key-based caller-default merging plus conflict-checked fixed constraints. [CITED: https://hexdocs.pm/elixir/keywords-and-maps.html] [CITED: https://hexdocs.pm/elixir/1.18.0/Keyword.html] [CITED: https://hexdocs.pm/elixir/1.18/Map.html]

The project already has the right implementation posture for this phase: narrow public APIs, NimbleOptions-backed option validation, focused verify tasks per phase, fake-backend hermetic tests, and docs-contract protection for public language. The planning work should therefore bias toward a small core module, property-heavy merge tests, and a dedicated `mix verify.phase83` rather than any new runtime dependency or framework-specific layer. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/nimble_options/index.html] [CITED: https://hexdocs.pm/stream_data/ExUnitProperties.html]

**Primary recommendation:** Add a small `Scrypath.Composition`-style resolver that normalizes host fragments into canonical plain data, merges them with field-specific precedence, returns visibility metadata, and hands the final `{text, opts}` to existing `Scrypath.search/3` callers. [VERIFIED: codebase grep]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Preset definition | Host context / feature module | — | The context file locks composition ownership at feature/context level instead of schemas or Phoenix helpers. [VERIFIED: .planning/phases/83-composition-presets-and-scope-contract/83-CONTEXT.md] |
| Fragment normalization | API / Backend library layer | — | The library owns the public plain-data contract and should validate/normalize fragments before search execution. [VERIFIED: codebase grep] |
| Deterministic merge and conflict detection | API / Backend library layer | — | Precedence and fixed-constraint behavior are core public semantics and must be implemented once centrally. [VERIFIED: .planning/phases/83-composition-presets-and-scope-contract/83-CONTEXT.md] |
| Search execution | API / Backend library layer | — | `Scrypath.search/3` remains the canonical runtime entrypoint. [VERIFIED: codebase grep] |
| Request param parsing | Browser / Phoenix edge | API / Backend library layer | `Scrypath.QueryParams` and optional `Scrypath.Phoenix` stop at plain data and must not absorb composition ownership. [VERIFIED: codebase grep] |
| Logs/tests visibility of final criteria | API / Backend library layer | Host app | The library should expose coarse metadata; host apps decide how to log/assert it. [VERIFIED: .planning/phases/83-composition-presets-and-scope-contract/83-CONTEXT.md] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir | 1.19.5 local; project floor `~> 1.17` | Core data and merge primitives | The repo already targets `~> 1.17`, and the local toolchain is Elixir 1.19.5 on OTP 28. [VERIFIED: mix.exs] [VERIFIED: `elixir --version`] |
| Ecto | 3.13.6 locked; 3.14.0 latest published 2026-05-19 | Existing integration surface and library positioning | Scrypath is explicitly Ecto-first, and no phase decision widens that surface. [VERIFIED: mix.exs] [VERIFIED: `mix hex.info ecto`] |
| NimbleOptions | 1.1.1 latest published 2024-05-25 | Public option schema validation and docs generation | The project already routes public option validation through NimbleOptions, whose docs cover validation and generated option docs. [VERIFIED: mix.exs] [VERIFIED: `mix hex.info nimble_options`] [CITED: https://hexdocs.pm/nimble_options/index.html] |
| Telemetry | 1.4.1 locked; 1.4.2 latest published 2026-05-11 | Stable observability metadata | Search surfaces already publish stable telemetry events, so composition visibility should complement rather than replace that story. [VERIFIED: `mix deps.tree`] [VERIFIED: `mix hex.info telemetry`] [VERIFIED: codebase grep] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Elixir `Keyword` / `Map` stdlib | Elixir 1.19.x docs verified | Deterministic top-level merge rules | Use directly for whole-value override and shallow map merge after normalizing duplicates. [CITED: https://hexdocs.pm/elixir/keywords-and-maps.html] [CITED: https://hexdocs.pm/elixir/1.18.0/Keyword.html] [CITED: https://hexdocs.pm/elixir/1.18/Map.html] |
| StreamData | 1.3.0 latest published 2026-03-09 | Property tests for merge stability and idempotence | Add as `:test`-only if you want stronger parity proof for precedence invariants. [VERIFIED: `mix hex.info stream_data`] [CITED: https://hexdocs.pm/stream_data/ExUnitProperties.html] |
| Existing fake backends | In-repo test support | Hermetic runtime parity checks | Reuse `Scrypath.TestSupport.FakeBackend` and existing search tests to prove the resolver feeds the unchanged runtime contract. [VERIFIED: codebase grep] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| New runtime dependency for composition | Elixir stdlib plus current project deps | No new runtime dependency is needed for Phase 83; the merge logic is small enough to keep in-core. [VERIFIED: codebase grep] |
| Plain-data seam | Macro DSL / behaviour-first extension layer | This would add ceremony and public API pressure that the locked decisions explicitly reject. [VERIFIED: .planning/phases/83-composition-presets-and-scope-contract/83-CONTEXT.md] |
| Coarse visibility metadata | Full merge trace / explain engine | A detailed trace widens the product promise and leaks internal merge machinery too early. [VERIFIED: .planning/phases/83-composition-presets-and-scope-contract/83-CONTEXT.md] |

**Installation:** No new runtime dependency is required for the recommended path. [VERIFIED: codebase grep]

```elixir
# Optional test-only strengthening if property tests are added
{:stream_data, "~> 1.3", only: :test}
```

**Version verification:** `ecto` latest published `3.14.0` on 2026-05-19, `nimble_options` latest published `1.1.1` on 2024-05-25, `telemetry` latest published `1.4.2` on 2026-05-11, and `stream_data` latest published `1.3.0` on 2026-03-09. [VERIFIED: `mix hex.info ecto`] [VERIFIED: `mix hex.info nimble_options`] [VERIFIED: `mix hex.info telemetry`] [VERIFIED: `mix hex.info stream_data`]

## Architecture Patterns

### System Architecture Diagram

```text
Host feature/context preset or scope
        |
        v
Plain fragment envelope
%{
  defaults: %{text?, filter?, sort?, page?, facets?, facet_filter?, per_query?},
  fixed: %{filter?, facet_filter?},
  meta?: %{source?, warning?}
}
        |
        v
Composition resolver
  1. normalize shapes
  2. canonicalize duplicate keys
  3. merge defaults with caller input
  4. apply fixed constraints with conflict checks
  5. build visibility metadata
        |
        +--> explicit `{:error, {:composition_conflict, field, key, details}}`
        |
        v
Canonical output
%{
  text: binary(),
  filter: keyword(),
  sort: keyword(),
  page: keyword(),
  facets: [atom()],
  facet_filter: keyword(),
  per_query: map(),
  applied: ...,
  defaulted: ...,
  fixed: ...
}
        |
        v
Host context calls `Scrypath.search/3`
        |
        v
Existing `Scrypath.Search` runtime and backend
```

The diagram keeps one runtime path and adds one resolver step ahead of it. [VERIFIED: codebase grep]

### Recommended Project Structure

```text
lib/
├── scrypath/
│   ├── composition.ex          # public composition seam
│   ├── composition/
│   │   ├── merge.ex            # field-specific precedence rules
│   │   ├── normalize.ex        # canonicalization of fragment input
│   │   └── result.ex           # visibility wrapper / typed helpers
│   ├── query_params.ex         # existing plain-data search-args contract
│   ├── search.ex               # existing canonical runtime
│   └── options.ex              # existing option vocabulary
test/
├── scrypath/
│   ├── composition_test.exs
│   ├── composition_property_test.exs
│   └── docs_contract_test.exs
└── support/
    └── fake_backend.ex
```

This split mirrors existing project practice: small public modules, internal helpers under the same namespace, and focused tests plus docs-contract coverage. [VERIFIED: codebase grep]

### Pattern 1: Resolve To Existing Search Args

**What:** Normalize every fragment and caller input into the same public vocabulary already used by `QueryParams` and `search/3`. [VERIFIED: codebase grep]

**When to use:** Always; this is the main guard against accidentally creating a second query system. [VERIFIED: .planning/REQUIREMENTS.md]

**Example:**

```elixir
# Source: lib/scrypath/query_params.ex [VERIFIED: codebase grep]
@spec to_search_args(t()) :: {String.t(), keyword()}
def to_search_args(%{} = query_params) do
  text = Map.get(query_params, :text, "")

  opts =
    Enum.map(@search_option_keys, fn key ->
      {key, Map.get(query_params, key, default_value(key))}
    end)

  {text, opts}
end
```

### Pattern 2: Use Field-Specific Merge Rules

**What:** Use whole-value override for `sort`, `page`, and `facets`; use key-aware merge plus fixed-conflict detection for `filter` and `facet_filter`; use shallow `Map.merge/2` for `per_query`. [VERIFIED: .planning/phases/83-composition-presets-and-scope-contract/83-CONTEXT.md] [CITED: https://hexdocs.pm/elixir/1.18.0/Keyword.html] [CITED: https://hexdocs.pm/elixir/1.18/Map.html]

**When to use:** Any time two scopes or caller input touch the same top-level field. [VERIFIED: .planning/phases/83-composition-presets-and-scope-contract/83-CONTEXT.md]

**Example:**

```elixir
# Source: lib/scrypath/multi_search/entries.ex [VERIFIED: codebase grep]
merged <- Keyword.merge(shared, entry_core, fn _k, _s, e -> e end)

Keyword.put(
  merged,
  :per_query,
  Map.merge(per_query_as_map(s), per_query_as_map(e))
)
```

### Pattern 3: Canonicalize Duplicate Keyword Keys Before Policy Logic

**What:** Convert duplicate-bearing keyword inputs into a unique-key form before fixed/default policy checks. [CITED: https://hexdocs.pm/elixir/keywords-and-maps.html] [CITED: https://hexdocs.pm/elixir/1.18.0/Keyword.html]

**When to use:** Before merging `filter` or `facet_filter`, and before building visibility metadata intended for tests/logs. [VERIFIED: codebase grep]

**Example:**

```elixir
# Source: https://hexdocs.pm/elixir/1.18.0/Keyword.html
defaults = Keyword.new(default_filter)
caller = Keyword.new(caller_filter)
merged = Keyword.merge(defaults, caller, fn _key, _default, input -> input end)
```

### Anti-Patterns to Avoid

- **Generic deep merge for all fields:** `page`, `sort`, and `facets` are locked to whole-value override, so a generic recursive merge would violate phase decisions. [VERIFIED: .planning/phases/83-composition-presets-and-scope-contract/83-CONTEXT.md]
- **Using `%Scrypath.Query{}` as public output:** the struct is documented as internal normalized runtime state, not a host-facing contract. [VERIFIED: codebase grep]
- **Putting composition ownership on schemas or `Scrypath.Phoenix`:** both the roadmap and context file explicitly reject that product shape. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/phases/83-composition-presets-and-scope-contract/83-CONTEXT.md]
- **Silent fixed-constraint override:** fixed conflicts must fail explicitly instead of picking “last wins.” [VERIFIED: .planning/phases/83-composition-presets-and-scope-contract/83-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Second search DSL | A new query builder or public `%Query{}` facade | Existing plain-data `{text, keyword_opts}` contract | The repo already has one canonical runtime path and one public data shape. [VERIFIED: codebase grep] |
| Generic recursive merge engine | Deep algebra for every field | Small field-by-field merge functions | The locked precedence rules differ by field, so a generic merger increases surprise. [VERIFIED: .planning/phases/83-composition-presets-and-scope-contract/83-CONTEXT.md] |
| Framework-owned composition API | Phoenix macros or schema-generated verbs | Context-owned functions returning fragments | The milestone explicitly keeps contexts canonical and Phoenix optional. [VERIFIED: .planning/REQUIREMENTS.md] |
| Ad hoc option validation strings | Custom validation scattered through the new module | Existing NimbleOptions pattern plus explicit tuple errors | The project already centralizes option grammar and error normalization through `Scrypath.Options`. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/nimble_options/index.html] |

**Key insight:** The hard part of this phase is not “how to compose data”; it is “how to keep one public runtime boundary while making precedence honest and inspectable.” [VERIFIED: .planning/REQUIREMENTS.md]

## Common Pitfalls

### Pitfall 1: Duplicate Keyword Keys Break Policy Checks

**What goes wrong:** A raw keyword list can carry repeated keys, so a naive `Keyword.get/2` or `Keyword.merge/2` can hide earlier duplicates and make conflict detection inconsistent. [CITED: https://hexdocs.pm/elixir/keywords-and-maps.html] [CITED: https://hexdocs.pm/elixir/1.18.0/Keyword.html]

**Why it happens:** Keyword lists are ordered optional-argument structures, not unique-key maps. [CITED: https://hexdocs.pm/elixir/keywords-and-maps.html]

**How to avoid:** Canonicalize `filter` and `facet_filter` with `Keyword.new/1` or an equivalent unique-key pass before applying default/fixed semantics. [CITED: https://hexdocs.pm/elixir/1.18.0/Keyword.html]

**Warning signs:** Repeated calls with semantically identical fragments produce different visibility output or different conflict outcomes. [ASSUMED]

### Pitfall 2: Whole-Value Fields Accidentally Deep-Merge

**What goes wrong:** `page`, `sort`, or `facets` end up partially merged across scopes, which violates the locked caller-override rule. [VERIFIED: .planning/phases/83-composition-presets-and-scope-contract/83-CONTEXT.md]

**Why it happens:** Generic merge helpers are convenient, but this phase has asymmetric rules per field. [VERIFIED: .planning/phases/83-composition-presets-and-scope-contract/83-CONTEXT.md]

**How to avoid:** Encode merge behavior per field in one dedicated module and test each field separately. [VERIFIED: codebase grep]

**Warning signs:** A caller sets only `page: [size: 50]` and the resolver silently preserves a preset `number:` from defaults. [ASSUMED]

### Pitfall 3: Visibility Metadata Drifts From Final Output

**What goes wrong:** `applied`, `defaulted`, or `fixed` report different data than the final criteria that will reach `search/3`. [VERIFIED: .planning/REQUIREMENTS.md]

**Why it happens:** Metadata gets built from pre-normalized fragments instead of from the same canonicalized final merge inputs. [ASSUMED]

**How to avoid:** Derive visibility metadata from the same normalized structures used to build final `{text, opts}` output. [VERIFIED: codebase grep]

**Warning signs:** Host tests pass on metadata snapshots but fail when the same criteria are passed to `Scrypath.search/3`. [ASSUMED]

### Pitfall 4: Boundary Drift Toward Schema Or Phoenix Ownership

**What goes wrong:** The library starts shipping helpers that look like runtime search verbs or framework facades rather than composition utilities. [VERIFIED: .planning/PROJECT.md] [VERIFIED: .planning/phases/83-composition-presets-and-scope-contract/83-CONTEXT.md]

**Why it happens:** Composition features often tempt library authors to add a “convenient” runtime wrapper at the same time. [ASSUMED]

**How to avoid:** Keep the public seam as resolver/merge helpers only and keep guides centered on contexts calling `Scrypath.search/3`. [VERIFIED: codebase grep]

**Warning signs:** Public docs need to explain a new runtime entrypoint, schema macro, or Phoenix controller helper to use composition. [VERIFIED: .planning/ROADMAP.md]

## Code Examples

Verified patterns from official or in-repo sources:

### Stable Plain-Data Search Args

```elixir
# Source: lib/scrypath/query_params.ex [VERIFIED: codebase grep]
{text, search_opts} = Scrypath.QueryParams.to_search_args(query_params)
Scrypath.search(Post, text, search_opts)
```

### Entry-Biased Shallow Merge

```elixir
# Source: lib/scrypath/multi_search/entries.ex [VERIFIED: codebase grep]
merged = Keyword.merge(shared, entry_core, fn _key, _shared, entry -> entry end)
```

### Property Test Skeleton For Merge Stability

```elixir
# Source: https://hexdocs.pm/stream_data/ExUnitProperties.html
use ExUnitProperties

property "composition is idempotent for equivalent inputs" do
  check all text <- StreamData.binary() do
    assert compose(input(text)) == compose(input(text))
  end
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Request-edge normalization only | Request-edge normalization plus bounded composition layer | `v1.22` roadmap opened on 2026-05-23 | The public story now moves from “plain params only” to “plain params plus reusable composition,” but must still feed the same runtime. [VERIFIED: .planning/STATE.md] [VERIFIED: .planning/ROADMAP.md] |
| Raw caller-owned merge glue | Library-owned merge contract with host-owned definitions | Phase 83 scope | Host apps should get less repeated glue without losing context ownership. [VERIFIED: .planning/REQUIREMENTS.md] |
| Phase-specific verify gates for request-edge and per-query only | Add a new verify gate for composition contract drift | Recommended for Phase 83 | The project already uses phase-focused verification tasks, so this phase should follow that pattern. [VERIFIED: codebase grep] |

**Deprecated/outdated:**

- Ad hoc app-local merge rules as the only composition story become outdated once Phase 83 ships, because the milestone goal is to freeze the reusable contract. [VERIFIED: .planning/ROADMAP.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Repeated calls with semantically identical duplicate-bearing inputs are a realistic host risk worth testing explicitly. | Common Pitfalls | Low; it only affects test prioritization. |
| A2 | Partial deep-merge mistakes on `page` and metadata derivation drift are the most likely implementation errors. | Common Pitfalls | Low-Medium; a different bug mix would change test emphasis, not architecture. |
| A3 | Boundary drift pressure will primarily show up as “convenience” runtime helpers in docs or API proposals. | Common Pitfalls | Low; the guardrail remains the same even if the exact drift vector differs. |

## Open Questions

1. **Should the public result wrapper be a map or a struct?**
   What we know: the user locked the seam to plain data and wants inspectable output. [VERIFIED: .planning/phases/83-composition-presets-and-scope-contract/83-CONTEXT.md]
   What's unclear: whether a small struct with plain fields would still count as “plain-data enough” for this milestone. [ASSUMED]
   Recommendation: Prefer a plain map for Phase 83 unless planning finds a compelling typed-doc reason to wrap it later. [ASSUMED]

2. **Should Phase 83 ship `compose/2` only or both `compose/2` and `compose!/2`?**
   What we know: Scrypath public APIs commonly offer non-bang and bang variants for expected-vs-raising flows. [VERIFIED: codebase grep]
   What's unclear: whether composition conflicts should be represented only as tuples or also with a raising helper for symmetry. [ASSUMED]
   Recommendation: Plan the tuple API first and treat bang symmetry as optional if it does not widen docs or semver cost. [ASSUMED]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit on Elixir 1.19.5 local runtime. [VERIFIED: `elixir --version`] |
| Config file | [test/test_helper.exs](/Users/jon/projects/scrypath/test/test_helper.exs:1) [VERIFIED: codebase grep] |
| Quick run command | `mix verify.phase83` after Wave 0 adds it; until then use targeted `mix test` files. [ASSUMED] |
| Full suite command | `mix test --exclude integration --exclude docs_contract` per CONTRIBUTING fast suite, plus `mix docs --warnings-as-errors` when public docs change. [VERIFIED: CONTRIBUTING.md] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| CMP-01 | Presets resolve into canonical `{text, opts}` shape with no second runtime | unit + parity | `mix test test/scrypath/composition_test.exs` | ❌ Wave 0 |
| CMP-02 | Defaults vs fixed precedence is deterministic and conflict-safe | property + unit | `mix test test/scrypath/composition_property_test.exs test/scrypath/composition_test.exs` | ❌ Wave 0 |
| CMP-03 | Visibility metadata matches final effective criteria | unit + docs contract | `mix test test/scrypath/composition_test.exs test/scrypath/docs_contract_test.exs` | ❌ / ✅ existing docs contract |
| CMP-04 | Public API/docs keep contexts canonical and Phoenix optional | docs contract | `mix test test/scrypath/docs_contract_test.exs` | ✅ |

### Sampling Rate

- **Per task commit:** `mix verify.phase83` once added. [ASSUMED]
- **Per wave merge:** `mix test --exclude integration --exclude docs_contract` and `mix docs --warnings-as-errors` if docs changed. [VERIFIED: CONTRIBUTING.md]
- **Phase gate:** Full Phase 83 verify task plus docs build green before `/gsd-verify-work`. [ASSUMED]

### Wave 0 Gaps

- [ ] `lib/mix/tasks/verify.phase83.ex` — focused Phase 83 verification task matching the project’s existing pattern. [VERIFIED: codebase grep]
- [ ] `test/scrypath/composition_test.exs` — deterministic merge, conflict, and visibility coverage for CMP-01..CMP-03. [ASSUMED]
- [ ] `test/scrypath/composition_property_test.exs` — idempotence and repeated-call stability coverage, ideally with `StreamData`. [ASSUMED]
- [ ] `test/scrypath/docs_contract_test.exs` updates — protect new public wording and non-goals. [VERIFIED: codebase grep]
- [ ] Optional framework install: `mix deps.get` after adding `:stream_data` if property tests are adopted. [VERIFIED: `mix hex.info stream_data`]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Host app concern; the phase explicitly does not solve auth. [VERIFIED: .planning/phases/83-composition-presets-and-scope-contract/83-CONTEXT.md] |
| V3 Session Management | no | No session behavior is introduced by this library slice. [VERIFIED: .planning/REQUIREMENTS.md] |
| V4 Access Control | no | Tenant/access policy remains host-owned by locked decision. [VERIFIED: .planning/phases/83-composition-presets-and-scope-contract/83-CONTEXT.md] |
| V5 Input Validation | yes | Reuse `Scrypath.Options`/NimbleOptions-style explicit validation and reject conflicting `fixed` constraints. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/nimble_options/index.html] |
| V6 Cryptography | no | No cryptographic behavior is in scope. [VERIFIED: .planning/REQUIREMENTS.md] |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Caller bypasses fixed policy by sending overlapping filter keys | Tampering | Normalize keys and fail explicitly on fixed conflicts instead of silently preferring caller input. [VERIFIED: .planning/phases/83-composition-presets-and-scope-contract/83-CONTEXT.md] |
| Duplicate keyword keys create ambiguous effective policy | Tampering | Canonicalize keyword inputs before merge and expose one stable final shape. [CITED: https://hexdocs.pm/elixir/keywords-and-maps.html] [CITED: https://hexdocs.pm/elixir/1.18.0/Keyword.html] |
| Debug visibility leaks into runtime authority | Elevation of privilege | Keep visibility output read-only and keep execution on `Scrypath.search/3` only. [VERIFIED: codebase grep] |
| Docs imply tenant-safe authz or framework-owned policy | Spoofing | Preserve explicit non-goals in docs-contract tests and public guides. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: codebase grep] |

## Sources

### Primary (HIGH confidence)

- `lib/scrypath.ex`, `lib/scrypath/search.ex`, `lib/scrypath/query_params.ex`, `lib/scrypath/options.ex`, `lib/scrypath/multi_search/entries.ex` - current runtime boundary, merge precedent, and option vocabulary. [VERIFIED: codebase grep]
- `.planning/phases/83-composition-presets-and-scope-contract/83-CONTEXT.md` - locked decisions and discretion areas. [VERIFIED: codebase grep]
- `.planning/REQUIREMENTS.md`, `.planning/STATE.md`, `.planning/ROADMAP.md`, `.planning/PROJECT.md` - milestone scope, requirement mapping, and guardrails. [VERIFIED: codebase grep]
- `https://hexdocs.pm/elixir/keywords-and-maps.html` - keyword vs map semantics and intended usage. [CITED: https://hexdocs.pm/elixir/keywords-and-maps.html]
- `https://hexdocs.pm/elixir/1.18.0/Keyword.html` - `Keyword.merge/3` and `Keyword.new/1` behavior. [CITED: https://hexdocs.pm/elixir/1.18.0/Keyword.html]
- `https://hexdocs.pm/elixir/1.18/Map.html` - `Map.merge/3` behavior. [CITED: https://hexdocs.pm/elixir/1.18/Map.html]
- `https://hexdocs.pm/nimble_options/index.html` - option schema validation and docs generation. [CITED: https://hexdocs.pm/nimble_options/index.html]
- `https://hexdocs.pm/stream_data/ExUnitProperties.html` - property-testing macros and usage. [CITED: https://hexdocs.pm/stream_data/ExUnitProperties.html]
- `mix hex.info ecto`, `mix hex.info nimble_options`, `mix hex.info telemetry`, `mix hex.info stream_data` - current published package versions and release dates. [VERIFIED: package registry]

### Secondary (MEDIUM confidence)

- None.

### Tertiary (LOW confidence)

- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - the phase can stay on existing project/runtime primitives, and package versions were verified from the registry. [VERIFIED: mix.exs] [VERIFIED: package registry]
- Architecture: HIGH - the current repo already enforces one runtime boundary and the context file locks the composition shape tightly. [VERIFIED: codebase grep]
- Pitfalls: MEDIUM - the most important ones are grounded in Elixir data-structure semantics and repo guardrails, but some warning-sign examples are predictive rather than directly observed. [CITED: https://hexdocs.pm/elixir/keywords-and-maps.html]

**Research date:** 2026-05-23
**Valid until:** 2026-06-22
