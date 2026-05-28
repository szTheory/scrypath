# Composing real-app search

This guide shows how to reuse search defaults, expose honest metadata for host-rendered controls, and compose multi-search calls. The contract stays narrow: request-edge helpers normalize plain data, `Scrypath.Composition` lowers that data into `Scrypath.search/3` or `Scrypath.search_many/2`, and your context remains the application boundary.

If you have not normalized browser params yet, start with [Request-edge search](request-edge-search.md). If you want the first-hour setup instead, start with the [Golden path](golden-path.md).

## Why composition exists after request-edge normalization

`Scrypath.QueryParams` solves request-edge normalization. Composition solves a different problem: once several screens or callers share the same search defaults, where do those reusable rules live without turning Scrypath into a second runtime or a framework facade?

The answer is plain data:

- contexts or feature modules define presets and scopes as maps
- `Scrypath.Composition.compose/2` resolves `defaults` plus `fixed` constraints
- `Scrypath.Composition.to_search_args/1` lowers that result into `{text, keyword_opts}`
- your context still calls `Scrypath.search/3`

`Scrypath.Composition` does not execute search, move search ownership onto schemas, or replace Phoenix, controllers, LiveView, or your context boundary.

## Presets, scopes, `defaults`, and `fixed`

The public vocabulary is intentionally small:

- `defaults` fill in search-shaped values when the caller omitted them
- `fixed` locks filter-bearing fields and fails on conflicts
- `applied`, `defaulted`, `fixed`, and `unsupported` remain inspectable in the result

That keeps the seam useful for tests, logs, and honest host rendering without exposing `%Scrypath.Query{}` or inventing schema-generated runtime verbs.

```elixir
base_catalog =
  %{
    defaults: %{
      sort: [desc: :published_at],
      page: [size: 24],
      facets: [:category, :author]
    },
    fixed: %{
      filter: [published: true]
    }
  }

criteria = %{
  text: "ecto",
  facet_filter: [category: ["books"]]
}

{:ok, composition} = Scrypath.Composition.compose(base_catalog, criteria)
{text, search_opts} = Scrypath.Composition.to_search_args(composition)

MyApp.Catalog.search_books(text, search_opts)
```

## Metadata supports host-rendered honest controls

Composition is only half of the real-app seam. Hosts often need to know what the schema declares and what the current search input resolved to before they render controls.

Use:

- `Scrypath.schema_capabilities/1` for declaration-backed support
- `Scrypath.reflect_search/2` for resolved `applied`, `defaulted`, `fixed`, and `unsupported` state
- `Scrypath.reflect_search_many/2` for entry-scoped multi-search reflection

```elixir
capabilities = Scrypath.schema_capabilities(MyApp.Catalog.Book)

reflection =
  Scrypath.reflect_search(MyApp.Catalog.Book, %{
    text: "ecto",
    facets: [:category],
    facet_filter: [category: ["books"], region: ["eu"]]
  })
```

Those helpers return plain data for host rendering. They do not generate UI, claim tenant-safe authz, or promise related-data propagation or rebuild correctness. Those remain host-owned concerns.

## One runtime, two worked flows

Two real-app flows sit on top of the same runtime boundary:

### Single-schema catalog flow

Use one schema, one context-owned `Scrypath.search/3` call, and metadata-driven controls for a searchable Phoenix catalog page. Composition reduces repeated query glue, while `schema_capabilities/1` and `reflect_search/2` keep the control state inspectable and honest.

Read [Faceted search with Phoenix LiveView](faceted-search-with-phoenix-liveview.md) for the concrete single-schema example.

### Multi-schema global-search flow

Use `Scrypath.Composition.compose_many/2` when several schemas share some defaults but still need entry-scoped criteria, capabilities, and failure handling. The helper lowers into the existing tuple/shared-option contract for `Scrypath.search_many/2`; it does not create a merged capability graph or a fake universal ranking scale.

Read [Multi-index search](multi-index-search.md) for the concrete multi-schema example.

## `compose_many/2` lowers into `search_many/2`

Multi-search composition follows the same boundary discipline:

- per-entry composition is canonical
- shared composition lowers `defaults` only
- shared `fixed` is intentionally unsupported
- entry-scoped capability differences stay visible
- partial failures stay explicit

```elixir
{:ok, many} =
  Scrypath.Composition.compose_many(
    [
      %{
        schema: MyApp.Post,
        text: "release",
        fragments: [%{defaults: %{filter: [published: true]}}],
        criteria: %{facets: [:status]}
      },
      %{
        schema: MyApp.User,
        text: "release",
        criteria: %{filter: [active: true]}
      }
    ],
    shared: %{defaults: %{page: [size: 8]}}
  )

{entries, shared_opts} = Scrypath.Composition.to_search_many_args(many)

Scrypath.search_many(entries, Keyword.merge(shared_opts, repo: MyApp.Repo))
```

The output stays inspectable plain data all the way to the runtime call.

## Non-goals

This guide is also the boundary page for what the composition layer does not promise:

- no public `%Scrypath.Query{}`
- no schema-generated runtime verbs
- no generated UI widgets, forms, or components
- no tenant/authz guarantees
- no related-data propagation or rebuild correctness claims

Scrypath helps you compose search-shaped data and reflect honest state. Your app still owns policy, rendering, and operational follow-through.

## Continue

- [Faceted search with Phoenix LiveView](faceted-search-with-phoenix-liveview.md)
- [Multi-index search](multi-index-search.md)
- [JTBD and user flows](jtbd-and-user-flows.md)
