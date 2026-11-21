<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/szTheory/scrypath/8beb3ed0f6f0b59f62df28ac60349c6dc9adf1a1/brand/assets/readme/scrypath-header-dark.svg">
    <img src="https://raw.githubusercontent.com/szTheory/scrypath/8beb3ed0f6f0b59f62df28ac60349c6dc9adf1a1/brand/assets/readme/scrypath-header-light.svg" alt="scrypath" width="260">
  </picture>
</p>

[![CI](https://github.com/szTheory/scrypath/actions/workflows/ci.yml/badge.svg)](https://github.com/szTheory/scrypath/actions/workflows/ci.yml) [![Hex.pm](https://img.shields.io/hexpm/v/scrypath.svg)](https://hex.pm/packages/scrypath) [![HexDocs](https://img.shields.io/badge/hex-docs-blue.svg)](https://hexdocs.pm/scrypath) [![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](https://github.com/szTheory/scrypath/blob/main/LICENSE)

Scrypath, the Ecto-native search indexing library, helps Phoenix and Ecto teams add search to existing schemas without hiding the operational work that keeps search in sync.

Scrypath needs a running Meilisearch server; the repository's examples use the `getmeili/meilisearch:v1.15` image on `http://127.0.0.1:7700`. Meilisearch is eventually consistent, so a record can take a moment to show up in search after you save it.

Public website: [sztheory.github.io/scrypath](https://sztheory.github.io/scrypath/)

## When Scrypath Fits

Scrypath is a good fit when you want:

- search indexing that feels native to Ecto instead of bolted onto a controller or callback maze
- one explicit place to choose between inline, manual, and Oban-backed sync
- repo-backed record loading through the common `Scrypath.search/3` path
- first-class backfill and managed reindex workflows when drift or schema changes happen

## When It Does Not

Scrypath is not trying to be:

- a Postgres full-text abstraction
- a Phoenix-only library
- a public multi-backend facade in v1
- a callback-heavy runtime that hides when search is out of date

If you want hidden model hooks, implicit repo access, or a library that pretends accepted work means immediate search visibility, this is the wrong tool.

Scrypath is Meilisearch-first in v1. Its backend seam is internal, not a promised public abstraction, and v1 does not promise public multi-backend parity.

## Installation

Add Scrypath to your dependencies:

```elixir
def deps do
  [
    {:scrypath, "~> 0.3"}
  ]
end
```

Scrypath owns its internal transport dependency; configure backend and sync behavior in your app instead of pinning `Req` in the base install path. Add Oban only when you choose `sync_mode: :oban`.

Scrypath follows semantic versioning for its public API, and the [changelog](https://github.com/szTheory/scrypath/blob/main/CHANGELOG.md) says what each release changed. The optional operator UI lives in the source checkout and is not part of the Hex package.

## Quick Path

Start a Meilisearch server first; these steps assume it answers on `http://127.0.0.1:7700`. Because Meilisearch is eventually consistent, a new record can take a moment to show up in search. The [golden path](https://hexdocs.pm/scrypath/golden-path.html) covers each step in full.

Declare the searchable fields on your Ecto schema. `use Scrypath` only declares metadata; persistence and sync stay in your context:

```elixir
defmodule MyApp.Blog.Post do
  use Ecto.Schema

  use Scrypath,
    fields: [:title, :body],
    filterable: [:status],
    sortable: [:inserted_at]

  schema "posts" do
    field :title, :string
    field :body, :string
    field :status, :string
    timestamps()
  end
end
```

Point Scrypath at Meilisearch in `config/runtime.exs`:

```elixir
import Config

config :scrypath, :defaults,
  backend: Scrypath.Meilisearch,
  meilisearch_url: System.get_env("SCRYPATH_MEILISEARCH_URL") || "http://127.0.0.1:7700",
  repo: MyApp.Repo
```

After a successful repo write, sync the record:

```elixir
{:ok, post} =
  MyApp.Repo.insert(%MyApp.Blog.Post{title: "Ecto search", body: "Hello", status: "published"})

{:ok, _sync} = Scrypath.sync_record(MyApp.Blog.Post, post, sync_mode: :inline)
```

Choose **`:inline`** for the first-hour path, **`:oban`** when durable enqueue and worker throughput matter, or **`:manual`** for imports and operator-controlled follow-up. A successful [`Scrypath.sync_record/3`](https://hexdocs.pm/scrypath/Scrypath.html#sync_record/3) return means work was accepted or, when inline waiting applies, completed. Neither makes the database and search writes atomic, and accepted work may not yet be visible in search. See [sync modes and visibility](https://hexdocs.pm/scrypath/sync-modes-and-visibility.html) for the exact return contract, lifecycle, and recovery guidance.

Then search. `result.records` holds the matching rows, loaded through your repo:

```elixir
{:ok, result} = Scrypath.search(MyApp.Blog.Post, "ecto", page: [size: 10])
result.records
```

## Next Steps

- Continue with the [golden path](https://hexdocs.pm/scrypath/golden-path.html) for a context module and an IEx check.
- [Support and compatibility](https://hexdocs.pm/scrypath/support-and-compatibility.html) covers release-backed guidance and supported versions; main may contain unreleased changes. Scope reopens only for a concrete production bug, reviewed outside-adopter evidence, or a deliberate strategic product decision.
- The [guides overview](https://hexdocs.pm/scrypath/overview.html) indexes every guide, from sync modes to drift recovery.
