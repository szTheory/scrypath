# Phase 2: Meilisearch Core Sync - Pattern Map

**Mapped:** 2026-04-15
**Files analyzed:** 15
**Analogs found:** 12 / 15

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `mix.exs` | config | request-response | `mix.exs` | exact |
| `lib/scrypath.ex` | utility | request-response | `lib/scrypath.ex` | exact |
| `lib/scrypath/sync.ex` | service | request-response | `lib/scrypath/projection.ex` | flow-match |
| `lib/scrypath/identity.ex` | utility | transform | `lib/scrypath/projection.ex` | flow-match |
| `lib/scrypath/config.ex` | config | transform | `lib/scrypath/config.ex` | exact |
| `lib/scrypath/options.ex` | config | transform | `lib/scrypath/options.ex` | exact |
| `lib/scrypath/meilisearch.ex` | service | request-response | `test/support/fake_backend.ex` | role-match |
| `lib/scrypath/meilisearch/client.ex` | service | request-response | none | none |
| `lib/scrypath/meilisearch/tasks.ex` | service | request-response | none | none |
| `README.md` | config | request-response | `README.md` | exact |
| `ARCHITECTURE.md` | config | request-response | `ARCHITECTURE.md` | exact |
| `test/scrypath/sync_test.exs` | test | request-response | `test/scrypath/projection_test.exs` | role-match |
| `test/scrypath/identity_test.exs` | test | transform | `test/scrypath/projection_test.exs` | flow-match |
| `test/scrypath/meilisearch_test.exs` | test | request-response | `test/scrypath/backend_test.exs` | role-match |
| `test/scrypath/meilisearch/tasks_test.exs` | test | request-response | `test/scrypath/backend_test.exs` | role-match |

## Pattern Assignments

### `mix.exs` (config, request-response)

**Analog:** `mix.exs`

**Dependency and docs pattern** (`mix.exs:4`):
```elixir
def project do
  [
    app: :scrypath,
    version: "0.1.0",
    elixir: "~> 1.17",
    start_permanent: Mix.env() == :prod,
    deps: deps(),
    docs: docs(),
    package: package(),
    description: "Ecto-native search indexing and orchestration for Elixir apps"
  ]
end
```

**Minimal app footprint** (`mix.exs:17`):
```elixir
def application do
  [
    extra_applications: [:logger]
  ]
end
```

**Copy forward:** keep any Meilisearch transport and test dependencies narrow and list docs extras explicitly.

---

### `lib/scrypath.ex` (utility, request-response)

**Analog:** `lib/scrypath.ex`

**Public facade pattern** (`lib/scrypath.ex:22`):
```elixir
defmacro __using__(opts) do
  quote do
    use Scrypath.Schema, unquote(opts)
  end
end
```

**Small top-level helpers** (`lib/scrypath.ex:28`):
```elixir
@spec schema_config(module()) :: map()
def schema_config(schema_module) do
  schema_module.__scrypath__(:config)
end
```

**Copy forward:** add the common sync verbs here as thin delegates into `Scrypath.Sync` rather than embedding projection, identity, and backend logic directly in the facade.

---

### `lib/scrypath/sync.ex` (service, request-response)

**Analog:** `lib/scrypath/projection.ex`

**Imports and focused module shape** (`lib/scrypath/projection.ex:14`):
```elixir
alias Scrypath.Document
```

**Single public function dispatching to small helpers** (`lib/scrypath/projection.ex:16`):
```elixir
@spec document(module(), struct() | map()) :: Document.t()
def document(schema_module, source_record) do
  if function_exported?(schema_module, :search_document, 1) do
    build_custom_document(schema_module, source_record)
  else
    build_field_document(schema_module, source_record)
  end
end
```

**Input error pattern** (`lib/scrypath/projection.ex:68`):
```elixir
defp ensure_projection_map!(_projection) do
  raise ArgumentError, "search_document/1 must return a map"
end
```

**Copy forward:** keep sync orchestration as a narrow runtime module with public entrypoints and private helpers for config resolution, projection, identity resolution, and backend dispatch.

---

### `lib/scrypath/identity.ex` (utility, transform)

**Analog:** `lib/scrypath/projection.ex`

**Field fetch pattern** (`lib/scrypath/projection.ex:74`):
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

**Metadata-driven resolution pattern** (`lib/scrypath/projection.ex:56`):
```elixir
fields = schema_module.__scrypath__(:fields)
id_field = schema_module.__scrypath__(:document_id)
```

**Copy forward:** resolve delete ids from schema metadata first, then from a dedicated hook if Phase 2 adds one; keep failures as explicit `ArgumentError`s for invalid local input.

---

### `lib/scrypath/config.ex` (config, transform)

**Analog:** `lib/scrypath/config.ex`

**Canonical config resolution** (`lib/scrypath/config.ex:6`):
```elixir
@spec resolve!(keyword()) :: keyword()
def resolve!(opts) when is_list(opts) do
  Application.get_env(:scrypath, :defaults, [])
  |> Keyword.merge(opts)
  |> Options.validate_runtime_options!()
end
```

**Backend lookup pattern** (`lib/scrypath/config.ex:13`):
```elixir
@spec fetch_backend!(keyword()) :: module()
def fetch_backend!(config) do
  Keyword.fetch!(config, :backend)
end
```

**Copy forward:** Phase 2 config additions should still resolve explicit runtime options first and keep backend lookup centralized here.

---

### `lib/scrypath/options.ex` (config, transform)

**Analog:** `lib/scrypath/options.ex`

**Runtime option schema pattern** (`lib/scrypath/options.ex:37`):
```elixir
@runtime_options [
  backend: [
    type: {:custom, __MODULE__, :validate_backend, []},
    required: true,
    doc: "Backend module responsible for search operations."
  ],
  repo: [
    type: {:custom, __MODULE__, :validate_optional_module, []},
    default: nil,
    doc: "Optional Ecto repo used by runtime operations."
  ],
  index_prefix: [
    type: {:custom, __MODULE__, :validate_optional_string, []},
    default: nil,
    doc: "Optional runtime index prefix override."
  ],
  sync_mode: [
    type: {:in, [:inline, :manual, :oban]},
    default: :inline,
    doc: "Synchronization mode to use for write operations."
  ]
]
```

**Validation failure pattern** (`lib/scrypath/options.ex:83`):
```elixir
defp validate!(opts, schema) do
  case NimbleOptions.validate(opts, schema) do
    {:ok, validated} ->
      validated

    {:error, error} ->
      raise ArgumentError, Exception.message(error)
  end
end
```

**Copy forward:** extend runtime validation here for inline timeout and Meilisearch runtime config only when those options are part of the common contract.

---

### `lib/scrypath/meilisearch.ex` (service, request-response)

**Analog:** `test/support/fake_backend.ex`

**Backend behavior implementation pattern** (`test/support/fake_backend.ex:1`):
```elixir
defmodule Scrypath.TestSupport.FakeBackend do
  @behaviour Scrypath.Backend

  alias Scrypath.Document
```

**Backend callback shape** (`test/support/fake_backend.ex:9`):
```elixir
@impl true
def index_name(schema_module, config) do
  prefix = Keyword.get(config, :index_prefix, "scrypath")
  schema_name = schema_module |> Module.split() |> List.last() |> Macro.underscore()

  "#{prefix}_#{schema_name}"
end
```

**List-oriented write callbacks** (`test/support/fake_backend.ex:17`):
```elixir
@impl true
def upsert_documents(_schema_module, documents, _config) do
  {:ok, Enum.map(documents, &document_id/1)}
end

@impl true
def delete_documents(_schema_module, document_ids, _config) do
  {:ok, document_ids}
end
```

**Copy forward:** implement `Scrypath.Backend` directly, keep single and batch flows list-based, and leave task waiting to a separate helper module instead of bloating the backend wrapper.

---

### `README.md` (config, request-response)

**Analog:** `README.md`

**Product boundary phrasing** (`README.md:5`):
```markdown
## Product Boundary

Scrypath v1 publicly targets Meilisearch first. The backend seam is internal, and v1 does not promise public multi-backend parity.
```

**Operational honesty pattern** (`README.md:9`):
```markdown
Phase 1 defines the schema declaration contract, projection behavior, and runtime reflection helpers. Search execution, synchronization workflows, Oban integration, and managed reindex orchestration land in later phases.

Projection changes and backend-setting changes can require reindex work once indexing flows are in place. Scrypath treats that as a normal operational concern, not hidden magic.
```

**Roadmap update pattern** (`README.md:64`):
```markdown
## Roadmap

Phase 2 adds the Meilisearch-backed sync path for insert, update, delete, and manual workflows.
```

**Copy forward:** document explicit verbs, inline versus manual semantics, delete-id rules, and the fact that inline waits for terminal backend success without claiming DB/search atomicity.

---

### `ARCHITECTURE.md` (config, request-response)

**Analog:** `ARCHITECTURE.md`

**Public/internal boundary pattern** (`ARCHITECTURE.md:3`):
```markdown
## Public Surface

Phase 1 exposes three core modules:

- `Scrypath` for runtime reflection helpers
- `Scrypath.Schema` for the metadata declaration contract
- `Scrypath.Projection` for document projection rules
```

**Backend seam description** (`ARCHITECTURE.md:24`):
```markdown
## Internal Backend Seam

`Scrypath.Backend` is an internal behavior. It exists to preserve a path for future backend support without promising a public backend-agnostic extension surface in v1.
```

**Config honesty pattern** (`ARCHITECTURE.md:38`):
```markdown
`Scrypath.Config.resolve!/1` treats explicit runtime options as canonical input and only falls back to `Application.get_env(:scrypath, :defaults, [])` as convenience defaults.
```

**Copy forward:** extend this doc with the new sync flow, identity resolution point, and the limited `Scrypath.Meilisearch.*` escape hatch.

---

### `test/scrypath/sync_test.exs` (test, request-response)

**Analog:** `test/scrypath/projection_test.exs`

**Inline schema fixtures inside the test module** (`test/scrypath/projection_test.exs:4`):
```elixir
defmodule CustomSearchablePost do
  use Ecto.Schema

  use Scrypath,
    fields: [:title],
    filterable: [:status],
    sortable: [:inserted_at]
```

**Behavior-first assertions** (`test/scrypath/projection_test.exs:37`):
```elixir
test "projects declared fields by default" do
  document =
    Scrypath.Projection.document(SearchablePost, %SearchablePost{
      id: 123,
      title: "Hello",
      body: "World",
      status: "published"
    })
```

**Error assertion pattern** (`test/scrypath/projection_test.exs:73`):
```elixir
assert_raise ArgumentError, ~r/missing projected field :body/, fn ->
  Scrypath.Projection.document(MissingFieldSearchablePost, %MissingFieldSearchablePost{
    title: "Hello"
  })
end
```

**Copy forward:** keep sync API tests close to the public verbs and assert exact tuple contracts for inline success, manual acceptance, and invalid local input.

---

### `test/scrypath/identity_test.exs` (test, transform)

**Analog:** `test/scrypath/projection_test.exs`

**Fixture module pattern** (`test/scrypath/projection_test.exs:27`):
```elixir
defmodule MissingFieldSearchablePost do
  use Ecto.Schema

  use Scrypath, fields: [:title, :body]
```

**Transform assertion shape** (`test/scrypath/projection_test.exs:53`):
```elixir
test "uses search_document/1 when present" do
  document =
    Scrypath.Projection.document(CustomSearchablePost, %CustomSearchablePost{
      title: "Hello",
      status: "published"
    })
```

**Copy forward:** test default `document_id`, custom identity hook behavior if added, string-vs-atom key support, and failures without any repo reload step.

---

### `test/scrypath/meilisearch_test.exs` (test, request-response)

**Analog:** `test/scrypath/backend_test.exs`

**Shared app-env cleanup pattern** (`test/scrypath/backend_test.exs:7`):
```elixir
setup do
  original_defaults = Application.get_env(:scrypath, :defaults)

  on_exit(fn ->
    if original_defaults == nil do
      Application.delete_env(:scrypath, :defaults)
    else
      Application.put_env(:scrypath, :defaults, original_defaults)
    end
  end)

  :ok
end
```

**Contract-style assertions** (`test/scrypath/backend_test.exs:41`):
```elixir
test "fake backend satisfies the behaviour contract" do
  documents = [
    %Document{id: 1, data: %{title: "Hello"}, source: :fields},
    %Document{id: 2, data: %{title: "World"}, source: :custom}
  ]
```

**Copy forward:** test the concrete backend as a behavior implementation first, then layer in Meilisearch-specific result normalization and index naming expectations.

---

### `test/scrypath/meilisearch/tasks_test.exs` (test, request-response)

**Analog:** `test/scrypath/backend_test.exs`

**Config merge assertion pattern** (`test/scrypath/backend_test.exs:21`):
```elixir
test "Scrypath.Config.resolve! prefers explicit backend over app defaults" do
  Application.put_env(:scrypath, :defaults,
    backend: FakeBackend,
    index_prefix: "default",
    sync_mode: :manual
  )
```

**Copy forward:** keep task-waiting tests deterministic with stubbed responses and assert separate outcomes for accepted, succeeded, failed, and timeout paths.

---

## Shared Patterns

### Runtime Config
**Source:** `lib/scrypath/config.ex:6`
**Apply to:** `lib/scrypath.ex`, `lib/scrypath/sync.ex`, `lib/scrypath/meilisearch.ex`, tests that rely on app defaults
```elixir
@spec resolve!(keyword()) :: keyword()
def resolve!(opts) when is_list(opts) do
  Application.get_env(:scrypath, :defaults, [])
  |> Keyword.merge(opts)
  |> Options.validate_runtime_options!()
end
```

### Runtime Validation
**Source:** `lib/scrypath/options.ex:37`
**Apply to:** `lib/scrypath/options.ex`, any new sync-mode or Meilisearch runtime option contract
```elixir
@runtime_options [
  backend: [type: {:custom, __MODULE__, :validate_backend, []}, required: true],
  repo: [type: {:custom, __MODULE__, :validate_optional_module, []}, default: nil],
  index_prefix: [type: {:custom, __MODULE__, :validate_optional_string, []}, default: nil],
  sync_mode: [type: {:in, [:inline, :manual, :oban]}, default: :inline]
]
```

### Projection Before Backend Write
**Source:** `lib/scrypath/projection.ex:16`
**Apply to:** `lib/scrypath/sync.ex`, `test/scrypath/sync_test.exs`
```elixir
@spec document(module(), struct() | map()) :: Document.t()
def document(schema_module, source_record) do
  if function_exported?(schema_module, :search_document, 1) do
    build_custom_document(schema_module, source_record)
  else
    build_field_document(schema_module, source_record)
  end
end
```

### Backend Contract
**Source:** `lib/scrypath/backend.ex:6`
**Apply to:** `lib/scrypath/meilisearch.ex`, backend tests
```elixir
@callback name() :: atom()
@callback index_name(module(), keyword()) :: String.t()
@callback upsert_documents(module(), [Document.t()], keyword()) ::
            {:ok, term()} | {:error, term()}
@callback delete_documents(module(), [term()], keyword()) ::
            {:ok, term()} | {:error, term()}
```

### Test Harness
**Source:** `test/test_helper.exs:1`
**Apply to:** new support files and all new test modules
```elixir
ExUnit.start()

"test/support/**/*.ex"
|> Path.wildcard()
|> Enum.each(&Code.require_file/1)
```

## No Analog Found

Files with no close existing analog in the codebase:

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `lib/scrypath/meilisearch/client.ex` | service | request-response | No current HTTP client, transport boundary, or response normalization module exists in `lib/`. |
| `lib/scrypath/meilisearch/tasks.ex` | service | request-response | No current polling or async task state module exists. |
| `test/scrypath/meilisearch/client_test.exs` | test | request-response | No current transport-level test analog exists; planner should use research guidance plus local ExUnit style. |

## Metadata

**Analog search scope:** `mix.exs`, `README.md`, `ARCHITECTURE.md`, `lib/**/*.ex`, `test/**/*.exs`, `test/support/**/*.ex`
**Files scanned:** 13
**Pattern extraction date:** 2026-04-15
