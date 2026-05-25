# Phase 92: Guide and Schema Declaration — Research

**Researched:** 2026-05-25
**Domain:** Elixir library internals — NimbleOptions schema options, compile-time macro normalization, document projection, ExDoc guide registration
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**D-01:** `tenant_field: :tenant_id` auto-adds `:tenant_id` to `fields:` at compile time if it is not already present. Merge is idempotent — if already in `fields:`, no-op, no warning.

**D-02:** When auto-injection occurs (field NOT already in `fields:`), emit `IO.warn/2` at compile time. Message explains auto-addition and tells developer how to silence it (add the field explicitly to `fields:`). `IO.warn/2` is the correct Elixir mechanism for "we did something on your behalf at compile time."

**D-03:** `tenant_field:` also auto-adds the named field to `filterable:` (idempotent — no-op if already present). This is the primary purpose: marking the field as filterable for Meilisearch index settings.

**D-04:** Implementation goes in `lib/scrypath/options.ex` `validate_schema_options!/1` as a normalization pass AFTER NimbleOptions validation. Deduplicate both `fields:` and `filterable:` lists preserving original order using the same dedup helper already present in `options.ex`.

**D-05:** When `tenant_field:` is declared AND the schema exports `search_document/1`, `Scrypath.Projection` performs a post-hook merge: after calling `schema_module.search_document(record)` to get the projected map, it ensures the tenant field is present in `Document.data` by pulling its value from the source record. If the custom hook already included the tenant field, the merge is a no-op.

**D-06:** This post-hook merge ensures the library's "declare once, it works correctly" contract holds regardless of whether the developer's `search_document/1` remembered to include the tenant field. Missing tenant field in indexed document returns empty results for entire tenant with no error — this is a silent data-leak failure mode.

**D-07:** The projection module must check `schema_module.__scrypath__(:config)` (or a new `__scrypath__(:tenant_field)` accessor) to know whether a tenant field is declared. Add `def __scrypath__(:tenant_field)` to `lib/scrypath/schema.ex` alongside the other accessors.

**D-08:** Multitenancy guide uses correct-pattern-first structure: show recommended shared-index + filter-injection pattern upfront, then introduce footgun as "common mistake to avoid" with explicit `## Wrong` / `## Correct` code examples.

**D-09:** Filter footgun examples use ONLY the context-layer pattern (explicit filter construction). Phase 92 ships WITHOUT `tenant_scope:`. Guide does NOT forward-reference Phase 93.

**D-10:** Wrong pattern labeled prominently (e.g., `## ❌ Wrong — tenant filter silently dropped`) and `Keyword.merge` last-key-wins behavior explained inline. Correct pattern shows explicit AND-combination in the context layer.

**D-11:** Filter composition example shows context as enforcement boundary — tenant ID is an explicit parameter, never extracted from conn/plug assigns/process dictionary. Async safety called out explicitly.

**D-12:** Guide sections (all required per TNNT-01):
  1. Overview of shared-index model + why per-tenant indexes are not the default
  2. Correct context-layer pattern with explicit tenant parameter
  3. Filter merge order footgun (wrong/correct code examples)
  4. Meilisearch tenant token guidance (browser-direct only, NOT server-side Scrypath search, Joken recipe link)
  5. `search_document/1` custom hook edge case (what `tenant_field:` guarantees in projection)
  6. Schema declaration example (`use Scrypath` with `tenant_field:`)

**D-13:** Add `guides/multitenancy.md` to ExDoc `extras:` list and place it in the **Getting Started** `groups_for_extras` group alongside `guides/composing-real-app-search.md` and `guides/related-data-and-reindexing.md`.

### Claude's Discretion

- Exact wording of `IO.warn` message — follow existing advisory messages in `options.ex` for tone/format
- Exact placement of `guides/multitenancy.md` within the Getting Started group list (after `related-data-and-reindexing.md` is sensible)
- Internal dedup helper naming/reuse — reuse existing pattern in `options.ex`
- Whether to add `__scrypath__(:tenant_field)` or check `__scrypath__(:config).tenant_field` — use whichever is consistent with existing accessor pattern in `schema.ex`

### Deferred Ideas (OUT OF SCOPE)

- `schema_capabilities/1` reflection for `:tenant` key — Phase 93
- `tenant_scope:` runtime enforcement — Phase 93
- `mix verify.phase94` hermetic gate — Phase 94
- Joken tenant token generation helpers in library core — TNNT-FUT-02, explicitly out of scope
- Per-tenant Meilisearch index routing — TNNT-FUT-01, explicitly out of scope
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| TNNT-01 | User can follow `guides/multitenancy.md` to implement tenant-safe search — guide covers shared-index model, correct context-layer pattern, filter merge footgun (wrong/correct examples), per-tenant index anti-pattern with Meilisearch throughput reason, tenant token placement (browser-direct only), `search_document/1` edge case | Guide narrative structure fully mapped in D-08 through D-13; wrong/correct pattern and footgun mechanics documented in Architecture Patterns section |
| TNNT-02 | User can declare `tenant_field: :field_name` in a Scrypath schema and have the named field automatically included in both `filterable:` and the synced document projection without separate declarations | Implementation insertion points identified: `@schema_options` NimbleOptions spec, `validate_schema_options!/1` normalization pass, `schema.ex` accessor, `projection.ex` post-hook merge |
</phase_requirements>

---

## Summary

Phase 92 delivers two co-shipped artifacts: a canonical multitenancy guide (`guides/multitenancy.md`) and a `tenant_field:` schema option that auto-injects the tenant field into both `filterable:` and the document projection. These are co-shipped because the declaration is meaningless without the guide to explain the threat model, and the guide is incomplete without a working schema example to demonstrate it.

The implementation is narrow and well-bounded. All four insertion points are known from the existing codebase: the NimbleOptions `@schema_options` spec in `options.ex`, the `validate_schema_options!/1` normalization pipeline, the `schema.ex` `__scrypath__/1` accessor, and the `projection.ex` `build_custom_document/2` post-hook. The `dedupe_preserve_order/1` helper already exists in `options.ex` and covers the idempotent merge requirement. Existing `IO.puts(:stderr, ...)` advisory patterns in `options.ex` establish the tone and format; D-02 specifies `IO.warn/2` (not `IO.puts`) which produces a proper warning with stacktrace context rather than a plain print — `IO.warn/2` is available and tested in Elixir 1.17+ (confirmed available in 1.19.5 on this system).

The guide requires no new infrastructure — it follows the same Markdown structure as `related-data-and-reindexing.md` (the most recent guide, confirmed as the style target) and is registered in `mix.exs` `extras:` / `groups_for_extras` following the established ExDoc pattern. Tests follow the existing `capture_io(:stderr, ...)` pattern for the `IO.warn` advisory, and the projection post-hook adds a new test case to `projection_test.exs` using the same module-in-test pattern already present.

**Primary recommendation:** Implement in three logical task groups — (1) `options.ex` + `schema.ex` for the compile-time `tenant_field:` declaration, (2) `projection.ex` for the post-hook tenant field merge, (3) `guides/multitenancy.md` + `mix.exs` ExDoc registration. Write tests concurrently with each group.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| `tenant_field:` schema option declaration | Compile-time macro layer (`options.ex`, `schema.ex`) | — | Schema options are validated and normalized at compile time in `validate_schema_options!/1`; this is where all option normalization lives |
| `filterable:` auto-injection | Compile-time macro layer (`options.ex`) | — | `filterable:` is a schema-level list already managed in `validate_schema_options!`; auto-injection is a normalization pass on the same map |
| `fields:` auto-injection with IO.warn | Compile-time macro layer (`options.ex`) | — | Same pipeline as filterable; `dedupe_preserve_order/1` already handles idempotent merge |
| `__scrypath__(:tenant_field)` reflection | Schema module accessor (`schema.ex`) | — | All `__scrypath__/1` keys are generated in the `__using__` macro; new key follows exact same pattern as `:fields`, `:filterable`, etc. |
| Post-hook tenant field merge for `search_document/1` | Document projection (`projection.ex`) | — | `build_custom_document/2` is the sole callsite for custom hook projection; post-hook merge belongs here |
| Canonical multitenancy guide | Documentation layer (`guides/`) | `mix.exs` ExDoc registration | Content responsibility: guides/; discovery responsibility: mix.exs `extras:` + `groups_for_extras` |
| Filter merge order footgun education | Guide (`guides/multitenancy.md`) | — | A documentation concern, not a runtime enforcement — that is Phase 93's `tenant_scope:` |

---

## Standard Stack

No new external packages are required for this phase. All implementation uses:

- **Elixir stdlib** — `IO.warn/2`, `MapSet`, list operations [VERIFIED: available in Elixir 1.17+, confirmed 1.19.5 on system]
- **NimbleOptions** (already a dependency at `~> 1.1`) — for the `tenant_field:` option spec [VERIFIED: existing dep in mix.exs]
- **ExDoc** (already a dep at `~> 0.37`, dev/test only) — for `extras:` + `groups_for_extras` registration [VERIFIED: existing dep in mix.exs]

### Package Legitimacy Audit

No new packages are installed in this phase.

**Packages removed due to slopcheck [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

---

## Architecture Patterns

### System Architecture Diagram

```
compile time
  use Scrypath opts
       │
       ▼
  validate!/1 (NimbleOptions)          ← @schema_options spec
       │ keyword list
       ▼
  ensure_non_empty_fields!/1           ← converts to map
       │ map
       ▼
  validate_faceting_rules!/1
       │ map
       ▼
  [NEW] normalize_tenant_field!/1      ← auto-inject into fields: and filterable:
       │                                  emit IO.warn/2 if fields: was mutated
       │ map
       ▼
  Map.put(:document_source, :fields)
       │ config map
       ▼
  stored in @scrypath_config
  __scrypath__/1 accessors generated
  including [NEW] __scrypath__(:tenant_field)

runtime (document sync)
  Scrypath.Projection.document/2
       │
       ├─── no search_document/1 exported ──► build_field_document/2
       │                                       (fields: already contains tenant field
       │                                        from compile-time injection — no change needed)
       │
       └─── search_document/1 exported ──────► build_custom_document/2
                                                 │
                                                 ▼
                                             call schema_module.search_document(record)
                                                 │ projected map
                                                 ▼
                                             [NEW] merge tenant field if declared
                                             (fetch from source record, put if missing)
                                                 │
                                                 ▼
                                             %Document{source: :custom}

mix.exs docs
  extras: [..., "guides/multitenancy.md", ...]
  groups_for_extras:
    "Getting Started": [..., "guides/related-data-and-reindexing.md",
                             "guides/multitenancy.md",   ← new, after related-data
                             ...]
```

### Recommended Project Structure

No new directories. Changes are surgical insertions into existing files:

```
lib/scrypath/
  options.ex          ← add tenant_field: to @schema_options; add normalize_tenant_field!/1 pass
  schema.ex           ← add __scrypath__(:tenant_field) accessor
  projection.ex       ← add post-hook tenant field merge in build_custom_document/2
guides/
  multitenancy.md     ← new canonical guide (TNNT-01)
mix.exs               ← add guides/multitenancy.md to extras: and Getting Started group
test/scrypath/
  options_test.exs    ← add tenant_field: tests (auto-inject, idempotent, IO.warn)
  schema_test.exs     ← add __scrypath__(:tenant_field) test
  projection_test.exs ← add post-hook merge tests (field injected, field already present = no-op)
```

### Pattern 1: NimbleOptions Custom Schema Option (tenant_field:)

Adding a new optional schema option follows the `fan_outs:` precedent — the most recent addition. [VERIFIED: from options.ex source]

```elixir
# In @schema_options keyword list
tenant_field: [
  type: {:custom, __MODULE__, :validate_tenant_field, []},
  default: nil,
  doc: "Optional tenant field name auto-injected into both filterable: and fields: for shared-index multitenancy."
]

# Validator (simple atom or nil):
def validate_tenant_field(nil), do: {:ok, nil}
def validate_tenant_field(value) when is_atom(value), do: {:ok, value}
def validate_tenant_field(_), do: {:error, "tenant_field must be an atom or nil"}
```

### Pattern 2: Normalization Pass After NimbleOptions (validate_schema_options! pipeline)

The pipeline in `validate_schema_options!/1` flows: `validate!` (keyword list) → `ensure_non_empty_fields!` (returns map) → `validate_faceting_rules!` (returns map) → `Map.put(:document_source, :fields)`. The tenant_field normalization pass receives and returns a map. [VERIFIED: from options.ex source]

```elixir
@spec validate_schema_options!(keyword()) :: map()
def validate_schema_options!(opts) do
  opts
  |> validate!(@schema_options)
  |> ensure_non_empty_fields!()
  |> validate_faceting_rules!()
  |> normalize_tenant_field!()      # ← new, after faceting, before document_source
  |> Map.put(:document_source, :fields)
end

defp normalize_tenant_field!(%{tenant_field: nil} = m), do: m

defp normalize_tenant_field!(%{tenant_field: field} = m) when is_atom(field) do
  # Auto-inject into filterable: (idempotent)
  new_filterable = dedupe_preserve_order([field | Map.fetch!(m, :filterable)])

  # Auto-inject into fields: (idempotent; warn if actually added)
  existing_fields = Map.fetch!(m, :fields)
  new_fields = dedupe_preserve_order([field | existing_fields])

  unless field in existing_fields do
    IO.warn(
      "[scrypath] tenant_field #{inspect(field)} is not listed in fields:. " <>
        "It has been auto-added so search documents include the tenant value. " <>
        "To silence this warning, add #{inspect(field)} to fields: explicitly.",
      []
    )
  end

  %{m | filterable: new_filterable, fields: new_fields}
end
```

### Pattern 3: __scrypath__/1 Accessor for tenant_field

Follows the exact same pattern as all other accessors in schema.ex. [VERIFIED: from schema.ex source]

```elixir
# Added to the quote block in __using__:
def __scrypath__(:tenant_field), do: @scrypath_config.tenant_field
```

The config map from `validate_schema_options!` already contains the `tenant_field` key (either nil or atom) after the normalization pass, so no additional plumbing is needed.

Also update `@moduledoc` key list in `schema.ex` to include `:tenant_field`.

### Pattern 4: Post-Hook Merge in build_custom_document/2

The merge happens after `search_document/1` returns. The tenant field value comes from the source record using the existing `fetch_field!/2` helper. [VERIFIED: from projection.ex source]

```elixir
defp build_custom_document(schema_module, source_record) do
  projected =
    source_record
    |> schema_module.search_document()
    |> ensure_projection_map!()

  id_field = schema_module.__scrypath__(:document_id)

  {id, data} =
    case Map.pop(projected, :id) do
      # ... existing id extraction logic (unchanged) ...
    end

  # NEW: post-hook tenant field merge
  data = maybe_inject_tenant_field(schema_module, source_record, data)

  %Document{id: id, data: data, source: :custom}
end

defp maybe_inject_tenant_field(schema_module, source_record, data) do
  case schema_module.__scrypath__(:tenant_field) do
    nil ->
      data

    field ->
      # Idempotent: if search_document/1 already included the tenant field, no-op
      if Map.has_key?(data, field) do
        data
      else
        Map.put(data, field, fetch_field!(source_record, field))
      end
  end
end
```

### Pattern 5: IO.warn/2 in Macro Context

`IO.warn/2` takes a message string and a second argument that in Elixir 1.18+ can be a stacktrace list or `[stacktrace: list]`. Passing `[]` (empty stacktrace list) emits the warning without file/line context, which is appropriate here since the message text explains the source. `IO.puts(:stderr, ...)` is what the existing code uses, but D-02 explicitly mandates `IO.warn/2` for this new advisory. `IO.warn/2` output is captured by `capture_io(:stderr, ...)` in tests — confirmed by existing test patterns. [VERIFIED: elixir --version 1.19.5, IO.warn confirmed working; ASSUMED: IO.warn output captured by capture_io(:stderr) in ExUnit context — the existing IO.puts(:stderr) tests use capture_io(:stderr) and IO.warn goes to :stderr]

The difference matters: `IO.warn/2` messages appear as Elixir compiler warnings in the build output (yellow, with "warning:" prefix) rather than as plain stderr prints. This is the correct signal for "the compiler did something on your behalf."

### Pattern 6: ExDoc Extras Registration

`mix.exs` `docs/0` function adds new guides to `extras:` as a string path and to the appropriate `groups_for_extras` key. [VERIFIED: from mix.exs source]

```elixir
# In extras: list (add after "guides/related-data-and-reindexing.md"):
"guides/multitenancy.md",

# In groups_for_extras "Getting Started" list (after "guides/related-data-and-reindexing.md"):
"guides/multitenancy.md",
```

The Getting Started group currently ends with `"guides/common-mistakes.md"`. Placement after `"guides/related-data-and-reindexing.md"` keeps the topically related guides (multitenancy builds on related-data understanding) adjacent.

### Anti-Patterns to Avoid

- **Adding tenant_field: normalization BEFORE `ensure_non_empty_fields!`:** That function converts the NimbleOptions keyword result to a map — normalization pass must operate on a map, not a keyword list.
- **Checking `function_exported?(schema_module, :__scrypath__, 1)` from inside projection.ex:** The accessor is always present if `use Scrypath` was called; no nil guard needed. Pattern-match on the value returned, not on the accessor's existence.
- **Overwriting tenant field in data if already present:** The post-hook merge must check `Map.has_key?(data, field)` first — if the developer's `search_document/1` deliberately sets the tenant field to a different shape (string key, transformed value), we must not clobber it. The guarantee is "field is present", not "field has this exact value."
- **Using `IO.puts(:stderr, ...)` instead of `IO.warn/2`:** D-02 is explicit. `IO.puts` emits a plain stderr line; `IO.warn` emits a proper Elixir compiler warning. Both go to :stderr and both are captured by `capture_io(:stderr, ...)`, but the compiler warning format is the correct signal.
- **Forward-referencing `tenant_scope:` in the guide:** D-09 is explicit — guide is accurate at ship time; no Phase 93 hints.
- **Putting tenant ID extraction in the guide's search example:** D-11 is explicit — tenant ID must be an explicit function parameter, never extracted from conn/process dictionary. The guide's examples must demonstrate this.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Deduplicating lists while preserving order | Custom dedup logic | `dedupe_preserve_order/1` already in `options.ex` (line 1137) | Already handles MapSet-based dedup with preserved order; reuse as a private helper call |
| NimbleOptions custom type validator | Custom type system | `{:custom, __MODULE__, :validate_tenant_field, []}` pattern | Established pattern in `@schema_options` for all non-primitive types; fan_outs: and backend: both use it |
| Fetching field from source record in projection | Custom field accessor | `fetch_field!/2` already in `projection.ex` (line 74) | Handles both atom and string key forms; handles missing field error; reuse directly |

**Key insight:** This phase is almost entirely wiring existing primitives together — the dedup helper, the `fetch_field!` helper, the `IO.warn` advisory pattern, and the NimbleOptions custom validator are all already present. The implementation risk is in correct placement within the pipeline, not in building new machinery.

---

## Common Pitfalls

### Pitfall 1: normalize_tenant_field! receives a map, not a keyword list

**What goes wrong:** `validate!(@schema_options)` returns a keyword list. `ensure_non_empty_fields!` converts it to a map via `Enum.into(opts, %{})`. If `normalize_tenant_field!` is inserted before `ensure_non_empty_fields!`, it will receive a keyword list and `Map.fetch!/2` will crash.

**Why it happens:** The pipeline type changes mid-way. Reading the pipeline order carelessly misses the type transition.

**How to avoid:** Insert `normalize_tenant_field!` AFTER `validate_faceting_rules!` (which also operates on the map). Confirmed insertion order: `validate!` → `ensure_non_empty_fields!` → `validate_faceting_rules!` → `normalize_tenant_field!` → `Map.put(:document_source, :fields)`.

**Warning signs:** `FunctionClauseError` or `KeyError` mentioning keyword list instead of map.

### Pitfall 2: IO.warn/2 stacktrace argument

**What goes wrong:** `IO.warn/2` in Elixir 1.18+ changed the second argument — it can be a stacktrace list OR a keyword with `:stacktrace` key. Passing the wrong shape raises `ArgumentError` or silently ignores the stacktrace.

**Why it happens:** Elixir `IO.warn/2` API evolved. Training-data examples may show old forms.

**How to avoid:** Pass `[]` as the second argument (empty stacktrace list). This is universally safe across 1.17+: `IO.warn(message, [])`. The warning appears without a file/line annotation, which is acceptable since the message text describes the fix.

**Warning signs:** `ArgumentError` at compile time when a schema with `tenant_field:` is compiled.

### Pitfall 3: Schema config map key not present — tenant_field defaults to nil

**What goes wrong:** `schema_module.__scrypath__(:tenant_field)` called on a schema that was compiled before the accessor was added (stale beam files) returns `nil` correctly, but calling it on a schema that never declared `tenant_field:` at all (with old `schema.ex`) raises `ArgumentError: unknown Scrypath metadata key: :tenant_field`.

**Why it happens:** The catch-all `def __scrypath__(key), do: raise ArgumentError` in `schema.ex` fires before the new accessor is generated.

**How to avoid:** Both the `@schema_options` addition (with `default: nil`) and the `schema.ex` accessor addition must land in the same commit. Never deploy one without the other.

**Warning signs:** `ArgumentError: unknown Scrypath metadata key: :tenant_field` during test runs after partial change.

### Pitfall 4: Projection post-hook checks atom key only

**What goes wrong:** `search_document/1` may return string keys (e.g., `%{"tenant_id" => value}` instead of `%{tenant_id: value}`). A naive `Map.has_key?(data, field)` where `field` is `:tenant_id` will not find the string-keyed version and will double-inject.

**Why it happens:** Maps in Elixir distinguish atom and string keys. The existing `fetch_field!/2` handles both key forms for the source record, but `build_custom_document/2` does not normalize the projected map's keys.

**How to avoid:** Check both `Map.has_key?(data, field)` AND `Map.has_key?(data, Atom.to_string(field))` before injecting. If either is present, treat as no-op. This mirrors the dual-key check in `fetch_field!/2`.

**Warning signs:** Tenant field appearing twice (as both atom and string key) in projected documents, or test failures on string-keyed `search_document/1` fixtures.

### Pitfall 5: Guide filter footgun example must use real Keyword.merge behavior

**What goes wrong:** The wrong example must show the EXACT failure — `Keyword.merge(base_opts, [filter: tenant_filter])` silently drops a preceding `filter:` in `base_opts` because `Keyword.merge/2` takes the last key-wins for keyword lists. A strawman example that doesn't show real Meilisearch search opts misses the point.

**Why it happens:** Abstracted examples don't convey the concrete mechanism.

**How to avoid:** The wrong example must use `Scrypath.search/3` opts with a real `filter:` key in `base_opts` merged with a `filter:` in the tenant addition. Explicitly comment that `Keyword.merge` drops the first. The correct example shows explicit AND-combination string or a dedicated merge that combines both filters.

**Warning signs:** Reader doesn't understand why the footgun is silent (no error, just wrong results).

---

## Code Examples

Verified patterns from official sources (codebase):

### validate_schema_options! pipeline (current + insertion point)

```elixir
# Source: lib/scrypath/options.ex lines 417-424
@spec validate_schema_options!(keyword()) :: map()
def validate_schema_options!(opts) do
  opts
  |> validate!(@schema_options)
  |> ensure_non_empty_fields!()
  |> validate_faceting_rules!()
  |> normalize_tenant_field!()      # ← INSERT HERE (returns map)
  |> Map.put(:document_source, :fields)
end
```

### dedupe_preserve_order/1 (existing helper, reuse directly)

```elixir
# Source: lib/scrypath/options.ex lines 1137-1148
defp dedupe_preserve_order(attrs) when is_list(attrs) do
  {uniq, _} =
    Enum.reduce(attrs, {[], MapSet.new()}, fn a, {acc, seen} ->
      if MapSet.member?(seen, a) do
        {acc, seen}
      else
        {[a | acc], MapSet.put(seen, a)}
      end
    end)

  Enum.reverse(uniq)
end
```

Note: The new `tenant_field` field must be appended (not prepended) to preserve stable order. Since `dedupe_preserve_order/1` takes `[new | existing]` and then reverses, passing `[field | existing_fields]` would put the tenant field FIRST. For `fields:`, a cleaner approach is `dedupe_preserve_order(existing_fields ++ [field])` to append — so it appears last, not first. For `filterable:`, order is less significant, but consistency with append-on-auto-add is better.

### existing __scrypath__/1 accessor pattern

```elixir
# Source: lib/scrypath/schema.ex lines 32-40
def __scrypath__(:config), do: @scrypath_config
def __scrypath__(:fields), do: @scrypath_config.fields
def __scrypath__(:filterable), do: @scrypath_config.filterable
# ... all follow same pattern ...
# NEW accessor (same pattern):
def __scrypath__(:tenant_field), do: @scrypath_config.tenant_field
```

### build_custom_document/2 (current implementation)

```elixir
# Source: lib/scrypath/projection.ex lines 30-54
defp build_custom_document(schema_module, source_record) do
  projected =
    source_record
    |> schema_module.search_document()
    |> ensure_projection_map!()

  id_field = schema_module.__scrypath__(:document_id)

  {id, data} =
    case Map.pop(projected, :id) do
      {nil, projected_without_id} ->
        case Map.pop(projected_without_id, "id") do
          {nil, projected_without_string_id} ->
            {fetch_field!(source_record, id_field), projected_without_string_id}
          {projected_id, projected_without_string_id} ->
            {projected_id, projected_without_string_id}
        end
      {projected_id, projected_without_id} ->
        {projected_id, projected_without_id}
    end

  %Document{id: id, data: data, source: :custom}
  # ↑ NEW: pass data through maybe_inject_tenant_field/3 before here
end
```

### Test pattern for IO.warn advisory (existing capture_io pattern)

```elixir
# Source: test/scrypath/options_test.exs lines 335-345 (existing IO.puts :stderr test)
test "warns when tenant_field not in fields: (A)" do
  err =
    capture_io(:stderr, fn ->
      Code.compile_string("""
      defmodule TenantAutoInjectPost do
        use Ecto.Schema
        use Scrypath, fields: [:title], tenant_field: :tenant_id
        embedded_schema do
          field :title, :string
          field :tenant_id, :integer
        end
      end
      """)
    end)

  assert err =~ "tenant_field :tenant_id is not listed in fields:"
  assert err =~ "auto-added"
end
```

Note: `Code.compile_string` is used in existing options_test for compile-time behavior testing (see schema_test.exs line 53 for the pattern). This is the right approach for testing advisory messages emitted during `use Scrypath` macro expansion.

### Guide filter footgun pattern

```elixir
## ❌ Wrong — tenant filter silently dropped

def search_posts_for_tenant(query, tenant_id, opts \\ []) do
  base_opts = [
    backend: Scrypath.Meilisearch,
    filter: [status: "published"]    # ← this filter will be silently dropped
  ]
  search_opts = Keyword.merge(base_opts, [filter: [tenant_id: tenant_id]])
  # Keyword.merge/2 takes the last value for duplicate keys.
  # The resulting filter: is [tenant_id: tenant_id] only — status filter is gone.
  # No error is raised. Documents from other tenants may appear.
  Scrypath.search(Post, query, search_opts)
end

## ✅ Correct — explicit AND-combination

def search_posts_for_tenant(query, tenant_id, opts \\ []) do
  Scrypath.search(Post, query,
    backend: Scrypath.Meilisearch,
    filter: [
      tenant_id: tenant_id,
      status: "published"
    ]
  )
end
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `IO.puts(:stderr, ...)` for compile-time advisories | `IO.warn/2` per D-02 | Phase 92 (this phase) | New advisories use the correct Elixir mechanism; existing IO.puts advisories in options.ex are NOT being changed (out of scope) |
| Developer manually adds tenant field to both `filterable:` and `fields:` | `tenant_field:` single declaration auto-injects both | Phase 92 (this phase) | Eliminates "field in filterable but missing from projection" silent failure for tenant-aware schemas |

**Note on existing IO.puts pattern:** The two existing advisories in `options.ex` (camelCase hint, ranking_rules completeness) use `IO.puts(:stderr, ...)`. D-02 specifies `IO.warn/2` for the new tenant_field advisory only. Do not refactor the existing advisories — that is out of scope and risks breaking existing tests that assert on the `IO.puts` format.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `IO.warn/2` output is captured by `capture_io(:stderr, ...)` in ExUnit | Code Examples (test pattern), Common Pitfalls (Pitfall 2) | Tests asserting on the advisory message would not capture it; test would always see empty string. Mitigation: run a quick test early to confirm, or fall back to `IO.puts(:stderr, ...)` if capture fails. | 
| A2 | Prepend vs append in `dedupe_preserve_order` for auto-injected tenant field — `fields: ++ [tenant_field]` appends, putting tenant field last | Architecture Patterns (Pattern 2), Code Examples | Field order in projection map is cosmetic for Meilisearch, but test assertions may depend on order. Keep auto-injected field at the end for least-surprise. |

**Note on A1:** The existing advisory tests use `capture_io(:stderr, fn -> validate_settings(...) end)` which captures `IO.puts(:stderr, ...)`. `IO.warn/2` goes to `:stderr` device — the same device. However `IO.warn/2` may use the Logger backend or a different mechanism depending on Elixir version. If `capture_io(:stderr, ...)` does not capture `IO.warn/2` output, the test can use `capture_log/1` instead or assert via `assert_raise` indirectly. Verify this early in implementation.

---

## Open Questions (RESOLVED)

1. **Does `capture_io(:stderr, ...)` capture `IO.warn/2` output?**
   - What we know: `IO.puts(:stderr, ...)` is captured by `capture_io(:stderr, ...)` in existing tests. `IO.warn/2` writes to `:stderr`. The two mechanisms may or may not be identical in ExUnit's capture.
   - What's unclear: Whether ExUnit's `CaptureIO` intercepts `IO.warn/2` at the `io:format` level or if warnings are routed differently.
   - Recommendation: Write the `IO.warn` advisory test first (Wave 0), run it, confirm capture behavior. If `capture_io(:stderr, ...)` does not capture it, use `ExUnit.CaptureLog` or assert on compiler diagnostics via `Code.compile_string` inside a `capture_io` block.
   - **RESOLVED:** Capture-with-fallback. Write the advisory test using `capture_io(:stderr, fn -> Code.compile_string(...) end)` first; if it returns an empty string, fall back to wrapping the compile in `ExUnit.CaptureLog.capture_log/1`. Both target `:stderr`; the fallback covers the version-dependent routing difference. Plan 92-01 Task 1 encodes this fallback explicitly in the test action.

2. **`dedupe_preserve_order` visibility — private defp or accessible from tests?**
   - What we know: It is currently `defp dedupe_preserve_order/1` in `options.ex` — private.
   - What's unclear: Whether `normalize_tenant_field!` should be a `defp` or whether tests should drive it indirectly via `validate_schema_options!`.
   - Recommendation: Keep `normalize_tenant_field!` private; test exclusively through `validate_schema_options!`. This matches how `validate_faceting_rules!` is tested — indirectly through `Code.compile_string` or via `validate_schema_options!` directly in unit tests.
   - **RESOLVED:** Private `normalize_tenant_field!/1`, tested indirectly. Keep both `dedupe_preserve_order/1` and `normalize_tenant_field!/1` as `defp`; drive all `tenant_field:` behavior through `validate_schema_options!/1` (or `Code.compile_string` for advisory tests), matching the existing `validate_faceting_rules!` test convention. Plan 92-01 Task 1 specifies `normalize_tenant_field!/1` as a private function.

3. **Fan_outs: option in @schema_options vs tenant_field: type spec**
   - What we know: `fan_outs:` uses `{:custom, __MODULE__, :validate_fan_outs, []}`. `tenant_field:` is simpler — just an optional atom.
   - What's unclear: Whether to use `{:custom, ...}` or the built-in `:atom` type with `{:or, [:atom, nil]}` shape.
   - Recommendation: Use `{:custom, __MODULE__, :validate_tenant_field, []}` for consistency and to allow future validation logic (e.g., warning if the atom is not a valid Ecto field name). Simpler NimbleOptions built-in types may not handle `nil` default cleanly.
   - **RESOLVED:** Custom validator `{:custom, __MODULE__, :validate_tenant_field, []}` with `default: nil`, following the `fan_outs:` precedent. This handles the `nil` default cleanly and leaves room for future field-name validation. Plan 92-01 Task 1 adds the `validate_tenant_field/1` validator (atom-or-nil) wired through this custom type.

---

## Environment Availability

Step 2.6: SKIPPED (no external dependencies introduced — Elixir stdlib and existing project deps only).

---

## Validation Architecture

nyquist_validation is enabled in config.json (key present and true).

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (built into Elixir) |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test test/scrypath/options_test.exs test/scrypath/schema_test.exs test/scrypath/projection_test.exs` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| TNNT-02 | `tenant_field:` auto-injects into `filterable:` | unit | `mix test test/scrypath/options_test.exs -t tenant_field` | ❌ Wave 0 (add to options_test.exs) |
| TNNT-02 | `tenant_field:` auto-injects into `fields:` when not present | unit | `mix test test/scrypath/options_test.exs` | ❌ Wave 0 |
| TNNT-02 | Auto-injection is idempotent (field already in `fields:`) | unit | `mix test test/scrypath/options_test.exs` | ❌ Wave 0 |
| TNNT-02 | IO.warn emitted when `fields:` was mutated | unit | `mix test test/scrypath/options_test.exs` | ❌ Wave 0 |
| TNNT-02 | No IO.warn when field already in `fields:` | unit | `mix test test/scrypath/options_test.exs` | ❌ Wave 0 |
| TNNT-02 | `__scrypath__(:tenant_field)` returns declared atom | unit | `mix test test/scrypath/schema_test.exs` | ❌ Wave 0 (add to schema_test.exs) |
| TNNT-02 | `__scrypath__(:tenant_field)` returns nil when not declared | unit | `mix test test/scrypath/schema_test.exs` | ❌ Wave 0 |
| TNNT-02 | Post-hook merge injects tenant field when `search_document/1` omits it | unit | `mix test test/scrypath/projection_test.exs` | ❌ Wave 0 (add to projection_test.exs) |
| TNNT-02 | Post-hook merge is no-op when `search_document/1` already includes tenant field | unit | `mix test test/scrypath/projection_test.exs` | ❌ Wave 0 |
| TNNT-02 | No post-hook behavior when no `tenant_field:` declared | unit | `mix test test/scrypath/projection_test.exs` | ❌ Wave 0 |
| TNNT-01 | `guides/multitenancy.md` exists and contains required section anchors | contract | `mix test test/scrypath/docs_contract_test.exs` | ❌ Wave 0 (add guide anchor test) |
| TNNT-01 | `guides/multitenancy.md` is in ExDoc extras and Getting Started group | contract | `mix test test/scrypath/docs_contract_test.exs` | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** `mix test test/scrypath/options_test.exs test/scrypath/schema_test.exs test/scrypath/projection_test.exs`
- **Per wave merge:** `mix test`
- **Phase gate:** Full suite green + `mix docs --warnings-as-errors` before `/gsd:verify-work`

### Wave 0 Gaps

All test additions are in existing files — no new test files needed:

- [ ] `test/scrypath/options_test.exs` — add `tenant_field:` option tests (auto-inject fields/filterable, idempotent, IO.warn/2 capture)
- [ ] `test/scrypath/schema_test.exs` — add `__scrypath__(:tenant_field)` accessor tests (declared returns atom, undeclared returns nil); update the existing `__scrypath__(:config)` exact-match assertion to include `tenant_field: nil`
- [ ] `test/scrypath/projection_test.exs` — add post-hook merge tests (inject when missing, no-op when present, no-op when tenant_field nil)
- [ ] `test/scrypath/docs_contract_test.exs` — add guide anchor assertions for `guides/multitenancy.md` required sections + ExDoc registration check

---

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — |
| V3 Session Management | no | — |
| V4 Access Control | yes (documentation) | Guide explicitly teaches that tenant filtering is application-layer, not Scrypath-layer enforcement; filter-injection pattern is the documented correct control |
| V5 Input Validation | yes | `validate_tenant_field/1` validates atom-or-nil type at compile time |
| V6 Cryptography | no | — |

### Known Threat Patterns for Shared-Index Multitenancy

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Filter merge order drops tenant guard (Keyword.merge last-key-wins) | Information Disclosure | Guide's explicit wrong/correct examples + D-10 prominent labeling |
| Tenant ID extracted from process dictionary / conn assigns | Information Disclosure | Guide explicitly forbids this (D-11); async boundary rationale given (Task.async, assign_async, Oban) |
| `search_document/1` custom hook omits tenant field from indexed doc | Information Disclosure | Post-hook merge in projection.ex (D-05, D-06) provides library-level safety net |
| Per-tenant index routing misunderstood as equivalent security model | Information Disclosure | Guide section on why per-tenant indexes are not the default (D-12 section 1) |

**Security note:** Phase 92 does NOT ship `tenant_scope:` enforcement (that is Phase 93). The guide must be explicit that the filter-injection pattern requires the developer to consistently pass the tenant filter at every search callsite. The guide's purpose is to make the correct pattern obvious and the failure modes visible.

---

## Sources

### Primary (HIGH confidence)

- `lib/scrypath/options.ex` — Direct source inspection: `validate_schema_options!` pipeline, `dedupe_preserve_order/1` helper, `IO.puts(:stderr, ...)` advisory patterns, `@schema_options` NimbleOptions spec, `fan_outs:` option as precedent
- `lib/scrypath/schema.ex` — Direct source inspection: `__scrypath__/1` accessor pattern, `@scrypath_config` module attribute
- `lib/scrypath/projection.ex` — Direct source inspection: `build_custom_document/2`, `fetch_field!/2`, document source detection
- `mix.exs` — Direct source inspection: `extras:` list, `groups_for_extras` "Getting Started" group
- `test/scrypath/options_test.exs` — Direct source inspection: `capture_io(:stderr, ...)` pattern for advisory tests
- `test/scrypath/projection_test.exs` — Direct source inspection: `Code.compile_string` in-test module pattern
- `test/scrypath/docs_contract_test.exs` — Direct source inspection: guide anchor test pattern, `@guide_paths` list

### Secondary (MEDIUM confidence)

- `guides/related-data-and-reindexing.md` — Style/structure target for new guide (most recent guide; confirmed as canonical format)
- `guides/common-mistakes.md` — Wrong/correct example format precedent for footgun section
- `guides/phoenix-contexts.md` — Context-layer pattern that multitenancy guide must be consistent with
- Elixir 1.19.5 system install — `IO.warn/2` confirmed available and functional

### Tertiary (LOW confidence)

- `IO.warn/2` capture by `capture_io(:stderr, ...)` — assumed based on both targeting `:stderr` device; not directly verified in ExUnit context without running a test (see Open Questions #1)

---

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH — no new dependencies; all implementation targets are verified in source
- Architecture: HIGH — all four insertion points are confirmed from direct source inspection; pipeline types and ordering verified
- Guide structure: HIGH — all required sections locked in CONTEXT.md D-08 through D-13; style target confirmed from existing guides
- Pitfalls: HIGH for mechanical pitfalls (pipeline ordering, dedupe direction); MEDIUM for IO.warn capture behavior (one open question)
- Test patterns: HIGH — all existing test patterns confirmed from source

**Research date:** 2026-05-25
**Valid until:** 2026-06-25 (stable Elixir library; no fast-moving dependencies)
