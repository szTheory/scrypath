<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="brandbook/assets/logo-primary-inverse.svg">
    <img alt="scrypath — Ecto-native search indexing" src="brandbook/assets/logo-primary.svg" width="300">
  </picture>
</p>

[![CI](https://github.com/szTheory/scrypath/actions/workflows/ci.yml/badge.svg)](https://github.com/szTheory/scrypath/actions/workflows/ci.yml) [![Hex.pm](https://img.shields.io/hexpm/v/scrypath.svg)](https://hex.pm/packages/scrypath) [![HexDocs](https://img.shields.io/badge/hex-docs-blue.svg)](https://hexdocs.pm/scrypath) [![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](https://github.com/szTheory/scrypath/blob/main/LICENSE)

Scrypath, the Ecto-native search indexing library, helps Phoenix and Ecto teams add search to existing schemas without hiding the operational work that keeps search in sync.

Public website: [sztheory.github.io/scrypath](https://sztheory.github.io/scrypath/)

## Installation

Add Scrypath to your dependencies:

```elixir
def deps do
  [
    {:scrypath, "~> 0.3"}
  ]
end
```

**Start here:** for the canonical first-hour path from dependencies through a working `Scrypath.search/3` with inline sync, follow [guides/golden-path.md](guides/golden-path.md).

**Support and readiness:** for supported Elixir, OTP, Meilisearch, sync modes, and the verification commands behind those claims, use [guides/support-and-compatibility.md](guides/support-and-compatibility.md).
The fast local support check is <code>mix verify.adopter</code>; the live Phoenix + Meilisearch check is <code>mix verify.adopter --live</code>.
That guide is the release-backed guidance authority; main may contain unreleased changes.
This README stays route-first and does not duplicate compatibility tuple values.

**Outside integrations and evidence:** if you are trying Scrypath in a real app and something fails or feels unclear, read [guides/outside-adopter-intake.md](guides/outside-adopter-intake.md).

**Scope and reopen policy:** scope reopens only for a **concrete production bug**, **reviewed outside-adopter evidence**, or a **deliberate strategic product decision**. The canonical policy owner is [guides/scope-and-reopen-policy.md](guides/scope-and-reopen-policy.md).

**Request-edge contract:** for browser params, `Scrypath.QueryParams`, optional `Scrypath.Phoenix` glue, and context-owned `Scrypath.search/3`, read [guides/request-edge-search.md](guides/request-edge-search.md).

**Real-app composition and metadata:** for reusable `defaults` / `fixed` search policy, host-owned metadata rendering, and `compose_many/2` lowering into the existing runtime, read [guides/composing-real-app-search.md](guides/composing-real-app-search.md).

If you want the user-flow and jobs-to-be-done map before wiring code, read [guides/jtbd-and-user-flows.md](guides/jtbd-and-user-flows.md).

If you need the real-app story for related rows, fan-out, and when to choose direct sync versus backfill or reindex, read [guides/related-data-and-reindexing.md](guides/related-data-and-reindexing.md).

If you want the architecture and JTBD crash course before reading the full guides, start with [guides/overview.md](guides/overview.md).

If you need the Meilisearch mental model behind Scrypath's choices, read [guides/meilisearch-concepts.md](guides/meilisearch-concepts.md) before the operations guide.

For symptom-style "why is search wrong?" debugging, see [guides/common-mistakes.md](guides/common-mistakes.md).

**Sync authority:** sync semantics, sync modes (`:inline`, `:oban`, `:manual`), eventual consistency, and operator lifecycle recovery language are defined in [guides/sync-modes-and-visibility.md](guides/sync-modes-and-visibility.md). Support/readiness posture and verification commands live in [guides/support-and-compatibility.md](guides/support-and-compatibility.md); this README does not restate either guide body.

**Operator UI (maintainers):** the optional Phoenix shell lives under [scrypath_ops/README.md](scrypath_ops/README.md) in the repository checkout and is not part of the Hex package. From the repository root, **`mix verify.ops_ui`** runs the same checks against **`scrypath_ops/`** that the path-scoped **`ops-ui`** CI job exercises; see [`CONTRIBUTING.md`](CONTRIBUTING.md) for the CI ↔ **`mix verify.*`** matrix and job names.

**Realistic e-commerce/admin demo:** if you want to see Scrypath in action before wiring your own app, run [examples/scrypath_ecommerce](examples/scrypath_ecommerce/README.md). It mounts the optional operator UI beside a multi-tenant catalog storefront so you can click through tenant-scoped search, category facets, related-data propagation, failed sync triage, and swap posture. The demo is also the advisory browser evidence surface behind `ecommerce-e2e`.

**Integration smoke (optional):** the repo ships **`examples/phoenix_meilisearch`** with Docker Compose and env vars documented there (including how it relates to CI - see [`CONTRIBUTING.md`](CONTRIBUTING.md) for GitHub job names ↔ `mix verify.*` tasks). From the clone root, run **`cd examples/phoenix_meilisearch && ./scripts/smoke.sh`** (the example's **`./scripts/smoke.sh`** exists only under that directory, not at the repository root).

Scrypath is Meilisearch-first in v1. The backend seam is internal, not a promised public abstraction, and v1 does not promise public multi-backend parity.
Scrypath owns its internal transport dependency. Configure backend and sync behavior in your app code instead of pinning `Req` directly in the base install path.
If you want queued sync, add Oban as an optional production integration when you choose `sync_mode: :oban`.

## Quick Path

Start with one searchable schema and one Phoenix context that owns both repo persistence and Scrypath orchestration. Declare search metadata with **`use Scrypath`** on the Ecto schema, own **`Scrypath.sync_record/3`** after successful repo writes and **`Scrypath.search/3`** from context functions, and keep controllers or LiveView as thin callers into that boundary. For the full copy-paste path - including context module, controller, and IEx check - follow [guides/golden-path.md](guides/golden-path.md).

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

## When Scrypath Fits

Scrypath is a good fit when you want:

- search indexing that feels native to Ecto instead of bolted onto a controller or callback maze
- one explicit place to choose between inline, manual, and Oban-backed sync
- repo-backed hydration through the common `Scrypath.search/3` path
- first-class backfill and managed reindex workflows when drift or schema changes happen

## When It Does Not

Scrypath is not trying to be:

- a Postgres full-text abstraction
- a Phoenix-only library
- a public multi-backend facade in v1
- a callback-heavy "it just stays in sync somehow" runtime

If you want hidden model hooks, implicit repo access, or a library that pretends accepted work means immediate search visibility, this is the wrong tool.

## Phoenix Wayfinding

If you are wiring Scrypath into a Phoenix app, read these next:

- [Guides overview](guides/overview.md) (table of contents for all guides)
- [JTBD and user flows](guides/jtbd-and-user-flows.md) (mental model and flow map before the implementation guides)
- [Meilisearch concepts](guides/meilisearch-concepts.md) (search projection, task, settings, and backup vocabulary)
- [Request-edge search](guides/request-edge-search.md) (canonical shared story for `QueryParams`, optional `Scrypath.Phoenix`, and context-owned runtime calls)
- [Composing real-app search](guides/composing-real-app-search.md) (canonical guide for `Scrypath.Composition`, `Scrypath.Metadata`, and the worked catalog/global-search flows)
- [Related data and reindexing](guides/related-data-and-reindexing.md) (what to do when associated data changes many documents)
- [Getting Started](guides/getting-started.md)
- [Phoenix Walkthrough](guides/phoenix-walkthrough.md)
- [Phoenix Contexts](guides/phoenix-contexts.md)
- [Phoenix Controllers and JSON](guides/phoenix-controllers-and-json.md)
- [Phoenix LiveView](guides/phoenix-liveview.md)
- **`Scrypath.search_within_facet/4`** - facet-scoped full-text search from LiveView-style catalogs ([Faceted search with Phoenix LiveView](guides/faceted-search-with-phoenix-liveview.md))
- [Multi-index search](guides/multi-index-search.md) - for **`Scrypath.search_many/2`**, **`:all` expansion**, **`federation_weight:`**, and merged ordering semantics, treat that guide as canonical beyond this bullet list.
- For **request-time** Meilisearch search parameters (filters, ranking score knobs, pagination, and related call options) versus **index-time** settings declared on the schema, read the canonical [Per-query tuning pipeline](guides/per-query-tuning-pipeline.md) spec next to the index-focused relevance guide.
- [Sync Modes and Visibility](guides/sync-modes-and-visibility.md)
- [Operator Mix Tasks](guides/operator-mix-tasks.md)

The walkthrough uses one context-owned search flow and carries that same boundary through controllers and LiveView.

## Public Surface

Scrypath keeps one common runtime surface and one explicit backend-specific escape hatch:

- `Scrypath` for runtime reflection, sync verbs, operator visibility, backfill, managed reindex, and the common search path
- `Scrypath.Schema` for the declaration contract
- `Scrypath.Projection` for document projection rules
- `Scrypath.Meilisearch` for backend-native operations that do not belong on the common path

Backfill and managed reindex now use the same internal operations seam as sync, but that seam stays private. The public backend-native namespace remains `Scrypath.Meilisearch.*`.

The operator surface also stays on `Scrypath.*`:

- `Scrypath.sync_status/2`
- `Scrypath.failed_sync_work/2`
- `Scrypath.retry_sync_work/2`
- `Scrypath.reconcile_sync/2`

For terminal-first operations, the thin `mix scrypath.status`, `mix scrypath.failed`,
`mix scrypath.retry`, and `mix scrypath.reconcile` tasks wrap those same root APIs.
They do not create a second operator product surface.

`use Scrypath` is metadata-only. It validates the declaration and exposes stable `__scrypath__/1` reflection keys without generating schema-specific runtime verbs.

## Sync Modes

Call sync after successful repo persistence. Scrypath is explicit about what each mode means:

| Mode | What Scrypath does before returning | What it does not mean |
|------|-------------------------------------|-----------------------|
| `:inline` | waits for terminal backend task success before returning | database and search writes are not atomic |
| `:manual` | returns accepted backend work immediately | the document may not be searchable yet |
| `:oban` | returns durable enqueue acceptance only | the backend write has not happened yet, and the document may not be searchable |

Successful `Scrypath.sync_record/3` (and related) calls return a map that includes **`:status` `:accepted`** when work was queued or accepted but may not be searchable yet, and **`:status` `:completed`** when the `:inline` Meilisearch wait path finished - see **`guides/sync-modes-and-visibility.md`** for the full contract.

Accepted work is not the same thing as search visibility.

`sync_mode: :oban` means durable enqueue accepted, not search visibility completed.

**Choosing a mode:** **`:inline`** is enough for many local workflows and small apps when you want the caller to observe terminal backend success immediately. Move to **`:oban`** when durable enqueue and worker throughput matter more than immediate search visibility in the same process. Use **`:manual`** for migrations, bulk imports, or operator-controlled batched follow-up where you want an explicit next step instead of automatic queue progression.

The full contract - lifecycle states, Phoenix implications, recovery language, and what "success" in a controller or LiveView really means - lives in **`guides/sync-modes-and-visibility.md`**. Treat that guide as the authority; keep README as the compact route map.

If this README and the sync guide disagree, treat **`guides/sync-modes-and-visibility.md`** as the source of truth for semantics.

The monospace lifecycle line below matches the **Operator lifecycle** section in that guide.

All three modes share one operator-facing lifecycle:

`requested -> enqueued -> processing -> backend_accepted -> completed | retrying | discarded`

In practice, retries, discarded jobs, stale deletes, and drift are normal operational realities. They are not edge cases to hide with optimistic wording.

## Versioning and upgrades

Scrypath follows semantic versioning for the public API: **minor** releases can add backwards-compatible capability; **major** releases signal breaking changes worth a deliberate upgrade read. Patch releases stay focused on fixes and safe doc corrections - see **`CHANGELOG.md`** at the repository root for the human-facing release narrative.

The version in root **`mix.exs`** (`@version`) is the source of truth for **this** checkout; the latest published package is listed on [hex.pm/packages/scrypath](https://hex.pm/packages/scrypath).

Quality for the packaged artifact is guarded by **`mix verify.phase11`**, the always-on gate referenced from [docs/releasing.md](docs/releasing.md). That document - not this README - owns the full verify matrix, Release Please flow, and publish checks for maintainers.

## Search

The common search path stays small and explicit:

```elixir
{:ok, result} =
  Scrypath.search(MyApp.Blog.Post, "ecto",
    backend: Scrypath.Meilisearch,
    repo: Repo,
    filter: [status: "published"],
    sort: [desc: :inserted_at],
    page: [number: 2, size: 20],
    preload: [:author]
  )

result.records
result.hits
result.missing_ids
result.page
```

Hydration is explicit and repo-backed. Scrypath does not infer repos globally or hide stale rows when search hits no longer match the database.

## Backfill And Reindex

Scrypath treats repair and rebuild work as first-class operator workflows:

- `Scrypath.backfill/2`
- `Scrypath.reindex/2`

Use backfill when the live index contract is still correct and you need to repair missing or stale documents.

Use managed reindex when the contract changed, settings changed, or you no longer trust the live index contents.

```elixir
{:ok, result} =
  Scrypath.reindex(MyApp.Blog.Post,
    backend: Scrypath.Meilisearch,
    repo: Repo,
    batch_size: 500,
    cutover?: false
  )

result.live_index
result.target_index
result.settings_applied
result.batches
result.documents
result.cutover
```

`cutover?: false` leaves the live index untouched while you inspect the rebuilt target.

## Drift Detection And Recovery

Detect drift before deciding whether a live-index backfill is enough or whether you need a full rebuild. Common signals are:

- stale search hits whose hydrated records are now missing
- document-count mismatches between the source table and the search index
- failed or discarded sync work
- stale deletes where search still returns records removed from the database
- projection or setting changes that should have rewritten every document

Accepted work is not the same thing as search visibility, and durable enqueue is not the same thing as rebuild completion.

Use `Scrypath.sync_status/2` and `Scrypath.failed_sync_work/2` when you need to inspect pending, retrying, failed, or last-successful work without reading raw Meilisearch or Oban payloads.

Use `Scrypath.reconcile_sync/2` when you need a report-first operator view that combines sync visibility, failed work, and rebuild visibility before you decide on recovery.

`Scrypath.reconcile_sync/2` does not heal anything by default. It returns drift signals plus explicit recovery actions so the caller can choose retry, backfill, or reindex deliberately.

## Integration smoke (Meilisearch)

CI runs live Meilisearch-backed tests in a dedicated workflow job. Locally you can use Docker Compose (from the repo root):

```bash
docker compose up -d
SCRYPATH_MEILISEARCH_URL=http://127.0.0.1:7700 mix verify.meilisearch_smoke
docker compose down
```

`mix verify.meilisearch_smoke --skip-integration` exits without contacting Meilisearch (useful for quick task wiring checks only; it does not run the live suites).

## Example: Phoenix + Postgres + Meilisearch

For a minimal consumer-shaped setup (Docker Compose with Postgres and Meilisearch on an explicit network, path dependency on this repo, and a scripted smoke test), see [examples/phoenix_meilisearch/README.md](examples/phoenix_meilisearch/README.md).

For a richer click-around showcase with a multi-tenant storefront and mounted operator UI, see [examples/scrypath_ecommerce/README.md](examples/scrypath_ecommerce/README.md).

## Architecture

See [ARCHITECTURE.md](ARCHITECTURE.md) for the full runtime boundary, sync guarantees, drift model, and managed reindex workflow order.

For operational guides, see [Sync Modes and Visibility](guides/sync-modes-and-visibility.md),
[Meilisearch Concepts](guides/meilisearch-concepts.md),
[Meilisearch Operations](guides/meilisearch-operations.md),
[Operator Mix Tasks](guides/operator-mix-tasks.md),
[Operator Support](docs/operator-support.md), and
[Search backend operations - SRE view](docs/search-backend-sre.md).
