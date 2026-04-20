# Guides

Short map of published guides. Start with the [Golden path](golden-path.md) for a linear first-hour setup, or [Getting Started](getting-started.md) for concepts first.

| Guide | Purpose |
| ----- | ------- |
| [Getting started](getting-started.md) | Mental model: what you configure, where sync and search live in the app. |
| [Golden path](golden-path.md) | Checklist from `mix.exs` through first `Scrypath.search/3` with **inline** sync. |
| [Meilisearch operations](meilisearch-operations.md) | Where Meilisearch runs, provisioning sketches, recovery paths, and footguns—through a Scrypath lens. |
| [Phoenix walkthrough](phoenix-walkthrough.md) | End-to-end Phoenix adoption: schema → context → controller → LiveView. |
| [Phoenix contexts](phoenix-contexts.md) | Context-owned search and sync boundaries. |
| [Phoenix controllers and JSON](phoenix-controllers-and-json.md) | JSON APIs and thin controller callers. |
| [Phoenix LiveView](phoenix-liveview.md) | LiveView calling `Scrypath.search/3` and related patterns. |
| [Faceted search with Phoenix LiveView](faceted-search-with-phoenix-liveview.md) | Facets, filters, and catalog-style UIs. |
| [Multi-index search](multi-index-search.md) | Federated / multi-index queries. |
| [Sync modes and visibility](sync-modes-and-visibility.md) | Inline, Oban, and manual sync semantics and what “done” means. |
| [Operator Mix tasks](operator-mix-tasks.md) | CLI entrypoints over `Scrypath.*` operator APIs. |
| [Drift recovery](drift-recovery.md) | Operator path when DB and search disagree or work is stuck. |
| [Relevance tuning](relevance-tuning.md) | Meilisearch settings, verification, and tuning from schema declarations. |
| [Per-query tuning pipeline](per-query-tuning-pipeline.md) | Request-time Meilisearch search parameters vs index-time settings — canonical merge and mapping spec. |

The runnable Phoenix example (Postgres + Meilisearch + Oban) lives under [`examples/phoenix_meilisearch/`](../examples/phoenix_meilisearch/README.md).
