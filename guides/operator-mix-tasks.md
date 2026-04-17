# Operator Mix Tasks

Use the Mix tasks in this guide when you want thin terminal entrypoints over the existing operator APIs on `Scrypath.*`.

The tasks do not bypass the library surface. Each one starts the app, parses task-owned argv, and delegates to the same root API you can call from code.

## Shared Runtime Options

The task layer accepts the same runtime options Scrypath already understands:

- `--backend Scrypath.Meilisearch` or `--backend meilisearch`
- `--sync-mode inline|manual|oban`
- `--index-prefix tenant`
- `--meilisearch-url http://127.0.0.1:7700`
- `--oban MyApp.Oban`
- `--oban-queue search_sync`

Keep backend-native search under `Scrypath.Meilisearch.*`. The operator tasks are for visibility and recovery, not a second search product surface.

## `mix scrypath.status`

`mix scrypath.status` wraps `Scrypath.sync_status/2`.

```bash
mix scrypath.status MyApp.Blog.Post --backend meilisearch --sync-mode oban --index-prefix tenant
```

Use it when you need a quick read on backend pending work, backend failures, last successful visibility, and queue backlog in `:oban` mode.

## `mix scrypath.failed`

`mix scrypath.failed` wraps `Scrypath.failed_sync_work/2`.

```bash
mix scrypath.failed MyApp.Blog.Post --backend meilisearch --sync-mode oban --index-prefix tenant
```

Use it when you want a stable list of failed or retrying work with a Scrypath-owned id, operation kind, retryability, summarized reason, and **`reason_class=`** on each row.

When there is at least one row, human output includes a compact **`Failed work by class:`** rollup (same taxonomy as `FailedWork.reason_class_counts/1`) above the per-row lines.

```bash
mix scrypath.failed MyApp.Blog.Post --backend meilisearch --sync-mode oban --index-prefix tenant --json
```

**`--json`** prints a single JSON document to stdout (no `Mix` shell framing). Use **`--no-class-summary`** to hide only the rollup header when piping or grepping row lines.

## `mix scrypath.retry`

`mix scrypath.retry` wraps `Scrypath.retry_sync_work/2`.

```bash
mix scrypath.retry MyApp.Blog.Post --id 601 --backend meilisearch --sync-mode oban --index-prefix tenant
```

Retry stays explicit. You must pass a concrete failed-work id. The task does not invent recovery targets or synthesize new retry semantics on its own.

## `mix scrypath.reconcile`

`mix scrypath.reconcile` wraps `Scrypath.reconcile_sync/2`.

```bash
mix scrypath.reconcile MyApp.Blog.Post --backend meilisearch --sync-mode oban --index-prefix tenant
```

By default it is report-first. It prints drift signals, failed-work count, a **`Failed work by class:`** rollup aligned with the same rows, recommended actions, and target-index visibility when a rebuild is in progress.

To mutate, request one explicit action from the report:

```bash
mix scrypath.reconcile MyApp.Blog.Post --action retry --id 601 --backend meilisearch --sync-mode oban --index-prefix tenant
mix scrypath.reconcile MyApp.Blog.Post --action reindex --backend meilisearch --sync-mode manual --index-prefix tenant
```

That keeps `Scrypath.reconcile_sync/2` honest: it reports first and only mutates when you ask for a concrete action.

## `mix scrypath.settings.hot_apply`

Applies a **live** Meilisearch settings PATCH for one schema. Only `synonyms`, `stop_words`, and `typo_tolerance` are sent; anything else is rejected before HTTP. You must pass **`--ack-live`** on every invocation (explicit acknowledgement of live mutation).

```bash
mix scrypath.settings.hot_apply MyApp.Blog.Post --settings-file operator/stopwords-patch.json --ack-live --meilisearch-url http://127.0.0.1:7700 --index-prefix tenant
```

Tradeoffs and non-goals: see `guides/relevance-tuning.md` (**Settings hot apply (v1.4)**).
