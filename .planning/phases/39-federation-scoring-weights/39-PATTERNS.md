# Phase 39 — Pattern map

Analogs and conventions for federation weights and merge trace.

## Error tuple pattern

From `Search` / `Entries` (Phase 21):

- Entry-shape / rails: `{:error, {:invalid_options, {:federation_key_in_entry, key}}}` style.
- Phase 39 adds: `{:error, {:invalid_options, {:federation_weight, detail}}}` and `{:error, {:invalid_options, {:federation_merge_requires_native_search_many, detail}}}`.

**Example (existing):**

```86:90:lib/scrypath/multi_search/entries.ex
  defp reject_shared_only_in_entry(entry_opts) do
    case Enum.find(entry_opts, fn {k, _} -> MapSet.member?(@shared_only_federation_keys, k) end) do
      nil -> :ok
      {k, _} -> {:error, {:invalid_options, {:federation_key_in_entry, k}}}
    end
```

## Strip-before-validate

`Options.validate_search_options/2` uses NimbleOptions on `@search_options` — non-schema keys must not reach it.

**Pattern:** In `Search.validate_search_triples/1`, call `Keyword.drop(merged, [:federation_weight])` (or strip in `Entries` so returned `merged` never contains it). CONTEXT mandates strip before `validate_search_options/2`.

## Backend callback

`Scrypath.Backend` — optional `search_many/2`; `Search` already branches:

```148:152:lib/scrypath/search.ex
      if function_exported?(backend, :search_many, 2) do
        run_native_search_many(backend, paired_queries, config)
      else
        run_sequential_search_many(backend, paired_queries, config)
      end
```

Extend: if merge-only options present, **do not** call `run_sequential_search_many/3`; return structured error instead.

## Meilisearch payload builder

Current `search_many` omits per-query `federationOptions`:

```72:89:lib/scrypath/meilisearch.ex
  def search_many(paired_queries, config) when is_list(paired_queries) do
    queries =
      Enum.map(paired_queries, fn {schema_module, %Query{} = query} ->
        index = index_name(schema_module, config)

        query
        |> MeilisearchQuery.to_payload()
        |> Map.put("indexUid", index)
      end)

    federation = %{
      "limit" => Keyword.fetch!(config, :federation_limit),
      "offset" => Keyword.fetch!(config, :federation_offset)
    }

    payload = %{"queries" => queries, "federation" => federation}

    client(config).multi_search(payload, config)
  end
```

**Analog:** Add a pure helper or extend `Enum.map` to merge `"federationOptions"` when weight present; keep JSON keys stringly typed.

## Federated decode

`FederatedDecode.per_schema_maps/2` walks federated `hits` — merge-order trace should use the **same** ordered list before `group_hits_by_federation_uid/1` (or a single pass that records `{uid, id}` order then resolves schema modules via `indexed_schemas` order map).

## Struct extension

`MultiSearchResult` uses `defstruct` with optional `:federation` — add optional merge-trace field the same way (not in `@enforce_keys`).

## PATTERN MAPPING COMPLETE
