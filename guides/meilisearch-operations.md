# Meilisearch operations for Scrypath adopters

This guide is for **operators** who run Scrypath against **Meilisearch** in development, staging, or production. It stays at the **infrastructure and posture** layer: where the engine runs, how to align versions with Scrypath’s expectations, and which companion guides carry the detailed recovery playbooks.

## Guide map

- [`guides/sync-modes-and-visibility.md`](sync-modes-and-visibility.md) — canonical semantics for `:inline`, `:oban`, and `:manual` sync and what “accepted” work means for search visibility.
- [`guides/drift-recovery.md`](drift-recovery.md) — symptom → diagnosis → action tables when the index and the database disagree.
- [`guides/common-mistakes.md`](common-mistakes.md) — short wrong-model → fix notes when behaviour “feels” like data loss but is usually visibility or hydration drift.
- [`guides/operator-mix-tasks.md`](operator-mix-tasks.md) — thin `mix scrypath.*` entrypoints over the same `Scrypath.*` operator APIs referenced here.

## Where Meilisearch runs

Treat Meilisearch as a **separate stateful service** beside your application and primary database:

- **Development** — local binary, Docker, or Compose; keep the HTTP URL stable in `SCRYPATH_MEILISEARCH_URL` (or your app’s equivalent runtime config) so Scrypath tasks and `iex` sessions agree on the same cluster.
- **Production** — run a supported Meilisearch release on infrastructure you operate (VM, Kubernetes, or managed offering that exposes the HTTP API Scrypath expects). Document the URL, master key handling, and TLS termination the same way you would for any other data store dependency.

Scrypath does **not** hide network or credential concerns: configure the backend URL and keys in the same runtime surfaces you use for Postgres and Oban.

## Version alignment

Scrypath’s tests and examples track a **pinned Meilisearch minor** (see the Phoenix example README and CI service images for the current target). Before upgrading production:

- Confirm the new Meilisearch release notes for breaking HTTP or task semantics.
- Run your usual **`mix test`** plus any integration suites you enable with `SCRYPATH_INTEGRATION=1` against a disposable cluster at the new version.

Staying within the supported matrix reduces “mystery” task failures that look like application bugs but are really engine behaviour changes.

## Keys, TLS, and blast radius

- Scope API keys so production indexes are not writable from developer laptops unless you intend that explicitly.
- Prefer TLS between your app and Meilisearch wherever traffic crosses an untrusted network.
- Treat the master key like a database superuser password: rotation requires coordinated config updates on every Scrypath node and worker.

## Backups vs rebuilding from Postgres

Meilisearch is a **search projection** of data you already store in the primary database (or import pipeline). For most teams:

- **Rebuilding** — acceptable and often simplest after large schema or settings changes: run a managed `Scrypath.reindex/2` or `Scrypath.backfill/2` path once Meilisearch is healthy, using the same semantics described in [`guides/sync-modes-and-visibility.md`](sync-modes-and-visibility.md).
- **Backups** — still valuable for large corpora or when rebuild time is unacceptable; snapshot Meilisearch data directories or vendor backups on the schedule your RPO/RTO demands, **and** keep Postgres (or source-of-truth) backups authoritative.

If you are unsure which path applies, start with drift triage in [`guides/drift-recovery.md`](drift-recovery.md) before choosing destructive rebuild steps.

## Health checks operators actually use

At minimum, operators should be able to answer:

- Can the app reach **`GET /health`** (or your platform’s equivalent) on the configured Meilisearch base URL with the configured key?
- Do Meilisearch **tasks** for your indexes show sustained `failed` states while Postgres writes succeed?
- Does `Scrypath.sync_status/2` report backlog or backend errors consistent with what Meilisearch’s task list shows?

Use `mix scrypath.status` for a compact terminal snapshot when `MIX_ENV` and runtime flags match production (`--backend`, `--sync-mode`, `--index-prefix`, `--meilisearch-url` as documented in [`guides/operator-mix-tasks.md`](operator-mix-tasks.md)).

## Footguns

- **Assuming “sync returned `:ok`” means the user’s next search is fresh** — see [`guides/sync-modes-and-visibility.md`](sync-modes-and-visibility.md); accepted work is not the same thing as search visibility.
- **Treating Meilisearch as the source of truth for business data** — it is a search index; reconcile or rebuild from your primary store when in doubt.
- **Running CI or examples against a different Meilisearch major/minor than production** — keep local Compose files and CI images aligned with what you ship, then document intentional drift if any.

For structured recovery steps once a concrete symptom is identified, continue in [`guides/drift-recovery.md`](drift-recovery.md).
