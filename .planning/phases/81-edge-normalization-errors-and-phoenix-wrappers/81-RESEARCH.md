# Phase 81: Edge normalization errors and Phoenix wrappers - Research

**Researched:** 2026-05-23
**Domain:** Request-edge normalization, structured field errors, and optional Phoenix adapters over `Scrypath.QueryParams`.
**Confidence:** HIGH. Based on checked-out code, current guides, and current docs-fixture tests.

<user_constraints>
## User Constraints

- Keep `Scrypath.search/3` as the canonical runtime and keep contexts as the application boundary.
- Do not expose `%Scrypath.Query{}` as public API.
- Keep Phoenix optional and out of runtime core.
- Normalize request params once at the edge and return structured field-scoped errors instead of forcing controller or LiveView branches.
- Do not widen into widgets, macros, controller facades, schema-generated verbs, or a second runtime.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| QTK-02 | Normalize text, filters, sort, pagination, facets, and facet-filter input once at the edge while preserving explicit defaults and limits. | Extend `Scrypath.QueryParams` beyond Phase 80's top-level envelope cast so browser-shaped nested params become the existing plain-data contract. |
| QTK-03 | Invalid edge input returns structured, field-scoped errors host apps can render directly. | Replace Phase 80 raise-on-nested-shape behavior with aggregate `{:ok, query_params} | {:error, error_map}` semantics and stable issue metadata. |
| PHX-01 | Optional Phoenix helpers support URL and form round-tripping without introducing a hard Phoenix dependency in runtime core. | Put Phoenix-only projection helpers in a separate optional module such as `Scrypath.Phoenix`, not in `Scrypath.QueryParams`. |
| PHX-02 | Optional LiveView helpers support param-driven search flows and error display while keeping URL params as shareable UI state. | Keep `handle_params/3` as the canonical source of truth; helpers should shape values/errors and URL params, not execute search or own socket lifecycle. |
</phase_requirements>

## Summary

The checked-out Phase 80 seam already gives Scrypath one public edge module: `Scrypath.QueryParams.cast/1` returns a plain-data map and `to_search_args/1` turns it into `{text, keyword_opts}` for a context-owned `Scrypath.search/3` call. The current limitation is deliberate: nested values must already be runtime-compatible Elixir shapes, and request-style nested params raise `ArgumentError`. That is the exact gap Phase 81 should close. [VERIFIED: `lib/scrypath/query_params.ex`] [VERIFIED: `lib/scrypath/query_params/caster.ex`] [VERIFIED: `test/scrypath/query_params_test.exs`]

The existing runtime grammar is already explicit enough to anchor normalization. `Scrypath.Options.validate_search_filter/1`, `validate_search_sort/1`, `validate_search_page/1`, and `validate_per_query_map/1` define the accepted runtime shapes and preserve important constraints such as positive pagination bounds, atom-keyed filter/sort lists, and the `per_query` allowlist. Phase 81 should reuse those validators after converting browser-shaped params into runtime-compatible forms instead of inventing a parallel semantics layer. [VERIFIED: `lib/scrypath/options.ex`]

The current Phoenix guidance and compile-checked docs fixtures both keep the boundary honest: controllers and LiveViews translate params, then delegate to a context. They also show the real duplication pressure this phase exists to remove. The JSON controller still hand-rolls page parsing, and the faceted LiveView still hand-rolls `genre` parsing and `facet_filter` construction inside `handle_params/3`. Phase 81 should replace that repeated glue with a shared toolkit plus optional Phoenix projection helpers while preserving `handle_params/3` as the canonical URL-state path. [VERIFIED: `test/support/docs/phoenix_example_case.ex`] [VERIFIED: `test/support/docs/phoenix_examples_test.exs`] [VERIFIED: `guides/phoenix-liveview.md`] [VERIFIED: `guides/phoenix-controllers-and-json.md`] [VERIFIED: `guides/faceted-search-with-phoenix-liveview.md`]

**Primary recommendation:** plan Phase 81 in two slices:
1. Core browser-param normalization plus structured edge-error contract in `Scrypath.QueryParams`.
2. Optional `Scrypath.Phoenix` wrappers, fixture/doc updates, and regression coverage for controller/form/URL/LiveView flows.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Browser-param normalization | Core library edge contract | Phoenix adapters | The normalized result must remain usable outside Phoenix. |
| Structured field-scoped edge errors | Core library edge contract | Phoenix adapters | The error model should stay framework-light, with Phoenix projecting it into form-friendly values. |
| URL/form projection | Optional Phoenix adapter | Docs fixtures | These are Phoenix ergonomics, not runtime responsibilities. |
| LiveView param flow | Host app LiveView | Optional Phoenix adapter | `handle_params/3` remains the owner of URL-driven state and context calls. |
| Search execution | Host app context | Core runtime | `Scrypath.search/3` stays canonical; no helper should search directly. |

## Standard Stack

### Core

| Library / Module | Purpose | Why Standard |
|------------------|---------|--------------|
| `Scrypath.QueryParams` | Public plain-data edge contract | Already the public seam introduced by Phase 80. |
| `Scrypath.QueryParams.Caster` | Internal normalization seam | Already owns the cast path that currently rejects nested request-style shapes. |
| `Scrypath.Options` | Canonical runtime grammar validators | Reusing it prevents drift between edge normalization and runtime acceptance. |
| `Scrypath.search/3` | Canonical runtime entrypoint | Phase 81 must feed this path, not compete with it. |

### Supporting

| Library / Module | Purpose | When to Use |
|------------------|---------|-------------|
| `NimbleOptions` | Validation and stable error message shaping | For nested page/per-query normalization or schema-driven sub-validation. |
| Phoenix guides + fixture tests | Boundary and docs truth | For shaping optional Phoenix helpers and keeping examples honest. |
| `Plug.Conn.Query.decode/1` smoke tests | Browser-shaped param proof | For testing real nested param decoding without pulling Phoenix into core tests. |

## Architecture Patterns

### Pattern 1: Convert browser params into the existing plain-data contract

Phase 81 should keep `Scrypath.QueryParams` as the public surface and add a non-raising normalize path. The public result should still be the existing plain-data contract that `to_search_args/1` already understands.

### Pattern 2: Reuse runtime validators after shape conversion

Convert request-style values into runtime-compatible `filter`, `sort`, `page`, `facets`, `facet_filter`, and `per_query` structures, then reuse `Scrypath.Options` validators to confirm bounds and type correctness. This avoids maintaining separate definitions of valid search options.

### Pattern 3: Separate core errors from Phoenix projection

The core edge contract should return aggregate structured errors with stable metadata such as `code`, `message`, `path`, and `meta`, grouped into `form_errors`, `field_errors`, and `errors`. Phoenix-facing helpers can then map that structure into `to_form/2`-friendly values without freezing Ecto changeset semantics into the public core contract.

### Pattern 4: URL params remain the shareable LiveView state

LiveView helpers should support `handle_params/3`-driven flows, attempted values, and `push_patch/2` round-tripping. They should not introduce event-only search execution, opaque callbacks, or socket-owning abstractions.

## Recommended Plan Slices

### Slice 1: Core normalization and edge-error contract

- Expand `Scrypath.QueryParams` / `Scrypath.QueryParams.Caster` to support Plug-decoded nested params for `q`, `text`, `filter`, `sort`, `page`, `facets`, and `facet_filter`.
- Introduce aggregate non-raising result semantics for browser-param normalization.
- Define the public structured edge-error contract and regression tests for malformed nested input, unknown nested keys, invalid page bounds, bad sort/filter shapes, and `per_query` exclusions.
- Preserve `to_search_args/1` and the `Scrypath.search/3` boundary.

### Slice 2: Optional Phoenix wrappers and docs-fixture adoption

- Add one plain-function optional Phoenix module for param/url/form projection and delegation to the core normalizer.
- Replace hand-rolled page and facet parsing in docs fixtures with the shared helpers.
- Update Phoenix guides and docs-contract tests to pin the new edge-helper story without implying a second runtime or Phoenix dependence in core.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Runtime grammar | A separate search grammar for browser helpers | `Scrypath.Options` validators and existing search-option vocabulary | Prevents drift from the canonical runtime. |
| Core error rendering | `%Ecto.Changeset{}` as the public error contract | Plain-data edge errors plus Phoenix projection | Keeps Phoenix optional and core reusable outside Ecto/Phoenix. |
| LiveView orchestration | `search_from_params` helper that executes search | `QueryParams` + context-owned `Scrypath.search/3` | Avoids a second runtime. |
| Phoenix integration | Controller macros / `use Scrypath.Phoenix` / widgets | Small helper functions only | Keeps the public surface narrow and honest. |

## Common Pitfalls

### Pitfall 1: Hard-coding Phoenix into core normalization

If core `QueryParams` helpers depend on Phoenix form or route semantics, the public toolkit stops being reusable outside Phoenix and violates the milestone boundary.

### Pitfall 2: Preserving Phase 80 raise semantics for invalid nested params

The current raise-on-invalid nested shape behavior blocks `QTK-03`. Phase 81 needs aggregate renderable errors instead of first-failure exceptions for expected request mistakes.

### Pitfall 3: Diverging browser grammar from runtime grammar

If request normalization accepts semantics that `Scrypath.Options` later rejects, apps will see confusing double-validation behavior. Keep conversion narrow and reuse the runtime validators.

### Pitfall 4: Hiding LiveView state transitions

If helpers own socket updates or search execution, the boundary becomes opaque and docs start implying a framework facade. Keep the canonical flow: params -> normalize -> assign attempted state/errors -> context call on success.

### Pitfall 5: Unsafe atom creation from request params

Any conversion from browser strings to atoms must be allowlisted and bounded. Request input must never flow through `String.to_atom/1`.

## Validation Architecture

### Test Framework

- Core unit tests in `test/scrypath/query_params_test.exs`
- Optional Phoenix helper tests in a dedicated `test/scrypath/phoenix_test.exs` or similar
- Fixture-level behavioral tests in `test/support/docs/phoenix_examples_test.exs`
- Real nested-param smoke via `Plug.Conn.Query.decode/1`
- Docs-contract anchors in `test/scrypath/docs_contract_test.exs`

### Phase Requirements -> Test Map

| Requirement | Validation Strategy |
|-------------|---------------------|
| QTK-02 | Request-shaped maps normalize into the existing plain-data contract for success cases across text, page, filters, sort, facets, and facet_filter. |
| QTK-03 | Invalid browser input returns aggregate field-scoped errors with stable machine-readable issue metadata. |
| PHX-01 | Optional helper tests prove URL/form round-trip helpers are pure and do not execute search or require Phoenix in runtime core. |
| PHX-02 | Fixture LiveView tests prove `handle_params/3` remains the URL-state source of truth and helpers can drive attempted values plus renderable errors. |

### Wave 0 Gaps

- No current research artifact existed for Phase 81.
- The current docs fixture still hand-rolls page and facet parsing.
- The current public `QueryParams.cast/1` contract raises on request-style nested values.

## Security Domain

### Applicable Concerns

- Untrusted request params entering public normalization
- Atom exhaustion from string-to-atom conversion
- Unexpected nested keys inside owned namespaces
- Silent dropping of malformed nested request data

### Mitigation Direction

- Explicit allowlists for top-level and nested owned keys
- Aggregate error reporting for malformed owned namespaces
- No `String.to_atom/1` on untrusted input
- Phoenix helpers remain pure adapters over validated core output

## Open Questions (RESOLVED)

1. **Should the error contract be Phoenix/Ecto-native?**
   - Recommendation: no. Keep the core edge error contract plain data and let Phoenix project it.

2. **Should Phoenix helpers live in `QueryParams`?**
   - Recommendation: no. Keep `Scrypath.QueryParams` framework-light and place adapters in a separate optional module.

3. **Should LiveView helpers execute search or own callbacks?**
   - Recommendation: no. They should only shape params, values, and errors around the context-owned boundary.

## Sources

### Primary

- `.planning/ROADMAP.md`
- `.planning/REQUIREMENTS.md`
- `.planning/PROJECT.md`
- `.planning/STATE.md`
- `.planning/phases/81-edge-normalization-errors-and-phoenix-wrappers/81-CONTEXT.md`
- `.planning/phases/81-edge-normalization-errors-and-phoenix-wrappers/81-PATTERNS.md`
- `.planning/phases/80-public-query-toolkit-contract/80-RESEARCH.md`
- `lib/scrypath/query_params.ex`
- `lib/scrypath/query_params/caster.ex`
- `lib/scrypath/options.ex`
- `test/scrypath/query_params_test.exs`
- `test/support/docs/phoenix_example_case.ex`
- `test/support/docs/phoenix_examples_test.exs`
- `test/support/docs/phoenix_request_shape_smoke_test.exs`
- `guides/phoenix-contexts.md`
- `guides/phoenix-liveview.md`
- `guides/phoenix-controllers-and-json.md`
- `guides/faceted-search-with-phoenix-liveview.md`

## RESEARCH COMPLETE
