# Scrypath

Scrypath, the Ecto-native search indexing library, helps Phoenix and Ecto teams declare searchable schemas without hiding the operational work that keeps search in sync.

## Product Boundary

Scrypath v1 publicly targets Meilisearch first. The backend seam is internal, and v1 does not promise public multi-backend parity.

Phase 1 defines the schema declaration contract, projection behavior, and runtime reflection helpers. Search execution, synchronization workflows, Oban integration, and managed reindex orchestration land in later phases.

Projection changes and backend-setting changes can require reindex work once indexing flows are in place. Scrypath treats that as a normal operational concern, not hidden magic.

## Schema Declaration

```elixir
defmodule MyApp.Post do
  use Ecto.Schema

  use Scrypath,
    fields: [:title, :body],
    filterable: [:status],
    sortable: [:inserted_at]

  schema "posts" do
    field :title, :string
    field :body, :string
    field :status, Ecto.Enum, values: [:draft, :published]
    timestamps()
  end
end
```

`use Scrypath` is metadata-only. It validates the declaration and exposes stable `__scrypath__/1` reflection keys without generating schema-specific runtime verbs.

## Projection

By default, Scrypath projects the exact field list declared in `fields: [...]` and uses the configured document id field, which defaults to `:id`.

When a schema defines `search_document/1`, that hook takes precedence over the declarative field list:

```elixir
def search_document(post) do
  %{
    id: "post:#{post.id}",
    title: post.title,
    excerpt: String.slice(post.body || "", 0, 140)
  }
end
```

Association-derived data requires explicit loading before projection. Scrypath does not preload relationships or reach through unloaded data implicitly.

## Runtime Reflection

Phase 1 exposes a small reflective surface for later sync and query code:

- `Scrypath.schema_config/1`
- `Scrypath.schema_fields/1`
- `Scrypath.document_source/1`
- `Scrypath.document_id_field/1`

These helpers are intended to keep runtime code centralized under `Scrypath.*` modules instead of generating APIs such as `Post.search/2`.

## Sync

Phase 2 adds explicit context-level sync verbs under `Scrypath`:

- `Scrypath.sync_record/3`
- `Scrypath.sync_records/3`
- `Scrypath.delete_record/3`
- `Scrypath.delete_document/3`
- `Scrypath.delete_documents/3`

Call sync after successful repo persistence. Inline sync improves immediacy, but it does not make database and search writes atomic.

```elixir
post =
  %Post{}
  |> Post.changeset(attrs)
  |> Repo.insert!()

{:ok, result} =
  Scrypath.sync_record(Post, post,
    backend: Scrypath.Meilisearch,
    sync_mode: :inline
  )

result.mode
# :inline
```

`sync_mode: :inline` waits for terminal backend success before returning `{:ok, result}`. The returned result still includes Meilisearch task metadata so the backend's asynchronous execution is visible.

```elixir
{:ok, result} =
  Scrypath.sync_record(Post, post,
    backend: Scrypath.Meilisearch,
    sync_mode: :inline
  )

result.status
# :completed
```

`sync_mode: :manual` uses the same verbs, but returns accepted work immediately for imports, migrations, and operator-controlled flows.

```elixir
{:ok, result} =
  Scrypath.sync_records(Post, posts,
    backend: Scrypath.Meilisearch,
    sync_mode: :manual
  )

result.mode
# :manual

result.status
# :accepted
```

Delete flows use the schema's configured document id by default. When a record needs a different stable delete identity, define `search_document_id/1`. Use `Scrypath.delete_document/3` or `Scrypath.delete_documents/3` when no source struct is available.

```elixir
def search_document_id(post), do: "post:#{post.legacy_id}"
```

```elixir
{:ok, _result} =
  Scrypath.delete_document(Post, "post:123",
    backend: Scrypath.Meilisearch,
    sync_mode: :manual
  )
```

Common sync examples should stay explicit in your Ecto contexts rather than hidden behind callbacks or transaction hooks.

## Roadmap

Phase 1 establishes the declaration and projection contracts.

Phase 2 adds the Meilisearch-backed sync path for insert, update, delete, and manual workflows.

Phase 3 adds the search API, filtering, sorting, pagination, and hydration.

Phase 4 adds Oban-backed synchronization and Telemetry instrumentation.

Phase 5 adds reindex and operator workflows.

Phase 6 adds Phoenix-focused guides and release polish.
