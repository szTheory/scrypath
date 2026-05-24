# Phase 84: Metadata Reflection And Multi-Search Parity - Pattern Map

**Mapped:** 2026-05-23
**Files analyzed:** 11
**Analogs found:** 11 / 11

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/scrypath/metadata.ex` | utility | transform | `lib/scrypath/query_params.ex` | exact |
| `lib/scrypath/metadata/capabilities.ex` | utility | transform | `lib/scrypath/options.ex` | role-match |
| `lib/scrypath/metadata/resolve.ex` | utility | transform | `lib/scrypath/composition/merge.ex` | role-match |
| `lib/scrypath/composition.ex` | utility | transform | `lib/scrypath/composition.ex` | exact |
| `lib/scrypath/composition/multi.ex` | utility | transform | `lib/scrypath/multi_search/entries.ex` | exact |
| `lib/scrypath.ex` | utility | request-response | `lib/scrypath.ex` | exact |
| `test/scrypath/metadata_test.exs` | test | transform | `test/scrypath/composition_test.exs` | role-match |
| `test/scrypath/composition_many_test.exs` | test | transform | `test/scrypath/multi_search/entries_test.exs` | exact |
| `test/scrypath/docs_contract_test.exs` | test | request-response | `test/scrypath/docs_contract_test.exs` | exact |
| `lib/mix/tasks/verify.phase84.ex` | utility | batch | `lib/mix/tasks/verify.phase83.ex` | exact |
| `guides/multi-index-search.md` | docs | request-response | `guides/multi-index-search.md` | exact |

## Pattern Assignments

### `lib/scrypath/metadata.ex`

**Analog:** `lib/scrypath/query_params.ex`

- Use one narrow public facade with typedocs and explicit plain-data return values.
- Keep execution out of the module.
- Mirror the current `to_search_args/1` style by exposing small conversion/inspection helpers rather than a large object API.

Useful patterns:
- public typedoc map contracts
- function-first API
- deterministic field-order helpers

### `lib/scrypath/metadata/capabilities.ex`

**Analog:** `lib/scrypath/options.ex`

- Derive capability truth from existing declaration and validation seams instead of duplicating allowlists.
- Reuse the same vocabulary the runtime validates: `filter`, `sort`, `page`, `facets`, `facet_filter`, `per_query`.
- Keep field/shape normalization close to current option-validation logic.

Useful patterns:
- small private helpers around field families
- explicit tuple errors for invalid shapes
- declaration-backed lists and maps rather than freeform structs

### `lib/scrypath/metadata/resolve.ex`

**Analog:** `lib/scrypath/composition/merge.ex`

- Build resolved metadata from final canonical criteria rather than from raw caller input.
- Keep field-scoped merge/explanation logic explicit.
- Use small helpers to distinguish `applied`, `defaulted`, `fixed`, and `unsupported`.

Useful patterns:
- canonicalize first, compare second
- explicit field-scoped tuples
- derive user-facing state from final normalized data

### `lib/scrypath/composition/multi.ex`

**Analog:** `lib/scrypath/multi_search/entries.ex`

- Preserve existing shared-vs-entry precedence.
- Keep per-entry the canonical unit.
- Lower to existing tuple/shared-option args instead of inventing a new runtime object.
- Keep `:per_query` shallow-merge semantics aligned with the current `Entries.normalize/2` behavior.

Useful patterns:
- `Keyword.merge(..., fn _k, _shared, entry -> entry end)`
- dedicated helper for `:per_query`
- explicit errors for forbidden shared-only or new semantic widening

### `test/scrypath/metadata_test.exs`

**Analog:** `test/scrypath/composition_test.exs`

- Use direct plain-data assertions over returned maps.
- Pin visibility vocabulary and non-goals with exact assertions.
- Avoid backend-dependent behavior unless explicitly testing parity boundaries.

### `test/scrypath/composition_many_test.exs`

**Analog:** `test/scrypath/multi_search/entries_test.exs`

- Keep tests small and deterministic.
- Assert exact tuple/shared-option lowering output.
- Pin rail behavior such as entry precedence, forbidden shared `fixed`, and `:all` honesty with exact error tuples.

### `lib/mix/tasks/verify.phase84.ex`

**Analog:** `lib/mix/tasks/verify.phase83.ex`

- Follow the focused verify-task pattern:
  - `Mix.Task.run("app.start")`
  - fail on args
  - run only the relevant test files
  - run `mix docs --warnings-as-errors`

### `guides/multi-index-search.md`

**Analog:** itself plus `guides/request-edge-search.md`

- Keep the guide honest and bounded.
- Explain lowering and reflection as data-preparation and inspection helpers.
- Do not drift into generated widget or merged-global-capability language.

## Recommended Reuse Notes

- Reuse `Scrypath.Composition` field ordering and visibility vocabulary instead of inventing a second naming system.
- Reuse `Scrypath.MultiSearch.Entries` precedence semantics as the semantic floor for multi-search lowering.
- Reuse `DocsContractTest` narrow-string assertion style instead of snapshots.
- Reuse the existing singleton `search_many/2` integration parity idea for at least one metadata/reflection boundary check.
