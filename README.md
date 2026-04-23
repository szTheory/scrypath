# Scrypath

[![CI](https://github.com/szTheory/scrypath/actions/workflows/ci.yml/badge.svg)](https://github.com/szTheory/scrypath/actions/workflows/ci.yml) [![Hex.pm](https://img.shields.io/hexpm/v/scrypath.svg)](https://hex.pm/packages/scrypath) [![HexDocs](https://img.shields.io/badge/hex-docs-blue.svg)](https://hexdocs.pm/scrypath) [![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](https://hex.pm/packages/scrypath)

> Search indexing that feels native to Ecto.

Scrypath, the Ecto-native search indexing library, helps Phoenix and Ecto teams add Meilisearch-backed search without hiding the operational work that keeps search in sync.

Think Searchkick or `meilisearch-rails`, but for Phoenix & Ecto, with explicit sync semantics.

## Why Teams Use It

- declare searchable fields on the schema you already own
- keep search and sync inside your context boundary instead of scattering callbacks
- choose explicit sync behavior: `:inline`, `:manual`, or `:oban`
- get repo-backed, hydrated search results instead of raw backend hits only

## How It Works

```text
Ecto schema
  -> declare search metadata with `use Scrypath`
  -> write through your context
  -> sync to Meilisearch
  -> query through `Scrypath.search/3`
  -> get hydrated records back from your Repo
```

```elixir
defmodule MyApp.Blog.Post do
  use Ecto.Schema

  use Scrypath,
    fields: [:title, :body],
    filterable: [:status],
    sortable: [:inserted_at]
end
```

`use Scrypath` is metadata-only. Your app still owns persistence, sync calls, and failure handling.

## When It Fits

Scrypath is a good fit when you want search indexing that feels like part of your Ecto app, not a separate callback-heavy subsystem.

It is not a good fit if you want hidden model hooks, implicit repo access, Postgres full-text search, or a public multi-backend facade in v1.

## Get Started

Add Scrypath to your dependencies:

```elixir
def deps do
  [
    {:scrypath, "~> 0.3"}
  ]
end
```

Then read these in order:

- [Golden path](guides/golden-path.md) for the first working setup
- [Getting Started](guides/getting-started.md) for the mental model
- [Sync Modes and Visibility](guides/sync-modes-and-visibility.md) before choosing `:inline`, `:manual`, or `:oban`
- [Guides overview](guides/overview.md) for the rest of the published docs

For a runnable Phoenix consumer example, use `examples/phoenix_meilisearch/` in the repository checkout.

## Product Shape

- Meilisearch-first in v1
- internal backend seam, not a promised public abstraction
- explicit operational honesty: accepted work is not the same thing as search visibility
- optional Oban integration when you want queued sync

Read the published docs at [hexdocs.pm/scrypath](https://hexdocs.pm/scrypath).
