# Phase 40 — Pattern map (`:all` expansion)

## New module (recommended)

| New file | Analog | Pattern to copy |
|----------|--------|-----------------|
| `lib/scrypath/multi_search/all_expansion.ex` (name finalizable) | `lib/scrypath/multi_search/entries.ex` | `with` pipelines returning `{:ok, _}` \| `{:error, term()}`; **no** HTTP. |

## Modify-in-place patterns

| File | Analog lines | Notes |
|------|--------------|-------|
| `lib/scrypath/search.ex` | `run_search_many/2` (`with {:ok, quads} <- Entries.normalize`) | Insert expansion **before** `normalize`; keep **`validate_search_quads`** after normalize. |
| `lib/scrypath/options.ex` | `@runtime_options` entries (`max_schemas`, `federation_timeout`, …) | Add optional **`global_schemas`** (or agreed name) list type + doc; ensure **`runtime_option_keys/0`** includes it. |
| `test/scrypath/search_many_test.exs` | Existing `FakeBackend`, `@base_opts`, multi-schema tests | Add cases: happy expansion with `global_schemas:`; empty registry; `max_schemas` exceeded after expansion; malformed `{:all, ...}`. |

## Excerpts (contracts)

**Normalize guard (pre-expansion today):**

```elixir
# Entries.normalize/2 — entries == [] → {:error, :empty_schema_list}
# check_schema_count(entries, shared) uses length(entries) vs max_schemas
```

**Search pipeline hook:**

```elixir
# Search.run_search_many/2
with {:ok, quads} <- Entries.normalize(entries, shared_opts),
```

**Target state after Phase 40:**

```elixir
with {:ok, flat_entries} <- AllExpansion.expand(entries, shared_opts),
     {:ok, quads} <- Entries.normalize(flat_entries, shared_opts),
```

*(Exact module/function names are implementation choices within CONTEXT bounds.)*

---

## PATTERN MAPPING COMPLETE
