# Meilisearch operations for Scrypath adopters

This guide is for teams running Scrypath against Meilisearch in development, staging, or production. It assumes Scrypath is the application layer around indexing and recovery, while Meilisearch remains a separate stateful service you operate or buy.

The short version: Postgres is the source of truth, Meilisearch is the search projection, and Scrypath is the orchestration layer that keeps projection, sync, drift, and rebuild workflows explicit.

## Guide map

- [Meilisearch concepts](meilisearch-concepts.md) - the short vocabulary and mental model before you operate it.
- [Sync modes and visibility](sync-modes-and-visibility.md) - what `:inline`, `:oban`, and `:manual` mean for search visibility.
- [Relevance tuning](relevance-tuning.md) - settings-as-code, settings drift, and managed reindex semantics.
- [Drift recovery](drift-recovery.md) - symptom to diagnosis to repair when search and the database disagree.
- [Operator Mix tasks](operator-mix-tasks.md) - thin terminal entrypoints over `Scrypath.*` operator APIs.
- [Search backend operations](../docs/search-backend-sre.md) - SRE dashboards, alerts, and capacity signals.

## Where Meilisearch runs

Treat Meilisearch as a separate stateful service beside your Phoenix app and database.

- **Development:** local binary, Docker, or Compose. Keep the HTTP URL stable in `SCRYPATH_MEILISEARCH_URL` or your app's runtime config so `iex`, tests, and workers talk to the same service.
- **Staging:** run the same Meilisearch minor line and similar settings as production. Use staging to rehearse imports, reindexes, restores, and upgrades.
- **Production:** run a pinned Meilisearch version on infrastructure you operate, or use Meilisearch Cloud when you do not want to own service operations.

Scrypath does not hide networking or credential concerns. Configure backend URL, key material, sync mode, repo, and queue behavior in the same runtime surfaces you use for Postgres and Oban.

## Local stand-up

For a known-good local Phoenix + Postgres + Meilisearch path, prefer the repository example in `examples/phoenix_meilisearch`. The examples and CI currently pin the supported Meilisearch minor; see [Support and compatibility](support-and-compatibility.md) for the current target.

If you need a minimal local Meilisearch-only service, the shape should look like this:

```yaml
services:
  meilisearch:
    image: getmeili/meilisearch:v1.15
    command: ["meilisearch", "--db-path", "/meili_data", "--http-addr", "0.0.0.0:7700"]
    ports:
      - "127.0.0.1:7700:7700"
    environment:
      MEILI_ENV: development
      MEILI_MASTER_KEY: dev_master_key_change_me_123456
    volumes:
      - meili_data:/meili_data
    healthcheck:
      test: ["CMD", "curl", "-fsS", "http://localhost:7700/health"]
      interval: 5s
      timeout: 2s
      retries: 20

volumes:
  meili_data:
```

Keep test suites deterministic by waiting where the test contract requires visibility. Do not assume Meilisearch writes are synchronous unless the Scrypath call path explicitly waits for terminal backend success.

## Production checklist

Use this as the first production pass before launching a Scrypath-backed feature:

- Pin an exact Meilisearch version. Do not run `latest`.
- Set `MEILI_ENV=production`.
- Use a strong master key stored in a secret manager.
- Create scoped API keys for server-side indexing/search; do not use the master key from ordinary app code.
- Keep Meilisearch on private networking, or put it behind TLS and an authenticated reverse proxy.
- Use persistent low-latency local or block storage, preferably SSD/NVMe-class.
- Do not place the live Meilisearch database on S3FS, NFS, or slow network filesystems.
- Configure snapshots or dumps according to your RPO/RTO, then test restore.
- Monitor health, tasks, failed tasks, disk, memory pressure, and Scrypath search/sync telemetry.
- Capacity-test the initial import and managed reindex path before launch.
- Document how to pause workers, restore or rebuild, verify counts, and resume sync.

The official Meilisearch docs cover the underlying operations in more detail: [production deployment](https://www.meilisearch.com/docs/learn/self_hosted/going_to_production), [data backups](https://www.meilisearch.com/docs/resources/self_hosting/data_backup/overview), [storage](https://www.meilisearch.com/docs/learn/engine/storage), and [API key security](https://www.meilisearch.com/docs/learn/security/differences_master_api_keys).

## Keys, TLS, and blast radius

Treat the master key like a database superuser password. It should manage API keys, not sit in browser code, logs, CI output, or everyday app search calls.

A practical split:

| Credential | Use |
| --- | --- |
| Master key | Rare administrative key management and emergency access. |
| Indexing/admin key | Server-side Scrypath sync, settings, task, and index-management operations your app legitimately needs. |
| Search key | Narrow search-only access when direct client search is intentional. |
| Tenant token | Browser/client search restriction for shared multi-tenant indexes. |

Prefer private networking. If traffic crosses an untrusted network, require TLS. For a Phoenix app that searches through its own backend, do not expose Meilisearch directly to the browser unless you have deliberately chosen that architecture and understand tenant token constraints.

Key rotation should be staged:

1. Create the new scoped key.
2. Deploy the app/workers with the new key.
3. Verify search and indexing.
4. Delete the old key.

Resetting the master key can invalidate derived API keys. Plan that as an operational event, not a casual config change.

## Storage and capacity

Meilisearch stores indexes with LMDB and relies on memory-mapped I/O plus the OS page cache. High memory use can be normal; OOM kills and sustained memory limit pressure are not.

Plan for:

- **Disk:** index data, snapshots/dumps, task DB growth, and temporary headroom during rebuilds. A reindex can temporarily require old and new index data at the same time.
- **Memory:** hot data, search traffic, indexing batches, and Meilisearch indexing memory limits.
- **CPU:** search, tokenization, ranking, and indexing work.
- **Task volume:** each document batch, settings change, dump, snapshot, swap, or delete is task-shaped work.

For Scrypath jobs, prefer moderately sized batches over one task per record or giant payloads. The right batch size depends on document shape, hardware, and latency budget. Start conservative, measure task latency and memory pressure, then tune.

Avoid indexing noisy fields that do not affect search. High-churn counters, page views, inventory ticks, or transient analytics fields can create task debt without improving search quality.

## Backups, DR, and rebuilds

Meilisearch has two important backup/migration artifacts:

| Artifact | Use it for | Tradeoff |
| --- | --- | --- |
| Snapshot | Fast restore to the same Meilisearch version. | Not the migration path across versions. |
| Dump | Portable migration or upgrade export. | Slower import because Meilisearch reprocesses data. |

Because Scrypath treats Meilisearch as a projection, you also have a third recovery path: rebuild from Postgres or your source data.

Choose deliberately:

- **Restore a snapshot** when the same-version index is large and fast restore matters.
- **Import a dump** when upgrading or moving data between versions/environments.
- **Rebuild from source of truth** when projection/settings drift is suspected, or when you want the most trustworthy recomputation.

A practical DR runbook:

1. Pause or drain Scrypath sync workers if replay order matters.
2. Bring up Meilisearch at the intended version.
3. Restore a snapshot, import a dump, or rebuild with `Scrypath.reindex/2`.
4. Check `/health`.
5. Compare `/stats` document counts against source-of-truth counts.
6. Run known search, filter, sort, and facet smoke queries.
7. Run Scrypath status/reconcile checks.
8. Resume workers and replay missed outbox or queue work.

Backup creation is not enough. A backup is only useful after a restore has been rehearsed.

## Upgrades and version alignment

Scrypath's verified Meilisearch target is documented in [Support and compatibility](support-and-compatibility.md). Keep local Compose, CI, staging, and production aligned unless you are intentionally testing a version move.

Safe upgrade posture:

1. Read the Meilisearch release notes.
2. Freeze risky settings changes during the upgrade window.
3. Create a dump from the current production version.
4. Import that dump into staging on the target version.
5. Run health, stats, settings diff, known queries, filters, sorts, facets, and Scrypath status checks.
6. Take a fresh production dump before cutover.
7. Upgrade using the Meilisearch-documented migration path.
8. Watch tasks, disk, RSS/memory pressure, search latency, and Scrypath error telemetry.

Never casually point an untested new binary at production data. Prefer a rehearsed dump/import path for version moves, following Meilisearch's [upgrade guidance](https://www.meilisearch.com/docs/learn/update_and_migration/updating).

## Common operator tasks

**Is Meilisearch reachable?**

```bash
curl -fsS "$MEILI/health" \
  -H "Authorization: Bearer $MEILI_ADMIN_KEY"
```

Expected status is `available`. Run the check from the same network path your Phoenix app uses.

**Is indexing backed up?**

```bash
curl -fsS "$MEILI/tasks?statuses=enqueued,processing&limit=100" \
  -H "Authorization: Bearer $MEILI_ADMIN_KEY"
```

Look for old processing tasks, sustained queues, repeated failures, and task volume that grows faster than workers can clear it.

**How many documents are indexed?**

```bash
curl -fsS "$MEILI/stats" \
  -H "Authorization: Bearer $MEILI_ADMIN_KEY"
```

Compare index counts to source-of-truth counts for the same visibility rules. Raw table count is not always the right comparison if only published or tenant-visible records are indexed.

**Does Scrypath see the same posture?**

Use `mix scrypath.status`, `mix scrypath.failed`, and `mix scrypath.reconcile` with the same runtime flags your app uses. These tasks delegate to `Scrypath.*` operator APIs and are the preferred first response before mutating state.

## Footguns

- **Assuming accepted work is visible search** - tasks are async; read [Sync modes and visibility](sync-modes-and-visibility.md).
- **Treating Meilisearch as the source of truth** - rebuild or hydrate from the primary store when correctness matters.
- **Changing settings casually** - many settings are rebuild-class contract changes; read [Relevance tuning](relevance-tuning.md).
- **Indexing giant or sensitive documents** - keep documents lean and safe to return.
- **Declaring every field searchable/filterable/sortable** - every capability has indexing and storage cost.
- **One tiny task per high-churn domain event** - batch, debounce, or omit fields that do not affect search.
- **Using the master key everywhere** - scope credentials and keep browser access narrow.
- **Implicit index creation in production** - create indexes and apply settings explicitly before importing documents.
- **Running unpinned `latest`** - pin versions and rehearse upgrades.
- **Rebuilding into the live index** - prefer managed reindex with an inspectable target and deliberate cutover for broad changes.
- **Ignoring task DB growth** - task history is operational data; monitor and prune according to your retention policy.

## Infrastructure sketch

This is not a production Terraform module. It shows the shape to preserve when translating to EC2, ECS, Kubernetes, Fly, Render, or another platform:

```hcl
resource "aws_security_group" "meili" {
  name   = "meilisearch"
  vpc_id = var.vpc_id

  ingress {
    description     = "Meilisearch API from Phoenix app"
    from_port       = 7700
    to_port         = 7700
    protocol        = "tcp"
    security_groups = [var.app_security_group_id]
  }
}

resource "aws_ebs_volume" "meili_data" {
  availability_zone = var.availability_zone
  size              = 100
  type              = "gp3"
  encrypted         = true
}
```

The important choices are platform-independent: private access from the app, pinned version, production mode, strong secrets, persistent low-latency storage, supervised process, health checks, and off-host backups.

## What Scrypath should make boring

Scrypath cannot remove the need to operate Meilisearch, but it should keep the common decisions inspectable:

- what index a schema maps to
- what settings were declared
- what sync work is pending, retrying, or failed
- whether settings or contract drift exists
- whether backfill is enough or managed reindex is safer
- when a target index is ready for cutover

When in doubt, start read-only: status, failed work, settings diff, contract drift, and reconcile reports. Mutate only after the operator path says what you are fixing.
