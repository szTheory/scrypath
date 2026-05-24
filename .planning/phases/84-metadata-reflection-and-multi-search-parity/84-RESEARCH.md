# Phase 84: Metadata Reflection And Multi-Search Parity - Research

**Researched:** 2026-05-23
**Domain:** Public metadata reflection over schema declarations and validator truth, plus plain-data `search_many/2` composition lowering that preserves existing runtime semantics.
**Confidence:** HIGH. Based on locked phase context, the checked-out `Scrypath`/`Options`/`Composition`/`Search` seams, existing `search_many/2` tests, and the project prompt corpus constraints.

<user_constraints>
## User Constraints

### Locked decisions from Phase 84 context
- Keep a two-layer reflection model:
  - schema capability metadata is the canonical source of truth
  - call-specific resolved metadata is a derived overlay
- Keep both surfaces plain-data and function-based.
- Keep metadata medium-density and framework-agnostic.
- Keep `defaulted` and `fixed` distinct everywhere.
- Surface `unsupported` only when reflecting attempted or composed caller input against a schema.
- Preserve the existing `search_many/2` executor and tuple/shared-option contract.
- Support shared and per-entry composition asymmetrically:
  - per-entry composition is canonical
  - shared composition may lower `defaults` only
- Do not support shared `fixed` composition for `search_many/2`.
- Keep `:all` honest and entry-scoped.
- Keep multi-search reflection entry-scoped by default; do not publish a merged cross-schema capability surface.
- Keep tenant policy, authorization, and related-data propagation explicitly host-owned.

### Boundary guardrails carried forward
- `Scrypath.search/3` and `Scrypath.search_many/2` remain the only runtime entrypoints.
- `%Scrypath.Query{}` remains internal normalized runtime state.
- Phoenix stays optional and host-owned; this phase must not generate widgets or controller/LiveView runtime helpers.
- Public API work should stay Ecto-first, explicit, and low-magic.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| META-01 | Apps can reflect declared filters, sorts, facets, and paging capabilities as framework-agnostic metadata derived from the same canonical declarations and validators that drive runtime behavior. | Derive capability metadata from `__scrypath__/1` declaration storage plus the same field/shape validation seams already used by `Scrypath.Options.validate_search_options/2`; do not hand-maintain a second capability registry. |
| META-02 | Metadata exposes applied defaults and capability constraints clearly enough for Phoenix, LiveView, JSON, or other host UIs to render honest controls without Scrypath generating UI components. | Use one explicit envelope with `capabilities`, `resolved`, and `host_owned` sections, and keep `resolved` vocabulary aligned with Phase 83 visibility keys: `applied`, `defaulted`, `fixed`, `unsupported`. |
| META-03 | Metadata and composition contracts keep tenant policy, authorization, and related-data propagation explicitly host-owned rather than implying those concerns are solved by presets or scopes. | Carry boundary language into docs and docs-contract tests; surface host-owned concerns as advisory metadata, not missing-engine TODOs. |
| MSCH-01 | The public composition model can assemble `search_many/2` flows using the existing tuple/shared-option contract rather than introducing a separate multi-search DSL. | Add lowering helpers that resolve to existing `{schema, text, keyword}` entries plus shared keyword opts; do not widen `Scrypath.Search.search_many/2`. |
| MSCH-02 | `search_many/2` composition preserves current per-entry behavior and failure-boundary honesty, including explicit limits around cross-schema ranking, metadata, and shared-vs-entry precedence. | Reuse `Scrypath.MultiSearch.Entries.normalize/2`, `AllExpansion`, and current `search_many/2` error vocabulary as the semantic floor; reflection and composition should report differences rather than flatten them away. |
</phase_requirements>

## Summary

Phase 84 should add one honest metadata surface and one honest multi-search lowering surface, not a new runtime. The checked-out code already has the right foundations: schema declarations live on `Scrypath.Schema.__scrypath__/1`, runtime validation truth lives in `Scrypath.Options.validate_search_options/2`, single-search composition already resolves to plain `{text, keyword_opts}`, and multi-search already has explicit entry/shared precedence rules in `Scrypath.MultiSearch.Entries.normalize/2`. The safest plan is therefore:

1. Freeze a public metadata contract derived from declarations and validator truth.
2. Freeze a public `search_many/2` composition-lowering contract that resolves to the existing tuple/shared-option shape.
3. Prove parity and honesty with focused tests and a dedicated `mix verify.phase84`.

The capability surface should be declaration-first, not execution-first. `Scrypath.schema_fields/1`, `schema_settings/1`, and `schema_faceting/1` already expose some reflection, but they are fragmented and too raw for honest UI rendering. Phase 84 should consolidate the search-facing subset into a stable capability payload under `Scrypath` while keeping the derivation rooted in current declaration storage and validation rules rather than in hand-authored docs or Phoenix-only helpers.

The resolved surface should be call-specific and field-scoped. Phase 83 already established `applied`, `defaulted`, `fixed`, and optional warnings/sources on the single-search composition seam. Phase 84 should reuse that vocabulary so hosts can render the same semantics whether the input came from explicit caller criteria, Phase 83 composition, or `search_many/2` lowering. This argues for a small reflection helper that accepts plain criteria or composition output and returns one stable resolved envelope rather than asking UIs to reverse-engineer state from scattered fields.

Multi-search composition should follow the same pattern as `QueryParams.to_search_args/1` and `Composition.to_search_args/1`: resolve once, then lower into the existing executor input shape. The checked-out `Entries.normalize/2` implementation already preserves right-biased top-level precedence, shallow-merges `:per_query`, rejects shared-only federation keys in entry opts, and keeps page-size/cardinality rails explicit. Phase 84 should compose into that contract rather than trying to invent a second multi-search object model.

**Primary recommendation:** plan Phase 84 in three slices:
- freeze the public metadata + multi-search lowering contract and boundary docs;
- add the focused verification lane for metadata derivation, `search_many/2` lowering parity, and public-language honesty;
- implement the metadata derivation and lowering helpers, then make the focused verify gate green.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Schema capability metadata | `Scrypath` public reflection layer | `Scrypath.Schema` / `Scrypath.Options` | Public callers need one honest capability contract, but the underlying truth should still come from declarations and validators. |
| Resolved single-search metadata | `Scrypath` public reflection layer | `Scrypath.Composition` | Resolved state is a caller-facing overlay derived from composed or explicit criteria, not a second schema registry. |
| Multi-search lowering | `Scrypath.Composition` | `Scrypath.MultiSearch.Entries` | Public composition should lower into existing entry/shared contracts, then let the current executor semantics remain authoritative. |
| Multi-search reflection | `Scrypath` public reflection layer | `Scrypath.Composition` / `Scrypath.MultiSearchResult` | Reflection should report per-entry capability/resolution differences without changing execution. |
| Honest UI rendering | Host app | `Scrypath` metadata | Scrypath exposes data; Phoenix, LiveView, JSON, or other hosts own widget/render decisions. |
| Tenant policy / authz / related-data | Host app | — | Explicitly out of scope and must remain labeled host-owned. |

## Standard Stack

### Core

| Module / Surface | Purpose | Why Standard |
|------------------|---------|--------------|
| `lib/scrypath.ex` | Root public reflection entrypoints and boundary docs | Existing home for small public reflection helpers and runtime wayfinding. |
| `lib/scrypath/schema.ex` | Declaration storage | Canonical source for `fields`, `filterable`, `sortable`, `faceting`, `settings`, `document_id`, and related metadata. |
| `lib/scrypath/options.ex` | Capability and validation truth | Already validates filter/sort/facet/page/per-query semantics and therefore should anchor reflection honesty. |
| `lib/scrypath/composition.ex` | Existing plain-data composition seam | Already owns Phase 83 visibility vocabulary and single-search lowering. |
| `lib/scrypath/multi_search/entries.ex` | Existing shared-vs-entry precedence contract | Already encodes the exact merge semantics Phase 84 must preserve. |
| `lib/scrypath/search.ex` | Canonical executor behavior and failure boundaries | Phase 84 must lower to this, not bypass it. |

### Supporting

| Module / Surface | Purpose | When to Use |
|------------------|---------|-------------|
| `lib/scrypath/multi_search_result.ex` | Entry-scoped multi-search result metadata shape | Use as the analog for entry-scoped public result helpers and per-entry honesty. |
| `test/scrypath/search_many_test.exs` | Hermetic `search_many/2` behavior proof | Reuse for precedence, `:all`, federation, and failure-boundary expectations. |
| `test/scrypath/multi_search/entries_test.exs` | Focused entry normalization proof | Reuse for shared-vs-entry and rail semantics. |
| `test/scrypath/search_many_integration_test.exs` | Live parity proof | Use for at least one single-search vs singleton-`search_many/2` parity assertion. |
| `test/scrypath/docs_contract_test.exs` | Public-language and guide drift protection | Extend for new metadata/lowering boundary language. |
| `guides/multi-index-search.md` | Canonical `search_many/2` story | Update with composition-lowering and reflection honesty, not generated UI claims. |
| `guides/faceted-search-with-phoenix-liveview.md` | Honest host-rendered facet UI story | Update or cross-link for metadata-driven UI examples without generated widgets. |

## Architecture Patterns

### Pattern 1: Derive capability metadata from declaration storage plus validator truth

Phase 84 should not synthesize capabilities from docs prose or hard-coded lists. `Scrypath.Schema` already stores:
- `:filterable`
- `:sortable`
- `:faceting`
- `:settings`

`Scrypath.Options.validate_search_options/2` already defines runtime-valid shapes and field constraints for:
- `filter`
- `sort`
- `page`
- `facets`
- `facet_filter`
- `per_query`

The public capability payload should therefore be built from these same seams so drift is mechanically harder.

### Pattern 2: Keep capability and resolved metadata separate in one envelope

Recommended public shape:

```elixir
%{
  capabilities: %{
    filters: ...,
    sorts: ...,
    facets: ...,
    paging: ...,
    limits: ...
  },
  resolved: %{
    applied: ...,
    defaulted: ...,
    fixed: ...,
    unsupported: ...
  },
  host_owned: %{
    tenant_policy: :host_owned,
    authorization: :host_owned,
    related_data: :host_owned
  }
}
```

This keeps declaration truth and call-specific state distinct while giving hosts one stable contract to render from.

### Pattern 3: Lower multi-search composition into existing executor args

Phase 83 already established the single-search pattern:
- compose plain data
- convert to canonical runtime args
- let contexts call the executor

Phase 84 should mirror that for multi-search:
- compose per-entry and optional shared defaults
- lower to existing `[{schema, text, keyword}]` plus shared keyword opts
- let callers pass those into `Scrypath.search_many/2`

No new multi-search executor or DSL is needed.

### Pattern 4: Preserve entry-scoped honesty

Current `search_many/2` semantics already preserve:
- per-entry search text
- per-entry option validation
- explicit shared-vs-entry precedence
- explicit federation and `:all` rails
- partial-failure honesty

Reflection and composition must keep those boundaries visible. If two schemas differ on supported facets or sorts, the public reflection should show that per entry rather than collapsing everything into one blended capability object.

### Pattern 5: Reuse focused phase verify tasks and bounded docs contracts

Phase 83 added a pattern this phase should keep:
- focused test files for the new public surface
- a dedicated `Mix.Tasks.Verify.Phase84`
- bounded docs-contract assertions against public promises
- `mix docs --warnings-as-errors`

This is a better fit than broad suite snapshots or live-service-heavy verification.

## Recommended Project Structure

```text
lib/
├── scrypath.ex
├── scrypath/
│   ├── metadata.ex
│   ├── metadata/
│   │   ├── capabilities.ex
│   │   └── resolve.ex
│   ├── composition.ex
│   ├── composition/
│   │   └── multi.ex
│   ├── multi_search/entries.ex
│   ├── options.ex
│   └── search.ex
test/
├── scrypath/
│   ├── metadata_test.exs
│   ├── composition_many_test.exs
│   ├── docs_contract_test.exs
│   └── search_many_test.exs
lib/mix/tasks/
└── verify.phase84.ex
```

`metadata.ex` as the public entrypoint plus small focused internal helpers matches current project structure better than a large all-in-one module.

## Recommended Plan Slices

### Slice 1: Freeze the public metadata and multi-search lowering contract

Target outcomes:
- add one public metadata surface under `Scrypath`
- add one public `search_many/2` lowering surface under `Scrypath.Composition`
- wire root/docs boundary language to the new surfaces without implying a new runtime or generated UI

Likely files:
- `lib/scrypath.ex`
- `lib/scrypath/metadata.ex`
- `lib/scrypath/composition.ex`
- `guides/multi-index-search.md`
- `guides/faceted-search-with-phoenix-liveview.md`

### Slice 2: Add the focused verification harness

Target outcomes:
- metadata derivation tests
- multi-search lowering parity tests
- docs-contract assertions for public honesty
- dedicated `mix verify.phase84`

Likely files:
- `test/scrypath/metadata_test.exs`
- `test/scrypath/composition_many_test.exs`
- `test/scrypath/docs_contract_test.exs`
- `lib/mix/tasks/verify.phase84.ex`
- `mix.exs`

### Slice 3: Implement derivation, lowering, and phase verify

Target outcomes:
- capability metadata derived from declarations and validators
- resolved metadata over explicit or composed criteria
- multi-search lowering that preserves current shared-vs-entry semantics
- passing `mix verify.phase84`

Likely files:
- `lib/scrypath/metadata.ex`
- `lib/scrypath/metadata/capabilities.ex`
- `lib/scrypath/metadata/resolve.ex`
- `lib/scrypath/composition.ex`
- `lib/scrypath/composition/multi.ex`
- `test/scrypath/metadata_test.exs`
- `test/scrypath/composition_many_test.exs`

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Capability metadata | A second hand-maintained registry of supported fields | `__scrypath__/1` + validator-derived truth | Prevents capability drift. |
| Multi-search composition | A new `%Scrypath.MultiQuery{}` or DSL | Plain-data lowering to existing tuples/shared opts | Preserves runtime boundary and semantics. |
| Honest UI rendering | Generated widgets/components | Plain metadata + host-owned rendering | Matches project posture and phase non-goals. |
| Cross-schema capability view | One merged global capability bag | Per-entry capability/reflection payloads | Keeps cross-schema differences explicit. |

## Common Pitfalls

### Pitfall 1: Duplicating capability truth

If Phase 84 defines capability metadata with its own field allowlists instead of deriving from declarations and validator seams, it will drift almost immediately from runtime behavior.

### Pitfall 2: Blurring `defaulted` and `fixed`

Phase 83 already established that defaults are overridable and fixed constraints are policy. Any metadata or docs shape that makes them look the same will mislead host UIs and tests.

### Pitfall 3: Inventing shared `fixed` semantics for multi-search

`Entries.normalize/2` currently has clear right-biased shared-vs-entry behavior. Adding shared `fixed` composition above that would silently introduce a new semantic layer and violate locked context.

### Pitfall 4: Publishing a merged cross-schema capability surface

If reflection collapses different schema capabilities into one fake global search form, hosts will over-render unsupported controls and lose the current honesty of `search_many/2`.

### Pitfall 5: Treating metadata as authorization or tenant policy

Metadata should say what the search seam supports, not what a tenant or user may access. That boundary must remain explicit in docs and advisory fields.

## Validation Architecture

### Test Framework

- `ExUnit` for focused unit and parity tests
- `mix docs --warnings-as-errors` for public docs drift
- existing `FakeBackend` and current `search_many` hermetic tests for runtime-adjacent proof
- existing singleton multi-search integration test for one live parity seam

### Phase Requirements -> Test Map

| Requirement | Validation Strategy |
|-------------|---------------------|
| META-01 | Add capability metadata tests that assert reflected filters/sorts/facets/paging match declaration storage and the current validator surface. |
| META-02 | Add resolved-metadata tests that assert `applied`, `defaulted`, `fixed`, and `unsupported` stay field-scoped and align with Phase 83 composition output. |
| META-03 | Add docs-contract assertions that public docs and root moduledocs label tenant policy, authorization, and related-data as host-owned. |
| MSCH-01 | Add multi-search lowering tests that prove composed entries/shared defaults resolve to the existing tuple/shared-option contract. |
| MSCH-02 | Add parity tests around shared-vs-entry precedence, `:all` honesty, unsupported entry-scoped capabilities, and current error/failure boundaries. |

### Wave 0 Gaps

- No Phase 84 research artifact existed before this run.
- No Phase 84 validation ledger existed before this run.
- No dedicated metadata or multi-search composition verify task exists yet.
- The current public docs describe `search_many/2` behavior and Phase 83 composition separately; they do not yet connect the two under one bounded public seam.

## Security Domain

### Applicable concerns

- UI-facing metadata overstating what the runtime actually supports
- accidental drift into authz/tenant policy claims
- silent multi-search semantic widening via shared `fixed` or merged capability surfaces

### Mitigation direction

- derive capability truth from current declaration + validation seams
- keep reflection advisory and data-only
- keep multi-search composition as lowering only
- pin public language with docs-contract assertions

## Open Questions (resolved for planning)

1. **Should Phase 84 add a public metadata module or keep adding helpers directly on `Scrypath`?**
   - Recommendation: add a small `Scrypath.Metadata` implementation module but expose convenience entrypoints from `Scrypath` for the public seam. This matches current style: small public helpers rooted at `Scrypath`, deeper logic below.

2. **Should resolved metadata accept explicit caller criteria, Phase 83 composition output, or both?**
   - Recommendation: both. Hosts should not have to recompute resolved state depending on whether they used presets/scopes or direct plain-data input.

3. **Should multi-search composition return a new public struct?**
   - Recommendation: no. Keep it plain data plus lowering helpers, exactly as Phase 83 did for single-search.

## Sources

### Primary

- `.planning/ROADMAP.md`
- `.planning/REQUIREMENTS.md`
- `.planning/PROJECT.md`
- `.planning/STATE.md`
- `.planning/phases/84-metadata-reflection-and-multi-search-parity/84-CONTEXT.md`
- `.planning/phases/84-metadata-reflection-and-multi-search-parity/84-UI-SPEC.md`
- `.planning/phases/83-composition-presets-and-scope-contract/83-CONTEXT.md`
- `.planning/phases/83-composition-presets-and-scope-contract/83-RESEARCH.md`
- `lib/scrypath.ex`
- `lib/scrypath/schema.ex`
- `lib/scrypath/options.ex`
- `lib/scrypath/composition.ex`
- `lib/scrypath/search.ex`
- `lib/scrypath/multi_search/entries.ex`
- `lib/scrypath/multi_search_result.ex`
- `lib/scrypath/query_params.ex`
- `guides/multi-index-search.md`
- `guides/request-edge-search.md`
- `guides/faceted-search-with-phoenix-liveview.md`
- `guides/per-query-tuning-pipeline.md`
- `test/scrypath/multi_search/entries_test.exs`
- `test/scrypath/search_many_test.exs`
- `test/scrypath/search_many_integration_test.exs`
- `test/scrypath/composition_test.exs`
- `test/scrypath/composition_property_test.exs`
- `test/scrypath/docs_contract_test.exs`

## RESEARCH COMPLETE
