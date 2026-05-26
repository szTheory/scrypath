# Phase 93: Reflection and Runtime Enforcement - Pattern Map

**Mapped:** 2026-05-25
**Files analyzed:** 2
**Analogs found:** 2 / 2

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/scrypath/metadata/capabilities.ex` | metadata | reflection | `lib/scrypath/metadata/capabilities.ex` (existing) | exact |
| `lib/scrypath/options.ex` | utility | validation/transformation | `lib/scrypath/options.ex` (existing) | exact |

## Pattern Assignments

### `lib/scrypath/metadata/capabilities.ex` (metadata, reflection)

**Analog:** Existing `schema_capabilities/1` function in the same file.

**Core Reflection Pattern** (lines 8-28):
```elixir
  @spec schema_capabilities(module()) :: map()
  def schema_capabilities(schema_module) when is_atom(schema_module) do
    faceting = schema_module.__scrypath__(:faceting)
    facet_attributes = Keyword.get(faceting, :attributes, [])

    %{
      filters: %{
        supported: schema_module.__scrypath__(:filterable) != [],
        fields: schema_module.__scrypath__(:filterable)
      },
      # ...
```
**Assignment:** Add `tenant: schema_module.__scrypath__(:tenant_field),` at the root level of the returned map. Since Phase 92 ensures `__scrypath__(:tenant_field)` returns `nil` when not declared, this safely covers both the populated and `nil` requirements.

---

### `lib/scrypath/options.ex` (utility, validation/transformation)

**Analog 1: Adding a search option** (lines 201-205 in `@search_options`)
```elixir
    filter: [
      type: {:custom, __MODULE__, :validate_search_filter, []},
      default: [],
      doc: "Structured common-path filters over declared filterable fields."
    ],
```
**Assignment:** Add `tenant_scope:` to `@search_options`. Omit the `default:` key and set `required: false` so `NimbleOptions` preserves its explicit presence/absence.

**Analog 2: Validation pipeline and safe injection** (lines 478-485 in `validate_search_options/2`)
```elixir
      try do
        validated
        |> validate_filterable_fields!(filterable)
        |> validate_sortable_fields!(sortable)
        |> then(&{:ok, &1})
      rescue
        e in ArgumentError -> {:error, {:validation, Exception.message(e)}}
      end
```
**Assignment:** Create a private `inject_tenant_scope!(opts, schema_module)` function that intercepts the validated options before `validate_filterable_fields!`. It must extract the `tenant_scope` using `Keyword.fetch/2` (so it cleanly handles `tenant_scope: nil`) and modify the `filter:` keyword list. Placing the injection step here automatically enables `tenant_scope:` for `Scrypath.search/3`, `Scrypath.search_within_facet/4`, and `Scrypath.search_many/2` concurrently.

**Analog 3: Conflict checking** (`lib/scrypath/search.ex` lines 114-124 - `merge_facet_bucket_into_opts!`)
```elixir
    if Keyword.has_key?(existing, attr) do
      raise ArgumentError,
            "search_within_facet: facet_filter already contains #{inspect(attr)}; " <>
              "omit that key from facet_filter: or use Scrypath.search/3 instead of locking the same attribute twice"
    else
      Keyword.put(opts, :facet_filter, Keyword.put(existing, attr, value))
    end
```
**Assignment:** Inside `inject_tenant_scope!/2`:
1. Fetch the value with `Keyword.fetch(opts, :tenant_scope)` (return unchanged if `:error`).
2. If present, check if `schema_module.__scrypath__(:tenant_field)` is nil (raise `ArgumentError` if so).
3. Check if the target `tenant_field` already exists in `opts[:filter]` and raise an `ArgumentError` to prevent caller shadowing. 
4. Inject `{tenant_field, scope_val}` into the filter list. 
Because this happens inside the `try` block of `validate_search_options/2`, the `ArgumentError` correctly surfaces as `{:error, {:validation, message}}`.

## Shared Patterns

### Error Handling
**Source:** `lib/scrypath/options.ex` `validate_search_options/2`
**Apply to:** Filter conflict checks
The validation pipeline catches `ArgumentError` and converts it to `{:error, {:validation, message}}`, which `Scrypath.Search` functions appropriately branch on (or raise for bang variants). Raising `ArgumentError` in `inject_tenant_scope!` is idiomatic and fully supported by the existing error boundary.

## Metadata

**Analog search scope:** `lib/scrypath/**/*.ex`
**Files scanned:** `lib/scrypath/options.ex`, `lib/scrypath/metadata/capabilities.ex`, `lib/scrypath/search.ex`
**Pattern extraction date:** 2026-05-25
