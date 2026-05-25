# Phase 92: Guide and Schema Declaration — Pattern Map

**Mapped:** 2026-05-25
**Files analyzed:** 8 (5 modified, 1 new Elixir guide, 2 test files with additions)
**Analogs found:** 8 / 8

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/scrypath/options.ex` | utility/compiler | transform | `lib/scrypath/options.ex` (fan_outs:, dedupe_preserve_order, IO.puts advisory) | self (surgical insertion) |
| `lib/scrypath/schema.ex` | macro/config | transform | `lib/scrypath/schema.ex` (existing `__scrypath__/1` accessors) | self (surgical insertion) |
| `lib/scrypath/projection.ex` | service | request-response | `lib/scrypath/projection.ex` (build_custom_document/2) | self (surgical insertion) |
| `guides/multitenancy.md` | documentation | — | `guides/related-data-and-reindexing.md` + `guides/common-mistakes.md` | role-match (style/structure) |
| `mix.exs` | config | — | `mix.exs` (existing extras:/groups_for_extras) | self (surgical insertion) |
| `test/scrypath/options_test.exs` | test | — | `test/scrypath/options_test.exs` (capture_io :stderr tests, lines 335–380) | self (new describe block) |
| `test/scrypath/schema_test.exs` | test | — | `test/scrypath/schema_test.exs` (Code.compile_string + __scrypath__ assertion) | self (new tests in describe) |
| `test/scrypath/projection_test.exs` | test | — | `test/scrypath/projection_test.exs` (CustomSearchablePost pattern) | self (new defmodule + tests) |

---

## Pattern Assignments

### `lib/scrypath/options.ex` — `tenant_field:` option + normalization pass

**Analog:** self — `fan_outs:` option addition (lines 41–45) and `dedupe_preserve_order/1` (lines 1137–1148) and `IO.puts` advisory (lines 665–670, 771–776)

**Step 1 — Add `tenant_field:` to `@schema_options`** (insert after `backend:`, lines 41–51):
```elixir
# In @schema_options keyword list — copy fan_outs: pattern for custom validator type
tenant_field: [
  type: {:custom, __MODULE__, :validate_tenant_field, []},
  default: nil,
  doc: "Optional tenant field name auto-injected into both filterable: and fields: for shared-index multitenancy."
]
```

**Step 2 — Add validator function** (alongside existing `validate_fan_outs`, `validate_backend`, etc.):
```elixir
@doc false
def validate_tenant_field(nil), do: {:ok, nil}
def validate_tenant_field(value) when is_atom(value), do: {:ok, value}
def validate_tenant_field(_), do: {:error, "tenant_field must be an atom or nil"}
```

**Step 3 — Insert normalization pass into `validate_schema_options!/1` pipeline** (lines 417–424):

Current pipeline (line 417–424):
```elixir
@spec validate_schema_options!(keyword()) :: map()
def validate_schema_options!(opts) do
  opts
  |> validate!(@schema_options)
  |> ensure_non_empty_fields!()
  |> validate_faceting_rules!()
  |> Map.put(:document_source, :fields)
end
```

New pipeline — insert `normalize_tenant_field!/1` AFTER `validate_faceting_rules!` (receives map, returns map):
```elixir
@spec validate_schema_options!(keyword()) :: map()
def validate_schema_options!(opts) do
  opts
  |> validate!(@schema_options)
  |> ensure_non_empty_fields!()
  |> validate_faceting_rules!()
  |> normalize_tenant_field!()
  |> Map.put(:document_source, :fields)
end
```

**Step 4 — Add `normalize_tenant_field!/1` private function** (follows same guard-clause style as `validate_faceting_rules!`):
```elixir
defp normalize_tenant_field!(%{tenant_field: nil} = m), do: m

defp normalize_tenant_field!(%{tenant_field: field} = m) when is_atom(field) do
  existing_fields = Map.fetch!(m, :fields)
  new_fields = dedupe_preserve_order(existing_fields ++ [field])

  unless field in existing_fields do
    IO.warn(
      "[scrypath] tenant_field #{inspect(field)} is not listed in fields:. " <>
        "It has been auto-added so search documents include the tenant value. " <>
        "To silence this warning, add #{inspect(field)} to fields: explicitly.",
      []
    )
  end

  new_filterable = dedupe_preserve_order(Map.fetch!(m, :filterable) ++ [field])

  %{m | fields: new_fields, filterable: new_filterable}
end
```

**IO.warn advisory pattern** (from lines 665–670 — existing IO.puts advisory, same structure but new code uses `IO.warn/2`):
```elixir
# Existing (IO.puts — do NOT change):
IO.puts(
  :stderr,
  "[scrypath] a schema declared settings using camelCase keys. ..."
)

# New pattern for tenant_field (IO.warn/2 per D-02):
IO.warn(
  "[scrypath] tenant_field #{inspect(field)} is not listed in fields:. ...",
  []
)
```

**`dedupe_preserve_order/1` helper** (lines 1137–1148 — reuse as-is, do not copy):
```elixir
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
Note: Use `existing_list ++ [field]` (append) so auto-injected tenant field appears last, not first.

---

### `lib/scrypath/schema.ex` — `__scrypath__(:tenant_field)` accessor

**Analog:** self — existing accessor block (lines 32–44)

**Accessor pattern** (lines 32–44 — add new `def __scrypath__(:tenant_field)` alongside the existing ones):
```elixir
# Existing accessors to copy pattern from:
def __scrypath__(:config), do: @scrypath_config
def __scrypath__(:fields), do: @scrypath_config.fields
def __scrypath__(:filterable), do: @scrypath_config.filterable
def __scrypath__(:faceting), do: @scrypath_config.faceting
def __scrypath__(:sortable), do: @scrypath_config.sortable
def __scrypath__(:settings), do: @scrypath_config.settings
def __scrypath__(:document_id), do: @scrypath_config.document_id
def __scrypath__(:document_source), do: @scrypath_config.document_source
def __scrypath__(:backend), do: @scrypath_config.backend

# New accessor (same pattern):
def __scrypath__(:tenant_field), do: @scrypath_config.tenant_field
```

**`@moduledoc` key list** (lines 8–20 — add `:tenant_field` to the bullet list of `__scrypath__/1` keys):
```elixir
# Add to the bullet list:
# - `:tenant_field`
```

**Full `__using__` macro context** (lines 25–46 — for placement reference):
```elixir
defmacro __using__(opts) do
  config = Options.validate_schema_options!(opts)

  quote bind_quoted: [config: Macro.escape(config)] do
    Module.register_attribute(__MODULE__, :scrypath_config, persist: true)
    @scrypath_config config

    def __scrypath__(:config), do: @scrypath_config
    # ... (all existing accessors) ...
    # INSERT def __scrypath__(:tenant_field) HERE, before the catch-all
    def __scrypath__(key) do
      raise ArgumentError, "unknown Scrypath metadata key: #{inspect(key)}"
    end
  end
end
```

---

### `lib/scrypath/projection.ex` — post-hook tenant field merge

**Analog:** self — `build_custom_document/2` (lines 30–54) and `fetch_field!/2` (lines 74–85)

**`build_custom_document/2` current implementation** (lines 30–54 — add `maybe_inject_tenant_field/3` call before `%Document{...}` struct construction):
```elixir
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

  # NEW: insert this line before %Document{...}
  data = maybe_inject_tenant_field(schema_module, source_record, data)

  %Document{id: id, data: data, source: :custom}
end
```

**New `maybe_inject_tenant_field/3` private function** (add after `build_custom_document/2`):
```elixir
defp maybe_inject_tenant_field(schema_module, source_record, data) do
  case schema_module.__scrypath__(:tenant_field) do
    nil ->
      data

    field ->
      # Idempotent: check both atom and string key forms (matches fetch_field!/2 dual-key pattern)
      if Map.has_key?(data, field) or Map.has_key?(data, Atom.to_string(field)) do
        data
      else
        Map.put(data, field, fetch_field!(source_record, field))
      end
  end
end
```

**`fetch_field!/2` helper** (lines 74–85 — reuse as-is for pulling tenant value from source record):
```elixir
defp fetch_field!(source_record, field) when is_map(source_record) do
  cond do
    Map.has_key?(source_record, field) ->
      Map.fetch!(source_record, field)

    Map.has_key?(source_record, Atom.to_string(field)) ->
      Map.fetch!(source_record, Atom.to_string(field))

    true ->
      raise ArgumentError, "missing projected field #{inspect(field)} in source record"
  end
end
```

---

### `guides/multitenancy.md` — canonical multitenancy guide (new file)

**Analog:** `guides/related-data-and-reindexing.md` (style/structure/tone target — most recent guide)
**Secondary analog:** `guides/common-mistakes.md` (wrong/correct example format)

**Top-level structure from `related-data-and-reindexing.md`** (lines 1–5):
```markdown
# [Title without "Guide" in the name]

[Opening paragraph — one or two sentences framing the problem this guide solves]

[Short "If you remember one sentence" or equivalent anchor sentence]
```

**Wrong/correct block format from `guides/common-mistakes.md`** (lines 9–19):
```markdown
## [Symptom or pattern name]

**Symptom:** ...

**Wrong model:** ...

**Fix pattern:** ...

**Authority:** See [guide name](guide.md) for the authoritative semantics.
```

For the footgun section use D-10 format (from CONTEXT.md):
```markdown
## ❌ Wrong — tenant filter silently dropped

```elixir
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
```

## ✅ Correct — explicit AND-combination

```elixir
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
```

**Required sections (D-12) in order:**
1. Overview of shared-index model + why per-tenant indexes are not the default
2. Correct context-layer pattern with explicit tenant parameter (D-11: never extract from conn/assigns)
3. Filter merge order footgun (wrong/correct — D-10)
4. Meilisearch tenant token guidance (browser-direct only, link to Joken docs)
5. `search_document/1` custom hook edge case — show example where hook forgets tenant field, explain post-hook merge guarantee
6. Schema declaration example (`use Scrypath` with `tenant_field:`)

---

### `mix.exs` — ExDoc registration

**Analog:** self — `extras:` list (lines 140–169) and `groups_for_extras` (lines 171–183)

**`extras:` insertion point** (after `"guides/related-data-and-reindexing.md"` on line 154):
```elixir
extras: [
  # ... existing entries ...
  "guides/related-data-and-reindexing.md",
  "guides/multitenancy.md",      # ← insert here
  "guides/meilisearch-operations.md",
  # ...
]
```

**`groups_for_extras` Getting Started group** (after `"guides/related-data-and-reindexing.md"` on line 182):
```elixir
"Getting Started": [
  "README.md",
  "guides/overview.md",
  "guides/jtbd-and-user-flows.md",
  "guides/getting-started.md",
  "guides/golden-path.md",
  "guides/support-and-compatibility.md",
  "guides/outside-adopter-intake.md",
  "guides/request-edge-search.md",
  "guides/composing-real-app-search.md",
  "guides/related-data-and-reindexing.md",
  "guides/multitenancy.md",      # ← insert here (after related-data, before common-mistakes)
  "guides/common-mistakes.md"
],
```

---

### `test/scrypath/options_test.exs` — tenant_field: tests

**Analog:** self — `capture_io(:stderr, ...)` tests (lines 335–380) and `Code.compile_string` pattern (lines 411–433)

**capture_io pattern for IO.warn advisory** (lines 335–344):
```elixir
test "warns when ranking_rules omits Meilisearch defaults (O)" do
  input = %{ranking_rules: [:typo, :proximity, :attribute, :sort, :exactness]}

  err =
    capture_io(:stderr, fn ->
      assert {:ok, _} = Options.validate_settings(input)
    end)

  assert err =~ "ranking_rules is missing the following Meilisearch default"
  assert err =~ "words"
end
```

Adapt to tenant_field advisory test (wrap `Code.compile_string` in `capture_io(:stderr, ...)`):
```elixir
test "warns when tenant_field not in fields: (tenant_field-A)" do
  err =
    capture_io(:stderr, fn ->
      Code.compile_string("""
      defmodule TenantFieldAutoInjectWarns do
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

**No-warn (idempotent) pattern** (lines 371–380):
```elixir
test "does not emit stderr on canonical snake_case happy path (R)" do
  err =
    capture_io(:stderr, fn ->
      assert {:ok, _} = Options.validate_settings(%{synonyms: [["nyc", "new york"]]})
    end)

  assert err == ""
end
```

Adapt to no-warn test when field already in `fields:`:
```elixir
test "no warn when tenant_field already in fields: (tenant_field-B)" do
  err =
    capture_io(:stderr, fn ->
      Code.compile_string("""
      defmodule TenantFieldIdempotentNoWarn do
        use Ecto.Schema
        use Scrypath, fields: [:title, :tenant_id], tenant_field: :tenant_id

        embedded_schema do
          field :title, :string
          field :tenant_id, :integer
        end
      end
      """)
    end)

  assert err == ""
end
```

**`Code.compile_string` with result binding** (lines 411–433 — for tests that assert on the compiled module's config):
```elixir
[{mod, _}] =
  Code.compile_string("""
  defmodule TenantFieldAutoInjectFields do
    use Ecto.Schema
    use Scrypath, fields: [:title], tenant_field: :tenant_id

    embedded_schema do
      field :title, :string
      field :tenant_id, :integer
    end
  end
  """)

assert :tenant_id in mod.__scrypath__(:fields)
assert :tenant_id in mod.__scrypath__(:filterable)
```

---

### `test/scrypath/schema_test.exs` — `__scrypath__(:tenant_field)` tests

**Analog:** self — `__scrypath__/1` describe block (lines 4–97)

**Pattern for existing accessor assertions** (lines 5–27):
```elixir
describe "__scrypath__/1" do
  test "returns normalized schema metadata" do
    assert SearchablePost.__scrypath__(:config) == %{
             fields: [:title, :body],
             filterable: [:status],
             # ...
           }

    assert SearchablePost.__scrypath__(:fields) == [:title, :body]
  end
end
```

**New tests follow same pattern — add to existing `describe "__scrypath__/1"` block:**
- `assert SomeSchemaWithTenantField.__scrypath__(:tenant_field) == :tenant_id`
- `assert SearchablePost.__scrypath__(:tenant_field) == nil` (existing schema without tenant_field)
- Note: `SearchablePost` config map assertions (line 6–17) will need `:tenant_field` key added when `@schema_options` default: nil is in place

**`Code.compile_string` with module-level `use Scrypath`** (lines 54–96 for compile-error tests — same pattern for testing that new option is rejected when wrong type):
```elixir
test "rejects unknown declaration options" do
  assert_raise ArgumentError, ~r/unknown options/, fn ->
    Code.compile_string("""
    defmodule InvalidSearchablePostUnknown do
      use Ecto.Schema
      use Scrypath, fields: [:title], mystery: true
      embedded_schema do
        field :title, :string
      end
    end
    """)
  end
end
```

---

### `test/scrypath/projection_test.exs` — post-hook merge tests

**Analog:** self — `CustomSearchablePost` defmodule + tests (lines 4–65)

**In-test module definition pattern** (lines 4–25):
```elixir
defmodule CustomSearchablePost do
  use Ecto.Schema

  use Scrypath,
    fields: [:title],
    filterable: [:status],
    sortable: [:inserted_at]

  embedded_schema do
    field(:title, :string)
    field(:status, :string)
    field(:inserted_at, :utc_datetime)
  end

  def search_document(post) do
    %{
      id: "post:#{post.title}",
      title: String.upcase(post.title),
      summary: "#{post.status}-summary"
    }
  end
end
```

New test module should follow same shape — add `tenant_field:` option and a `search_document/1` that omits the tenant field:
```elixir
defmodule TenantFieldCustomPost do
  use Ecto.Schema

  use Scrypath,
    fields: [:title, :tenant_id],
    tenant_field: :tenant_id

  embedded_schema do
    field(:title, :string)
    field(:tenant_id, :integer)
  end

  def search_document(post) do
    %{title: String.upcase(post.title)}   # intentionally omits :tenant_id
  end
end
```

**Test assertion pattern** (lines 53–65):
```elixir
test "uses search_document/1 when present" do
  document =
    Scrypath.Projection.document(CustomSearchablePost, %CustomSearchablePost{
      title: "Hello",
      status: "published"
    })

  assert document == %Scrypath.Document{
           id: "post:Hello",
           data: %{title: "HELLO", summary: "published-summary"},
           source: :custom
         }
end
```

New test should assert tenant field is injected even when `search_document/1` omits it:
```elixir
test "post-hook injects tenant_field when search_document/1 omits it" do
  document =
    Scrypath.Projection.document(TenantFieldCustomPost, %TenantFieldCustomPost{
      id: 1,
      title: "Hello",
      tenant_id: 42
    })

  assert document.data.tenant_id == 42
  assert document.data.title == "HELLO"
  assert document.source == :custom
end
```

---

### `test/scrypath/docs_contract_test.exs` — guide anchor + ExDoc registration tests

**Analog:** self — `@guide_paths` list (lines 33–56) and guide anchor test pattern (lines 74–78)

**`@guide_paths` list pattern** (lines 33–56 — add `"guides/multitenancy.md"` to `@guide_paths`):
```elixir
@guide_paths [
  # ... existing paths ...
  "guides/related-data-and-reindexing.md",
  "guides/multitenancy.md"   # ← add here
]
```

**Guide anchor test pattern** (lines 74–78):
```elixir
test "per-query tuning pipeline guide spine anchors" do
  assert String.contains?(@per_query_tuning_pipeline, "## Two-plane model and precedence")
  assert String.contains?(@per_query_tuning_pipeline, "## Implementation readiness checklist")
  assert String.contains?(@per_query_tuning_pipeline, "## Telemetry catalog")
end
```

New anchor test for multitenancy guide:
```elixir
@multitenancy_guide File.read!("guides/multitenancy.md")

test "multitenancy guide contains required section anchors (TNNT-01)" do
  assert String.contains?(@multitenancy_guide, "shared-index")
  assert String.contains?(@multitenancy_guide, "Keyword.merge")
  assert String.contains?(@multitenancy_guide, "tenant token")
  assert String.contains?(@multitenancy_guide, "search_document")
  assert String.contains?(@multitenancy_guide, "tenant_field")
end
```

ExDoc registration test — assert `mix.exs` contains the new entry:
```elixir
@mix_exs File.read!("mix.exs")

test "multitenancy guide is registered in ExDoc extras and Getting Started group (TNNT-01)" do
  assert String.contains?(@mix_exs, ~s("guides/multitenancy.md"))
end
```

---

## Shared Patterns

### Compile-time `IO.warn/2` Advisory
**Source:** `lib/scrypath/options.ex` lines 665–670 and 771–776 (existing `IO.puts` format — new code upgrades to `IO.warn/2` per D-02)
**Apply to:** `normalize_tenant_field!/1` in `options.ex` only

Pattern: `[scrypath] {key} {description}. {action}. To silence, {explicit fix}.`

```elixir
# New IO.warn form (D-02):
IO.warn(
  "[scrypath] tenant_field #{inspect(field)} is not listed in fields:. " <>
    "It has been auto-added so search documents include the tenant value. " <>
    "To silence this warning, add #{inspect(field)} to fields: explicitly.",
  []
)

# Existing IO.puts form (do NOT change existing advisories):
IO.puts(
  :stderr,
  "[scrypath] a schema declared settings using camelCase keys. ..."
)
```

### `dedupe_preserve_order/1` Reuse
**Source:** `lib/scrypath/options.ex` lines 1137–1148
**Apply to:** `normalize_tenant_field!/1` — call directly as a private function
**Key detail:** Use `existing_list ++ [field]` to append (tenant field appears last); `[field | existing_list]` would prepend (tenant field first). Both deduplicate correctly, but append is least-surprise.

### `__scrypath__/1` Catch-all Guard
**Source:** `lib/scrypath/schema.ex` lines 42–44
**Apply to:** New `:tenant_field` accessor must be inserted BEFORE the catch-all raise, not after it:
```elixir
# New accessor before catch-all:
def __scrypath__(:tenant_field), do: @scrypath_config.tenant_field

# Existing catch-all (must remain last):
def __scrypath__(key) do
  raise ArgumentError, "unknown Scrypath metadata key: #{inspect(key)}"
end
```

### `fetch_field!/2` Dual-Key Pattern
**Source:** `lib/scrypath/projection.ex` lines 74–85
**Apply to:** `maybe_inject_tenant_field/3` — check `Map.has_key?(data, field) or Map.has_key?(data, Atom.to_string(field))` to mirror the dual-key check used in `fetch_field!/2`. This prevents double-injection when `search_document/1` returns string-keyed maps.

### `capture_io(:stderr, ...)` Test Pattern
**Source:** `test/scrypath/options_test.exs` lines 335–380
**Apply to:** `options_test.exs` new tests for `IO.warn` advisory
**Note on A1 from RESEARCH.md:** `IO.warn/2` routes to `:stderr`; assume `capture_io(:stderr, ...)` captures it (same device). If capture fails, fall back to `capture_log/1` or wrap `Code.compile_string` directly. Confirm with first test run.

### `Code.compile_string` In-Test Module Pattern
**Source:** `test/scrypath/options_test.exs` lines 409–433 and `test/scrypath/schema_test.exs` lines 53–96
**Apply to:** All compile-time behavior tests (`tenant_field:` auto-injection, advisory emission, accessor reflection)
**Key detail:** Bind result as `[{mod, _}] = Code.compile_string(...)` when the test needs to call `mod.__scrypath__/1` on the compiled module.

---

## No Analog Found

No files in this phase lack a codebase analog. All insertion points are in existing files with directly applicable patterns.

---

## Metadata

**Analog search scope:** `lib/scrypath/`, `guides/`, `test/scrypath/`, `mix.exs`
**Files scanned:** 8 source files read directly
**Pattern extraction date:** 2026-05-25
