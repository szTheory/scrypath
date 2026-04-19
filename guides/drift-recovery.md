# Drift recovery for Scrypath and Meilisearch

This guide is for **operators** who already ship Scrypath with Meilisearch and need a **short, repeatable path** from symptom to verification when search and the database disagree, or when indexing work is stuck. It assumes you can run your app (or `iex -S mix`) with the same config your workers use.

## Guide map

- [`guides/relevance-tuning.md`](relevance-tuning.md) — open when ranking, searchable attributes, or verify-applied settings are in question.
- [`guides/faceted-search-with-phoenix-liveview.md`](faceted-search-with-phoenix-liveview.md) — open when filters, facet counts, or `filterableAttributes` explain the mismatch.
- [`guides/multi-index-search.md`](multi-index-search.md) — open when the wrong index or federation-style `search_many/2` behavior is suspected.

## Empty index (documents exist in the DB but search returns nothing)

**Symptom** — Users see empty search or “no hits” for `YOUR_SCHEMA` while Postgres (or your primary store) clearly has rows that should be indexed.

**Diagnosis** — Distinguish “never indexed” from “settings or facet contract hiding hits”: if tasks never succeeded, you have a cold index or a failed backfill path rather than a relevance ranking issue ([relevance-tuning.md](relevance-tuning.md) covers ranking and verify-applied semantics, not whether rows were ever ingested).

**Action** — Run `Scrypath.sync_status/2` on `YOUR_SCHEMA` with your runtime config. If the index is missing or never completed a successful backfill, run `Scrypath.backfill/2` for that schema (or your app’s wrapper) with the same `backend`, `index_prefix`, and credentials you use in production. Use `mix scrypath.status` in CI or a shell with `MIX_ENV` loaded to confirm queue and backend posture when `sync_mode` is `:oban`.

**Verify** — Re-run search against `http://localhost:7700` (or your cluster URL) and confirm hit counts move. `mix scrypath.reconcile` stays report-first: use it to print recommended actions, then apply `Scrypath.backfill/2` or `Scrypath.reindex/2` explicitly if the reconcile output says so.

## Stale results after sync success

**Symptom** — `Scrypath` sync calls return success, or Meilisearch tasks show `succeeded`, but the UI still shows old titles, stale deletes, or rows that no longer exist in the database.

**Diagnosis** — This is often **hydration or visibility drift**, not a failed task: accepted work is not the same thing as what the user’s next search returns. If the wrong physical index or alias is targeted in a multi-index app, confirm you are not mis-attributing a federation issue to sync ([multi-index-search.md](multi-index-search.md)).

**Action** — Call `Scrypath.sync_status/2` and `Scrypath.failed_sync_work/2` on `YOUR_SCHEMA` to rule out retrying or discarded jobs. If the queue is clean, use `mix scrypath.reconcile` for a read-only triage summary, then choose a deliberate `Scrypath.backfill/2` for bounded repair or `Scrypath.reindex/2` when the live index should not be trusted.

**Verify** — Spot-check representative IDs in the DB vs Meilisearch `GET /indexes/{uid}/documents/{id}`. After backfill or cutover-driven reindex, repeat the same queries your users run.

## Backfill or document-count divergence

**Symptom** — Dashboards or scripts show different document totals between the database and Meilisearch, or partial shards after a large import.

**Diagnosis** — Count drift usually means an interrupted backfill, partial batch failure, or a later delete path that never reached the backend; facet or filter configuration can make counts *look* wrong even when documents exist ([faceted-search-with-phoenix-liveview.md](faceted-search-with-phoenix-liveview.md)).

**Action** — Use `Scrypath.sync_status/2` for a high-level picture, then `Scrypath.failed_sync_work/2` for concrete rows. Repair narrow gaps with `Scrypath.retry_sync_work/2` when `retryable?` is true; use `Scrypath.backfill/2` when the index is healthy but incomplete. `mix scrypath.failed` surfaces the same failed-work list without starting `iex`.

**Verify** — Compare counts after backfill completes (Meilisearch stats vs your source of truth). Run `mix scrypath.status` to ensure no retryable backlog remains when using `:oban`.

## Failed-work pileup (Oban or backend tasks)

**Symptom** — `mix scrypath.failed` shows a growing list, or `Scrypath.failed_sync_work/2` returns many rows; alerts on Meilisearch failed tasks fire.

**Diagnosis** — Classify transport vs validation vs exhausted queue work using each row’s `reason`, `reason_class`, and `retryable?` before replaying anything. Validation-shaped failures need data or schema fixes first; transport blips may respond to a single retry.

**Action** — Start with `mix scrypath.status`, then `mix scrypath.failed` for IDs (optional **`--json`** for machine-readable rollups, or read **`failed_work_counts`** on **`mix scrypath.reconcile`** / `%Scrypath.Operator.Reconcile{}`). Retry one id at a time with `mix scrypath.retry` (or `Scrypath.retry_sync_work/2` from application code) only when the row is retryable and the underlying contract still holds. Use `mix scrypath.reconcile` for a structured report; apply `Scrypath.reconcile_sync/2` only with explicit options after reading the report.

**Verify** — Re-run `Scrypath.failed_sync_work/2` until the list is empty or only contains expected non-retryable rows. Confirm Meilisearch’s task list stops growing failed tasks for the same root cause.

## Settings drift (ranking or attributes changed)

**Symptom** — Search “works” but ranking, typo tolerance, or displayed fields are wrong after a deploy that changed schema settings.

**Diagnosis** — Settings drift is a **rebuild-class** problem: changing `searchableAttributes`, ranking rules, or synonym maps often requires reindex rather than a row-level backfill; this overlaps with relevance tuning, not facet UI state alone.

**Action** — Read back settings with your existing settings-read path, compare to the schema module’s declared settings, then run `Scrypath.reindex/2` on `YOUR_SCHEMA` when verify-applied or operator policy says the live index is no longer authoritative. Keep `skip_settings_verification?` off in steady state so post-apply checks can fire.

**Verify** — After reindex completes, run representative searches and, if you use it, your verify-applied step from the relevance guide. `mix scrypath.status` should show no stuck settings tasks.

## Index contract drift (fields, filterable, sortable, faceting, settings families)

**Symptom** — Search or the index “looks wrong” in ways that may be **contract** mismatches beyond ranking-only settings: missing filterable attributes, wrong sortables, facet shape drift, or structural field mismatches.

**Diagnosis** — **`mix scrypath.settings.diff`** stays focused on **declared vs applied** Meilisearch `settings:` keys and rebuild-class posture for those keys. **Index contract drift** compares the broader **declared schema vs live index** contract (searchable fields, filterable attributes, sortable attributes, faceting shape, and the declared settings families) using one read-only `get_settings` pass.

**Action** — Run **`mix scrypath.index.contract_drift YOUR_SCHEMA`** (add **`--json`** for machine output) or call **`Scrypath.index_contract_drift/2`** from application code to get the structured **index contract drift** report. This path is **report-first** and does not mutate the index. When you only need settings-key parity, keep using **`mix scrypath.settings.diff`**. When you decide to repair, follow your existing **`Scrypath.reconcile_sync/2`** and **`Scrypath.reindex/2`** runbooks explicitly.

**Verify** — Re-run after deploys that touch schema contracts. For maintainer ordering on when to reach for queue triage vs contract reads vs reconcile, see [`docs/operator-support.md`](operator-support.md).

## Stuck reindex mid-cutover

**Symptom** — A long `Scrypath.reindex/2` run paused, dual-write confusion, or operators are unsure which index UID is live.

**Diagnosis** — Reindex is intentionally multi-step (create target, apply settings, backfill, optional cutover). A stall is often visible in Meilisearch tasks or in Oban backlog for enqueue modes; multi-index apps should confirm which schema/index pair the cutover targets ([multi-index-search.md](multi-index-search.md)).

**Action** — Inspect `Scrypath.sync_status/2` for `YOUR_SCHEMA`, then `Scrypath.failed_sync_work/2` for blocking failures. Clear retryable work with `Scrypath.retry_sync_work/2` or `mix scrypath.retry` where appropriate. If the reindex should restart from a clean plan, call `Scrypath.reindex/2` again with the same explicit options your runbook uses (do not invent new verbs).

**Verify** — Confirm the active index UID in config matches the index your app queries. Run `mix scrypath.reconcile` before and after to keep decisions explicit.

## Related guides

- [`guides/sync-modes-and-visibility.md`](sync-modes-and-visibility.md) — `:inline`, `:oban`, and `:manual` semantics.
- [`guides/operator-mix-tasks.md`](operator-mix-tasks.md) — thin Mix wrappers over `Scrypath.*`.
- [`guides/relevance-tuning.md`](relevance-tuning.md) — settings, verify-applied, and ranking workflows.
- [`guides/faceted-search-with-phoenix-liveview.md`](faceted-search-with-phoenix-liveview.md) — facet drift and LiveView-oriented checks.
- [`guides/multi-index-search.md`](multi-index-search.md) — `search_many/2` and multi-schema operations.
