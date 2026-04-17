# Search backend operations (SRE view)

This guide is for **platform and SRE** maintainers who run the search process alongside a Phoenix app using Scrypath. It complements [Sync Modes and Visibility](guides/sync-modes-and-visibility.md) (application semantics) and [Operator Support](operator-support.md) (library maintainer first response).

## Scope

- **Scrypath v1** publicly targets **Meilisearch** first. Runbooks here assume a Meilisearch cluster or single node your app reaches over HTTP. Other engines need different metrics and failure modes; Scrypath does not abstract them on the public path.
- **Goal:** a **small** set of metrics and alerts so teams notice user-visible failure and capacity risk without paging on normal variance.

## Two layers: app vs search engine

| Layer | What you own | What breaks first when users complain |
|-------|----------------|--------------------------------------|
| **Application** | Scrypath sync/search/hydration paths, Oban queues, DB | Wrong or stale results, timeouts, 5xx from your app |
| **Meilisearch** | Process health, disk, RAM, version, task pipeline | Search down, writes stuck, index corruption risk under disk pressure |

Instrument **both**. Do not page only on Meilisearch CPU; pair with **Scrypath search error rate** and **end-to-end latency** from the app.

## Scrypath telemetry (application signals)

Scrypath emits **`:telemetry.span/3`**-style events (see [Telemetry](https://hexdocs.pm/telemetry/readme.html) for `start` / `stop` / `exception` and duration measurements on `stop`). Keep dashboards **low cardinality**: use `schema`, `backend`, `index`, `sync_mode` — avoid high-cardinality tags such as raw query text or primary keys on alert rules.

Stable event prefixes (each has `:start`, `:stop`, and on failure `:exception` where applicable):

| Event prefix | When | Useful aggregates |
|--------------|------|-------------------|
| `[:scrypath, :search]` | Common-path search | p95/p99 duration, error rate, `hit_count` from stop metadata |
| `[:scrypath, :hydration]` | Repo batch load after search | Duration vs `hit_count` / `record_count` / `missing_count` (drift indicator when `missing_count` grows) |
| `[:scrypath, :sync, :upsert]` / `[:scrypath, :sync, :delete]` | Document sync | Error rate, `document_count`, `:noop` ratio (noisy if alerted per call) |
| `[:scrypath, :meilisearch, :request]` | HTTP to Meilisearch | `status_code`, `method`, `path` pattern — alert on sustained 5xx / connection errors |
| `[:scrypath, :meilisearch, :task_wait]` | Waiting for Meilisearch task completion | `poll_count`, `final_status` — large `poll_count` or non-`:succeeded` trends |
| `[:scrypath, :reindex, :settings_verified]` | Post-apply settings read-back | Stop metadata `result` tag (`:parity`, `:drift`, etc.) |
| `[:scrypath, :reindex, :verify_skipped]` | Execute only — settings verify skipped by opt | Rare spikes may be intentional deploys; correlate with logs |
| `[:scrypath, :operator, :failed_work, :observed]` | Each failed-work row materialized from backend tasks or Oban jobs | Useful for dashboards and structured logs; **high volume** on noisy data — do **not** page on every event; treat as diagnostic signal and aggregate |

**Dashboard-first:** sync upsert volume, search QPS, hydration `missing_count` distribution, Meilisearch request latency.

## Meilisearch infrastructure (minimal signals)

Prioritize signals that predict **outage**, **data loss risk**, or **unbounded backlog**. Exact metric names depend on your exporter (Prometheus sidecar, cloud vendor agent, or logs). Map these **concepts** to your stack:

1. **Process up / ready** — HTTP `GET /health` (or vendor equivalent) from the same network path as the app. Page when **unreachable** for longer than a short window (e.g. two failed checks), not on single blips.
2. **Disk free** — Meilisearch persists indexes; **running out of disk** is a top cause of corruption and wedged tasks. Alert on **free space percentage or absolute GB** with headroom for compactions and reindexes.
3. **Memory pressure** — Large batches and concurrent indexing drive RSS. Page on **OOM kills** or **sustained** memory limit pressure from your orchestrator, not one-off spikes during planned reindex.
4. **Task failures** — Meilisearch indexes work through a **task** queue. Sustained **failed** tasks (not every transient validation error) indicate a bad deploy, schema mismatch, or upstream bug. Prefer a **rate** or **count over a window**, not every single failure.
5. **Replication / multi-node** (if used) — **split brain or lag** between nodes is a separate product surface; follow Meilisearch’s own HA docs for your version.

**Avoid alert fatigue:** do **not** page on single slow searches, one failed document in a batch, or Meilisearch `202 Accepted` enqueue latency alone. Those belong on dashboards or SLO burn-rate rules with long windows.

## Footguns (Meilisearch + Scrypath-shaped)

- **`filter` and `facetFilters` AND together** — Users can think they cleared facets while a base `filter` still narrows results. Document in your UI and ops playbooks; see the faceted search guide appendix.
- **Reindex + disk** — Full reindex can **temporarily double** index footprint until old data is dropped. Plan disk headroom before `Scrypath.reindex/2` on large corpora.
- **Settings verify skipped** — `skip_settings_verification?: true` speeds emergencies but **hides drift** until the next verify. Treat as a **temporary** flag; do not leave it on silently.
- **Sync mode semantics** — `:oban` means **durable enqueue**, not “search is updated.” Paging on queue depth without checking **search visibility** misdiagnoses user impact; see sync modes guide.
- **Version skew** — Meilisearch minor versions change task and index behavior. Pin server **and** client expectations per environment; roll upgrades in a canary before production.

## What to run before you tune alerts

From the repo root (maintainer checks):

- **mix verify.phase13** (with integration when you have `SCRYPATH_MEILISEARCH_URL`) — exercises operator flows against a real Meilisearch in CI-style setups.
- **Application-level:** `Scrypath.sync_status/2`, `Scrypath.failed_sync_work/2`, `Scrypath.reconcile_sync/2` for human-readable posture before you change indexing.

## Related docs

- [ARCHITECTURE.md](ARCHITECTURE.md) — drift, reindex order, and sync guarantees
- [guides/sync-modes-and-visibility.md](guides/sync-modes-and-visibility.md) — `:inline` / `:oban` / `:manual`
- [guides/operator-mix-tasks.md](guides/operator-mix-tasks.md) — thin Mix wrappers over `Scrypath.*`
- [guides/relevance-tuning.md](guides/relevance-tuning.md) — settings and verify-applied semantics
