# Phase 43 — Pattern map

Analog files and extension points for **TUNE-PQ** runtime work.

| Planned change | Role | Closest existing analog | Notes |
|----------------|------|-------------------------|-------|
| `:per_query` NimbleOptions field | Search-time validation | `lib/scrypath/options.ex` `@search_options` + `validate_search_options/2` | Add one `:per_query` entry with nested map validation; keep `Keyword.drop(..., runtime_option_keys())` behavior. |
| Carry tuning into dispatch | Query model | `lib/scrypath/query.ex` `%Query{}` + `new/2` | Add `per_query` (map) to struct and `@type t`; default `%{}`. |
| JSON projection | Meilisearch wire | `lib/scrypath/meilisearch/query.ex` `to_payload/1` | Follow `maybe_put/3` style; camelCase string keys for Meilisearch JSON. |
| Telemetry for debug knobs | Observability | `lib/scrypath/search.ex` `do_search/5`, `Telemetry.span` | Mirror existing metadata patterns; **do not** use `Mix.env/0`. |
| `search_many` merge exception | Multi-search | `lib/scrypath/multi_search/entries.ex` `normalize_one/2` | After `Keyword.merge/3`, special-case `:per_query` inner `Map.merge/2` (shared left, entry right on conflicts). |
| Thin verify composer | CI | `lib/mix/tasks/verify.phase41.ex` | Clone structure: `@focused_tests`, `ensure_no_args!/1`, `Mix.Task.run("test", args)`. |
| Doc contract pins | Drift prevention | `test/scrypath/docs_contract_test.exs` `@verify_phase41` | Add `@verify_phase43` + assertion test mirroring phase 41. |
| Facet-scoped search path | API surface | `lib/scrypath/search.ex` `search_within_facet/4` | Same validation path as `search/3` after bucket merge. |

## Code excerpts (reference)

**Entry vs shared merge (today):**

```elixir
merged <- Keyword.merge(shared, entry_core, fn _k, _s, e -> e end)
```

**Query payload base (today):**

```elixir
%{q: query.text}
|> maybe_put(:filter, ...)
```

**Validate search options pipeline:**

```elixir
search_opts = Keyword.drop(opts, runtime_option_keys())
with {:ok, validated} <- nimble_options_result(@search_options, search_opts), ...
```

## PATTERN MAPPING COMPLETE
