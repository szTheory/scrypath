# Guides

A short recommended reading order. The HexDocs sidebar lists every guide, grouped by job. If you read one page first, make it the [Golden path](golden-path.md).

## Recommended reading order

1. [Golden path](golden-path.md) — a linear first hour, from `mix.exs` to a working `Scrypath.search/3` with inline sync.
2. [JTBD and user flows](jtbd-and-user-flows.md) — Canonical mental model: the jobs Scrypath serves, the main flows, and what "success" honestly means in each one.
3. [Meilisearch concepts](meilisearch-concepts.md) — the Meilisearch nouns, the async task model, and the projection boundary Scrypath relies on.
4. [Request-edge search](request-edge-search.md) — browser params, `Scrypath.QueryParams`, optional `Scrypath.Phoenix`, and context-owned `Scrypath.search/3`.
5. [Composing real-app search](composing-real-app-search.md) — reusable `defaults`, `fixed` scopes, host-owned rendering, and `compose_many/2` lowering.
6. [Phoenix walkthrough](phoenix-walkthrough.md) — end-to-end adoption: schema, context, controller, LiveView.
7. [Sync modes and visibility](sync-modes-and-visibility.md) — inline, Oban, and manual sync, and what "done" means.
8. [Related data and reindexing](related-data-and-reindexing.md) — associated-data fan-out, and when to escalate to backfill or reindex.
9. [Drift recovery](drift-recovery.md) — the operator path when the database and search disagree or work is stuck.
10. [Common mistakes](common-mistakes.md) — evidence-led pitfalls, from symptom to fix.

The minimal runnable Phoenix example (Postgres, Meilisearch, and Oban) lives under [`examples/phoenix_meilisearch/`](https://github.com/szTheory/scrypath/blob/main/examples/phoenix_meilisearch/README.md). For a richer click-around showcase with a multi-tenant storefront, a mounted operator UI, Docker Compose, and realistic seeds, use [`examples/scrypath_ecommerce/`](https://github.com/szTheory/scrypath/blob/main/examples/scrypath_ecommerce/README.md).

For supported versions and install guidance, use [Support and compatibility](support-and-compatibility.md).
