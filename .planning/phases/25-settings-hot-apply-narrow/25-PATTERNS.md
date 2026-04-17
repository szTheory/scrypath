# Phase 25 — Pattern Map

Analogs for new or heavily modified files.

## `lib/scrypath/meilisearch/settings.ex`

- **Analog:** `apply/3` (lines ~123–136) — `resolve` → `translate_settings` → `client().update_settings` → `normalize_task`.
- **Hot path difference:** Input is a **user-supplied subset** merged with nothing from full `resolve/2` for the PATCH body; still run **only** extracted keys through `translate_settings/1` on a small map.

## `lib/scrypath/meilisearch/tasks.ex`

- **Analog:** `wait_for_task/2` — use after `update_settings` returns initial task map, identical to `Sync.maybe_wait_for_task/2` pattern.

## `lib/mix/tasks/scrypath.settings.diff.ex`

- **Analog:** `run/1` — `Mix.Task.run("app.start")`, `OperatorTask.parse!`, `OperatorTask.schema_from_argv!`, `Scrypath.Config.resolve!`, `OperatorTask.runtime_opts ++ test_operator_opts`, `OperatorTask.error!/2` on failure.

## `test/support/meilisearch_integration.ex`

- **Analog:** `fetch_settings!/1`, `delete_index/1`, `meilisearch_url!/0` — reuse for integration test index lifecycle.

## Code excerpts (reference)

Settings apply core:

```elixir
with {:ok, response} <- client(config).update_settings(index_name, translated, config),
     {:ok, task} <- Meilisearch.normalize_task(response) do
  {:ok, %{index: index_name, settings: settings, task: task}}
end
```

Stub to replace:

```elixir
def hot_apply(_schema_module, _index_name, _config), do: {:error, :hot_apply_disabled}
```

## PATTERN MAPPING COMPLETE
