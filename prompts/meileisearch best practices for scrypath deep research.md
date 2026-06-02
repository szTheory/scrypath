Meilisearch for Scrypath: the tired engineer’s field guide

I’m going to treat Scrypath as an Ecto/Phoenix-facing “search read-model orchestrator” whose job is to make Meilisearch feel boring, safe, and observable. I checked your current public package/repo: Hex currently shows scrypath as an Ecto-native search indexing/orchestration library, version 0.3.8, last updated May 27, 2026, and the GitHub mix.exs also has @version "0.3.8" with docs already organized around guides like Meilisearch operations, sync modes, operator tasks, and search/Oban integration.  ￼

The core thesis for your docs:

Postgres is the source of truth. Meilisearch is a fast, denormalized, async search appliance. Scrypath should make the projection, lifecycle, drift, and failure modes explicit.

Meilisearch should feel to Scrypath users like an indexable cache with a search brain, not like a second database they manually babysit.

⸻

1. The 10-minute mental model

Meilisearch is a single-binary search engine with a REST API. It gives you typo tolerance, tokenization, ranking rules, filtering, sorting, faceting, highlighting, cropping, hybrid/vector search options, async indexing tasks, dumps, snapshots, API keys, tenant tokens, and operational endpoints. Official docs emphasize that the basic self-hosted story is intentionally simple: one binary, no external dependencies, no cluster to configure by default, no schema required up front.  ￼

But “simple” does not mean “operationally magical.” The important split is:

Postgres / Ecto
  = durable source of truth, transactions, relational integrity
Scrypath
  = projection layer, sync orchestration, rebuild workflow, drift detector
Meilisearch
  = denormalized search index, ranking/filtering engine, async task processor

A Meilisearch index is like a table-shaped search collection. It has a UID, one primary key, settings, and documents. A document is just a JSON object with fields. The primary key uniquely identifies documents; sending another document with the same primary key overwrites that stored search document.  ￼

For a Phoenix app, a typical projection looks like this:

# Illustrative Scrypath-style shape, not claiming exact public API.
defmodule MyApp.Search.ProductIndex do
  use Scrypath.Index,
    schema: MyApp.Catalog.Product,
    index_uid: "products"
  primary_key :id
  document fn product ->
    %{
      id: product.id,
      title: product.name,
      body: product.description,
      tenant_id: product.org_id,
      category_id: product.category_id,
      status: product.status,
      price_cents: product.price_cents,
      inserted_at: DateTime.to_iso8601(product.inserted_at)
    }
  end
  settings %{
    searchableAttributes: ["title", "body"],
    filterableAttributes: ["tenant_id", "category_id", "status"],
    sortableAttributes: ["price_cents", "inserted_at"],
    displayedAttributes: ["id", "title", "price_cents", "status"]
  }
end

The document is not your domain model. It is a carefully-shaped search card. That distinction is one of the best gifts Scrypath can give its users.

⸻

2. The vocabulary: nouns, verbs, and lifecycle

The nouns

Term	What it means in practice
Instance	A running Meilisearch server process with one database path, API surface, task queue, indexes, keys, dumps/snapshots.
Index	A collection of search documents, roughly analogous to a table or materialized read model. Has a UID and one primary key.  ￼
Document	A JSON object stored in an index. Usually denormalized from one or more Ecto schemas.  ￼
Primary key	Stable unique identifier for documents. In Scrypath, usually the Ecto primary key or a composite synthetic ID.
Settings	The search “schema”: searchable fields, filterable fields, sortable fields, displayed fields, ranking rules, typo tolerance, synonyms, stop words, facets, embedders, etc.
Task	An async operation. Index creation, document writes, settings updates, dumps, snapshots, swaps, deletes, and task operations are task-driven.  ￼
Snapshot	Fast same-version backup of the Meilisearch database. Good for regular restore. Not for version migration.  ￼
Dump	Portable export used for migration/upgrades. Slower to import because data gets reprocessed/reindexed.  ￼
API key	Scoped credential. The master key is for managing keys; regular app/search operations should use scoped keys.  ￼
Tenant token	Search-time restriction token for multi-tenant shared indexes. Useful when browser clients search directly.  ￼
Shard/replica	Enterprise/Cloud horizontal-scaling concepts. Sharding splits data; replication duplicates shards for read availability/throughput.  ￼

The verbs

Meilisearch verbs map nicely to operator workflows:

create index
configure settings
add/update/delete documents
search
multi-search / federated search
wait for task
swap indexes
create snapshot
create dump
export to another instance
rotate keys
compact/delete tasks
upgrade by dump/import

The key lifecycle event is this:

Most writes are accepted now and applied later.

When you add documents or change settings, the API usually returns a taskUid, not “done.” The task moves through statuses like enqueued, processing, succeeded, or failed, and you inspect task details for errors.  ￼

That has direct Scrypath documentation implications:

{:ok, task} = Scrypath.index(Product, product)
# This should not mean "search results now include product".
# It should mean "Meilisearch accepted the operation".
task.uid

The docs should repeatedly distinguish:

accepted by Meilisearch != visible in search
database commit != search index caught up
task succeeded != user sees hydrated DB row, unless app query path does that

⸻

3. What is actually inside Meilisearch?

Under the hood, Meilisearch uses LMDB, a transactional key-value store with ACID properties and memory-mapped I/O. Meilisearch’s docs explain that documents are automatically loaded into memory by the OS page cache, and that the best performance comes when the full dataset fits in RAM, though lower RAM-to-disk ratios can still work depending on workload. They also explicitly recommend low-latency disk such as NVMe and warn against HDD/NFS/network storage for performance-sensitive deployments.  ￼

That gives you the mechanical sympathy:

Meilisearch is not "just using RAM".
It is heavily leaning on mmap + OS page cache + fast local disk.

This is why memory graphs can look surprising. Community operators often notice high memory use; maintainers commonly explain that LMDB/mmap makes the OS cache part of the story. In one Hacker News thread, users described successful small deployments and larger imports, while maintainers emphasized that data lives on disk and the OS caches frequently used pages.  ￼

Indexing is also special. Meilisearch’s technical writing describes LMDB’s strengths and constraints: MVCC allows search to continue while updates are processed, but LMDB has one write transaction at a time, and Meilisearch’s newer indexing pipeline uses chunking and parallel extractors to reduce memory pressure.  ￼

The operator translation:

Search can be fast while indexing is happening.
Indexing still competes for CPU, RAM, disk, and write throughput.
Lots of tiny writes can become task-queue debt.
Huge rebuilds can become memory/disk-pressure events.

⸻

4. How search ranking works: not Lucene cosplay

Meilisearch’s default ranking is not classic BM25-first relevance scoring. It uses an ordered list of ranking rules. Official docs describe the default rules as:

words
typo
proximity
attribute
sort
exactness

Some docs and examples also refer to attributeRank/wordPosition naming depending on context/version, but the important idea is stable: rules are applied in order, and order matters. Meilisearch uses a bucket-sort-like process where each rule narrows or orders candidate results before the next rule runs.  ￼

The memorable version:

Meilisearch ranking is a tournament bracket, not a single magic score.

A practical example:

{
  "rankingRules": [
    "words",
    "typo",
    "proximity",
    "attribute",
    "sort",
    "exactness",
    "price_cents:asc"
  ]
}

But be careful: custom ranking can make product search feel “business-smart,” or it can make search feel weird and unfair. For Scrypath docs, explain custom ranking as business tie-breakers, not a replacement for relevance.

Tokenization is multilingual and powered by Meilisearch’s tokenizer stack. Docs describe tokenization as splitting text into tokens and note language-specific handling for languages such as Chinese, Japanese, Hebrew, Thai, and Khmer.  ￼

Search also supports filtering, sorting, highlighting, cropping, facets, multi-search, and federated search. Filtering only works on attributes declared as filterableAttributes, and that setting is empty by default.  ￼

⸻

5. The first major footgun: settings are migrations

In Meilisearch, settings are not decoration. They are the shape of the index.

Some setting changes are cheap. Some require a full reindex. Official docs recommend configuring settings before adding documents, because changing settings like searchable attributes, filterable attributes, sortable attributes, stop words, synonyms, typo tolerance, embedders, dictionary settings, separator tokens, and proximity precision can trigger reindexing.  ￼

This is probably the single most important Scrypath documentation idea:

Treat index settings like database migrations.

Bad path:

1. Import 10M products.
2. Realize category_id must be filterable.
3. PATCH filterableAttributes.
4. Surprise: expensive reindex.

Good path:

1. Define settings in code.
2. Apply settings before first import.
3. Diff live settings against code.
4. For reindex-triggering changes, rebuild into a temp index.
5. Atomically swap.

Scrypath should make that workflow first-class:

mix scrypath.settings.diff
mix scrypath.index.rebuild products
mix scrypath.index.swap products products__build_20260530_1530

Even if those exact commands do not exist yet, that is the operator-shaped interface your users will want.

⸻

6. The second major footgun: async tasks are the truth

Every indexing library eventually has to pick a stance on consistency. Meilisearch forces the issue because long operations are async tasks. Official docs list many async operations: index create/update/swap/delete, settings updates, document add/update/delete, task cancel/delete, dumps, and snapshots.  ￼

A document write looks conceptually like this:

curl -X POST "$MEILI/indexes/products/documents" \
  -H "Authorization: Bearer $MEILI_ADMIN_KEY" \
  -H "Content-Type: application/json" \
  --data-binary @products.json

The response is not “your products are searchable.” It is more like:

{
  "taskUid": 42,
  "indexUid": "products",
  "status": "enqueued",
  "type": "documentAdditionOrUpdate"
}

Then you poll or wait:

curl "$MEILI/tasks/42" \
  -H "Authorization: Bearer $MEILI_ADMIN_KEY"

The Scrypath docs should make sync modes explicit:

# Fast path: enqueue and return.
Scrypath.upsert(Product, product, wait: false)
# Admin/import path: block until Meilisearch says the task succeeded.
Scrypath.upsert(Product, product, wait: true, timeout: :timer.seconds(30))
# Test path: deterministic.
Scrypath.upsert!(Product, product, wait: true)
assert Scrypath.search(Product, "espresso").hits_count == 1

The design smell to avoid is hidden waiting. Waiting is sometimes right, but it should be named.

⸻

7. Happy-path architecture for a Phoenix app

A good production architecture looks like this:

Browser / LiveView / API client
        |
        v
Phoenix app
        |
        | 1. transactional writes
        v
Postgres
        |
        | 2. after-commit/outbox/Oban job
        v
Scrypath sync worker
        |
        | 3. add/update/delete document task
        v
Meilisearch
        |
        | 4. search returns IDs + lightweight fields
        v
Phoenix hydrates authoritative records from Postgres

The safest query pattern is often:

Meilisearch finds candidate IDs.
Postgres hydrates the records the user is allowed to see.
Phoenix preserves Meilisearch order.

Example:

{:ok, %{hits: hits}} =
  Scrypath.search(Product, "espresso machine",
    filter: "tenant_id = #{tenant_id} AND status = published",
    attributes_to_retrieve: ["id"]
  )
ids = Enum.map(hits, & &1["id"])
products =
  Product
  |> where([p], p.id in ^ids)
  |> where([p], p.org_id == ^tenant_id)
  |> Repo.all()
  |> sort_in_search_order(ids)

Why hydrate from Postgres?

Authorization stays authoritative.
Sensitive fields do not leak from search documents.
Deleted/hidden records can be filtered defensively.
Search remains a projection, not a system of record.

For many apps, returning fully-renderable cards directly from Meilisearch is fine. But Scrypath should document both modes:

Fast UI mode: search docs contain enough display fields.
Strict mode: search returns IDs, app hydrates from DB.

⸻

8. Stand-up: development Docker Compose

For local development, make it boring.

services:
  meilisearch:
    image: getmeili/meilisearch:${MEILI_VERSION:?pin-an-exact-version}
    command:
      - meilisearch
      - --db-path
      - /meili_data
      - --http-addr
      - 0.0.0.0:7700
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

The /health endpoint returns availability status and is the obvious readiness probe.  ￼

For test suites, use either a throwaway index UID per test module or a test instance with aggressive cleanup:

index_uid = "products_test_#{System.unique_integer([:positive])}"
on_exit(fn ->
  Scrypath.delete_index(index_uid)
end)

Do not let tests assume indexing is synchronous unless Scrypath explicitly waits for tasks.

⸻

9. Stand-up: production checklist

Meilisearch’s own production checklist includes using a strong master key of at least 16 bytes, running in production environment mode, putting the service behind HTTPS/reverse proxy, scheduling snapshots/backups, using systemd or another supervisor, and reviewing RAM/threading behavior.  ￼

For Scrypath docs, the production baseline should read like this:

[ ] Pin the Meilisearch version. Do not run "latest".
[ ] Set MEILI_ENV=production.
[ ] Use a strong master key, stored in a secret manager.
[ ] Create scoped API keys; do not use the master key from app code.
[ ] Put Meilisearch on private networking.
[ ] Terminate TLS at a reverse proxy/load balancer if exposed beyond localhost/private VPC.
[ ] Use persistent local SSD/NVMe-style storage.
[ ] Do not place the live data.ms database on S3FS, NFS, or slow network disks.
[ ] Configure snapshots/dumps and test restores.
[ ] Export metrics/stats/tasks into your observability stack.
[ ] Capacity-test initial import and rebuild before launch.

Official docs are especially clear on keys: the master key has full control and should only be used for creating/deleting API keys; search, indexing, settings, and index-management operations should use scoped keys.  ￼

A sane key split:

MEILI_MASTER_KEY
  - stored in secret manager
  - used rarely by operator tooling
MEILI_ADMIN_INDEXING_KEY
  - used by Scrypath server-side sync workers
  - allowed actions: documents/settings/indexes/tasks as needed
  - never sent to browser
MEILI_SEARCH_KEY
  - used for public search if direct browser search is allowed
  - narrow index/action permissions
TENANT TOKENS
  - generated by backend when shared multi-tenant index is searched directly

Tenant tokens are specifically designed to restrict search visibility within a shared index; they are useful when multiple tenants share an index and browser/client-side search talks directly to Meilisearch.  ￼

⸻

10. Minimal index bootstrap

A safe bootstrap sequence is:

# 1. Create index explicitly.
curl -X POST "$MEILI/indexes" \
  -H "Authorization: Bearer $MEILI_ADMIN_KEY" \
  -H "Content-Type: application/json" \
  --data '{
    "uid": "products",
    "primaryKey": "id"
  }'
# 2. Apply settings before importing documents.
curl -X PATCH "$MEILI/indexes/products/settings" \
  -H "Authorization: Bearer $MEILI_ADMIN_KEY" \
  -H "Content-Type: application/json" \
  --data '{
    "searchableAttributes": ["title", "body"],
    "filterableAttributes": ["tenant_id", "category_id", "status"],
    "sortableAttributes": ["price_cents", "inserted_at"],
    "displayedAttributes": ["id", "title", "price_cents", "status"]
  }'
# 3. Add documents.
curl -X POST "$MEILI/indexes/products/documents" \
  -H "Authorization: Bearer $MEILI_ADMIN_KEY" \
  -H "Content-Type: application/json" \
  --data-binary @products.json

Explicit index creation is better than letting the first document write create an index implicitly. Official docs warn that implicit creation is convenient but harder to diagnose in production because it bundles multiple actions into one task.  ￼

⸻

11. Rebuild without downtime: temp index + swap

The golden path for reindexing:

1. Create products__build_20260530_1530.
2. Apply desired settings.
3. Bulk import from Postgres.
4. Wait for all tasks to succeed.
5. Run smoke searches.
6. Swap products <-> products__build_20260530_1530.
7. Delete the old index now sitting under the temp UID.

Conceptually:

BUILD="products__build_20260530_1530"
curl -X POST "$MEILI/indexes" \
  -H "Authorization: Bearer $MEILI_ADMIN_KEY" \
  -H "Content-Type: application/json" \
  --data "{\"uid\":\"$BUILD\",\"primaryKey\":\"id\"}"
curl -X PATCH "$MEILI/indexes/$BUILD/settings" \
  -H "Authorization: Bearer $MEILI_ADMIN_KEY" \
  -H "Content-Type: application/json" \
  --data @products.settings.json
curl -X POST "$MEILI/indexes/$BUILD/documents" \
  -H "Authorization: Bearer $MEILI_ADMIN_KEY" \
  -H "Content-Type: application/json" \
  --data-binary @products.json
# Wait for tasks, then:
curl -X POST "$MEILI/swap-indexes" \
  -H "Authorization: Bearer $MEILI_ADMIN_KEY" \
  -H "Content-Type: application/json" \
  --data "[
    {\"indexes\": [\"products\", \"$BUILD\"]}
  ]"
# After verifying:
curl -X DELETE "$MEILI/indexes/$BUILD" \
  -H "Authorization: Bearer $MEILI_ADMIN_KEY"

This should be a marquee Scrypath feature. The operator should not have to invent this under pressure.

⸻

12. Sync from Ecto: use an outbox, not vibes

The robust pattern is:

Ecto transaction commits domain change.
Same transaction records a search-sync event.
Oban/Scrypath worker processes event after commit.
Worker sends idempotent upsert/delete to Meilisearch.
Worker records task UID and result.

Sketch:

Repo.transaction(fn ->
  product = Repo.insert!(changeset)
  SearchOutbox.enqueue!(
    schema: Product,
    id: product.id,
    op: :upsert
  )
  product
end)

Worker:

def perform(%Oban.Job{args: %{"schema" => "Product", "id" => id, "op" => "upsert"}}) do
  product =
    Product
    |> Repo.get!(id)
    |> Repo.preload([:category, :brand])
  doc = MyApp.Search.ProductDocument.render(product)
  with {:ok, task} <- Meili.add_or_update("products", [doc]),
       :ok <- Meili.wait_for_task(task.uid, timeout: 30_000) do
    :ok
  end
end

The important properties:

Idempotent: repeated upsert of the same primary key is safe.
Durable: if Meilisearch is down, Oban retries.
Observable: every job can store task UID and failure reason.
Repairable: full rebuild from Postgres is always possible.

Scrypath should encourage users to think in these categories:

live sync       = keep index warm during normal writes
full rebuild    = repair/recompute the whole projection
settings diff   = detect and plan search-schema changes
task monitor    = know when Meilisearch is behind or failing

Your mix.exs already shows optional Oban and docs around sync modes/operator workflows, which is directionally perfect for this story.  ￼

⸻

13. Backups, DR, and restores

The beautiful disaster-recovery truth:

If Postgres is source of truth, Meilisearch is rebuildable. But rebuilds may be slow, so you still want backups.

Meilisearch has two primary backup/migration artifacts:

Artifact	Use it for	Tradeoff
Snapshot	Fast same-version restore of the current database.	Not portable across versions; bigger; meant for regular backups.
Dump	Version migration, portability, reimport.	Slower because import reprocesses/reindexes data.

Official docs make this distinction directly: snapshots are exact copies of the data.ms database and are faster to import, while dumps are portable blueprints useful for migration and upgrades.  ￼

A practical DR policy:

RPO:
  - Search data RPO is usually "whatever Postgres + outbox can replay".
  - Snapshots reduce time-to-recover if the index is large.
RTO:
  - Fastest: restore same-version snapshot.
  - Medium: import dump.
  - Slowest but most trustworthy: rebuild from Postgres.
Backup schedule:
  - Daily snapshot for ordinary restore.
  - Dump before every Meilisearch version upgrade.
  - Copy artifacts off the instance.
  - Test restore in staging.

Meilisearch docs suggest daily snapshots as a good starting point, creating dumps before upgrades, testing restore procedures, and storing backups off-server.  ￼

Create a dump:

curl -X POST "$MEILI/dumps" \
  -H "Authorization: Bearer $MEILI_ADMIN_KEY"

Dump creation is async and returns a task. The time required is proportional to database size.  ￼

Restore posture for Scrypath docs:

1. Bring up Meilisearch at the intended version.
2. Restore snapshot or import dump.
3. Run /health.
4. Compare /stats document counts to expected counts.
5. Run known smoke queries.
6. Resume Scrypath sync workers.
7. Replay missed outbox events if needed.

Do not store the live database on S3/S3FS/network-object-storage. A Meilisearch maintainer explicitly recommended against putting the active database on S3-like storage and recommended fast disk such as NVMe; storing dump/snapshot artifacts in S3 is different and fine.  ￼

⸻

14. Upgrades and migrations

The operationally safe rule:

Never casually point a new Meilisearch binary at an old data.ms directory.

Official upgrade docs state that Meilisearch databases are currently compatible only with the version that created them, and that dumps are the migration path from older to newer versions.  ￼

A safe upgrade runbook:

1. Read the release notes.
2. Freeze risky index-setting changes.
3. Create a dump from current production.
4. Restore/import dump into staging on target version.
5. Run Scrypath smoke checks:
   - health
   - stats
   - index list
   - settings diff
   - known queries
   - filtering/sorting/facets
6. Create a fresh production dump.
7. Replace production with target version using the documented import path.
8. Resume sync.
9. Watch tasks, latency, disk, RSS, and errors.

If Scrypath grows an operator CLI, this would be gold:

mix scrypath.doctor
mix scrypath.smoke products
mix scrypath.settings.diff --all
mix scrypath.tasks.failed --since 24h

Meilisearch also has an /export endpoint for transferring data directly between instances, useful for migration, replicas, and scaling workflows where a dump file is not the right mechanism.  ￼

⸻

15. Observability: what to watch

At minimum, operators need four views:

/health   - is it alive?
/stats    - what is in it?
/tasks    - what is it doing or failing to do?
/metrics  - what is Prometheus seeing?

The /stats endpoint reports database size, last update, per-index document count, indexing status, and field distribution.  ￼

The /tasks endpoint exposes async operations and supports filtering by index UID, status, type, and date ranges.  ￼

Prometheus metrics are available through /metrics when enabled, though the docs mark the feature as experimental. Metrics include database size, batch progress, HTTP request totals, response times, index/document counts, and task counts.  ￼

Scrypath should translate this into app-level signals:

search.index.products.document_count
search.index.products.last_successful_sync_at
search.index.products.pending_tasks
search.index.products.failed_tasks_24h
search.index.products.settings_drift
search.index.products.rebuild_in_progress
search.index.products.lag_seconds

Useful operator commands:

curl "$MEILI/health" \
  -H "Authorization: Bearer $MEILI_ADMIN_KEY"
curl "$MEILI/stats" \
  -H "Authorization: Bearer $MEILI_ADMIN_KEY"
curl "$MEILI/tasks?statuses=failed&limit=20" \
  -H "Authorization: Bearer $MEILI_ADMIN_KEY"
curl "$MEILI/tasks?statuses=enqueued,processing&indexUids=products" \
  -H "Authorization: Bearer $MEILI_ADMIN_KEY"

The task database itself can become an operational object. Docs note limits around task DB size and task counts, and Meilisearch exposes task deletion and compaction workflows.  ￼

Real-world issue trackers show this is not theoretical: one GitHub issue involved task DB growth, “no space left on device,” and over a million tasks.  ￼

Scrypath docs should say plainly:

If you generate lots of tiny writes, you are also generating lots of tasks.
Batch, debounce, compact, and monitor.

⸻

16. Capacity planning: RAM, CPU, disk

Meilisearch’s storage docs are the best starting point: it benefits from enough RAM for hot data and from fast low-latency disk; NVMe is preferable to HDD/NFS/network storage.  ￼

Indexing memory is tunable. Meilisearch docs say indexing uses at most two-thirds of available RAM by default, can be limited with --max-indexing-memory, and indexing threads can be adjusted with --max-indexing-threads; they also warn that using all memory/cores for indexing can hurt search or trigger OOM behavior.  ￼

Practical guidance:

Small app:
  - 1 node, persistent SSD, snapshots, app-side rebuild.
  - Keep docs lean.
  - Batch writes.
Medium app:
  - Dedicated VM/container.
  - Explicit indexing memory/thread settings.
  - Prometheus metrics.
  - Rebuild rehearsals.
  - Snapshot + dump policy.
Large/high-churn app:
  - Load-test import and steady-state writes.
  - Separate rebuild windows from peak traffic.
  - Consider Meilisearch Cloud/Enterprise sharding/replication.
  - Consider whether Elasticsearch/OpenSearch/Typesense/Algolia-like alternatives fit better.

Payload limits also matter. Meilisearch’s document API has a default payload limit of 100 MB, and increasing batch size can increase RAM pressure.  ￼

For Scrypath defaults:

Prefer "moderately chunky batches", not one document per task and not monster payloads.
Expose batch size as config.
Document the tradeoff.

Example:

config :scrypath,
  batch_size: 1_000,
  task_wait_timeout: :timer.minutes(5),
  max_retries: 10

Do not promise a universal batch size. Tell users to tune with their document shape, hardware, and indexing latency budget.

⸻

17. Terraform sketch: boring EC2 + persistent disk

This is not a full production module. It is the minimum shape that communicates the right architecture.

variable "vpc_id" {}
variable "subnet_id" {}
variable "app_security_group_id" {}
variable "meili_version" {
  description = "Pin an exact Meilisearch image tag, e.g. v1.x.y. Do not use latest."
  type        = string
}
# In real production, do not put this in plain Terraform variables/state.
# Fetch it at boot from AWS Secrets Manager or SSM Parameter Store.
variable "meili_master_key" {
  type      = string
  sensitive = true
}
resource "aws_security_group" "meili" {
  name        = "meilisearch"
  description = "Meilisearch private access from app only"
  vpc_id      = var.vpc_id
  ingress {
    description     = "Meilisearch API from Phoenix app"
    from_port       = 7700
    to_port         = 7700
    protocol        = "tcp"
    security_groups = [var.app_security_group_id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_ebs_volume" "meili_data" {
  availability_zone = "us-east-1a"
  size              = 100
  type              = "gp3"
  encrypted         = true
  tags = {
    Name = "meilisearch-data"
  }
}
resource "aws_instance" "meili" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = "t3.large"
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.meili.id]
  user_data = <<-EOF
    #!/usr/bin/env bash
    set -euo pipefail
    dnf install -y docker
    systemctl enable --now docker
    mkdir -p /var/lib/meilisearch
    # Real production should format/mount the attached EBS volume carefully,
    # add /etc/fstab, and alert if the mount is absent.
    docker run -d \
      --name meilisearch \
      --restart unless-stopped \
      -p 7700:7700 \
      -e MEILI_ENV=production \
      -e MEILI_MASTER_KEY='${var.meili_master_key}' \
      -e MEILI_DB_PATH=/meili_data \
      -v /var/lib/meilisearch:/meili_data \
      getmeili/meilisearch:${var.meili_version}
  EOF
  tags = {
    Name = "meilisearch"
  }
}
resource "aws_volume_attachment" "meili_data" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.meili_data.id
  instance_id = aws_instance.meili.id
}

The important bits are not AWS-specific:

private network
pinned version
production mode
strong secret
persistent encrypted disk
local-ish low-latency storage
no public admin endpoint
supervised process
off-host backups

If using ECS/Kubernetes, the same shape applies:

one Meilisearch container
persistent volume
readiness probe /health
resource requests/limits tested against indexing workloads
secret-mounted master/admin keys
network policy allowing only app/admin traffic

⸻

18. Terraform-ish backup job

Do not overcomplicate your first DR story. Trigger dumps, copy them off-host, and rehearse import.

Pseudo-cron:

#!/usr/bin/env bash
set -euo pipefail
TASK_JSON="$(
  curl -fsS -X POST "$MEILI/dumps" \
    -H "Authorization: Bearer $MEILI_ADMIN_KEY"
)"
TASK_UID="$(echo "$TASK_JSON" | jq -r '.taskUid')"
echo "Started Meilisearch dump task $TASK_UID"
while true; do
  TASK="$(
    curl -fsS "$MEILI/tasks/$TASK_UID" \
      -H "Authorization: Bearer $MEILI_ADMIN_KEY"
  )"
  STATUS="$(echo "$TASK" | jq -r '.status')"
  case "$STATUS" in
    succeeded) break ;;
    failed)
      echo "$TASK" >&2
      exit 1
      ;;
    *)
      sleep 5
      ;;
  esac
done
LATEST_DUMP="$(ls -t /var/lib/meilisearch/dumps/*.dump | head -n1)"
aws s3 cp "$LATEST_DUMP" "s3://my-search-backups/meilisearch/$(basename "$LATEST_DUMP")"

The docs should call this “backup verification,” not merely “backup creation.” The artifact is not a backup until someone has restored it.

⸻

19. Cloud, self-hosting, and horizontal scale

Meilisearch Cloud is the easiest production route if users do not want to own ops. Official deployment docs say Cloud is recommended for most production use cases and handles provisioning, updates, backups, and scaling.  ￼

Self-hosting is attractive when users want:

private infrastructure
cost control
local/dev parity
custom networking
open-source-only deployment
data residency control

The tradeoff is they own:

upgrades
snapshots/dumps
metrics
disk sizing
memory pressure
rebuilds
task queue hygiene
security hardening
incident response

Horizontal scale is changing. Official docs describe sharding and replication as Enterprise Edition features, with sharding splitting indexes across remotes and replication duplicating shards across remotes; a leader coordinates writes/topology and non-leaders reject writes.  ￼

Meilisearch also announced Cloud support for sharding and replication in April 2026, framing sharding as data/scale and replication as read availability/read throughput, while noting write high availability was not part of that launch.  ￼

Scrypath docs should therefore avoid implying the default OSS deployment is a distributed search cluster. A precise sentence:

The default self-hosted Meilisearch mental model is a single search node. Cloud/Enterprise deployments can add sharding and replication, but Scrypath should still treat Meilisearch as an eventually-consistent search projection.

⸻

20. Common operator tasks

Task: “Is Meilisearch healthy?”

curl -fsS "$MEILI/health" \
  -H "Authorization: Bearer $MEILI_ADMIN_KEY"

Expected:

{ "status": "available" }

Task: “Is indexing backed up?”

curl -fsS "$MEILI/tasks?statuses=enqueued,processing&limit=100" \
  -H "Authorization: Bearer $MEILI_ADMIN_KEY"

Look for old tasks, repeated failures, and huge queues.

Task: “How many docs are indexed?”

curl -fsS "$MEILI/stats" \
  -H "Authorization: Bearer $MEILI_ADMIN_KEY"

Compare against Postgres counts:

select count(*) from products where status = 'published';

Task: “Are settings drifted?”

curl -fsS "$MEILI/indexes/products/settings" \
  -H "Authorization: Bearer $MEILI_ADMIN_KEY" \
  > live.settings.json
diff -u desired.products.settings.json live.settings.json

Scrypath should make this prettier:

products:
  filterableAttributes:
    live:    ["tenant_id", "status"]
    desired: ["tenant_id", "status", "category_id"]
    impact: full reindex required

Task: “Can I rotate keys?”

Yes, but document the blast radius. Resetting the master key invalidates all API keys.  ￼

Safe pattern:

1. Create new scoped key.
2. Deploy app with both old/new acceptable if needed.
3. Switch app to new key.
4. Verify indexing/search.
5. Delete old key.

Task: “Can I delete old tasks?”

Yes, with filters. But make sure you retain enough operational history for incidents. Task deletion and compaction are part of task DB hygiene.  ￼

⸻

21. The footgun catalog

Footgun 1: treating Meilisearch as the source of truth

Bad:

User changed visibility in Postgres.
Old visible doc remains searchable.
Frontend trusts Meilisearch result.
Private object leaks.

Better:

Index only safe display fields.
Filter by tenant/status.
Hydrate sensitive records from Postgres.
Use Scrypath repair/rebuild jobs.

Footgun 2: assuming write-after-read consistency

Bad:

Scrypath.upsert(Product, product)
assert search("new title") == [product]

Better:

task = Scrypath.upsert!(Product, product)
Scrypath.wait!(task)
assert search("new title") == [product]

Footgun 3: changing settings casually

filterableAttributes, sortableAttributes, searchableAttributes, synonyms, stop words, typo tolerance, embedders, dictionary settings, proximity precision, and separator-token settings can force reindexing.  ￼

Better:

settings change -> impact analysis -> temp index rebuild -> swap

Footgun 4: too many filterable/sortable/searchable fields

Bad:

{
  "searchableAttributes": ["*"],
  "filterableAttributes": ["*"],
  "sortableAttributes": ["*"]
}

Better:

{
  "searchableAttributes": ["title", "description"],
  "filterableAttributes": ["tenant_id", "status", "category_id"],
  "sortableAttributes": ["price_cents", "inserted_at"]
}

Every declared capability has indexing and storage consequences.

Footgun 5: indexing giant documents

Bad:

{
  "id": 123,
  "title": "Nice article",
  "html": "<entire rendered page with nav/footer/comments/tracking junk>"
}

Better:

{
  "id": 123,
  "title": "Nice article",
  "body": "clean searchable text",
  "summary": "short display snippet"
}

Use displayedAttributes, attributesToRetrieve, highlighting, and cropping to control returned payloads.

Footgun 6: one task per tiny write forever

Bad:

Every page view updates views_count in Meilisearch.
Every like updates like_count in Meilisearch.
Every inventory tick updates every product immediately.

Better:

Batch.
Debounce.
Only index fields that affect search.
Use scheduled sync for high-churn counters.

Community reports include cases where frequent updates led to long pending-task backlogs, and official docs expose task-management endpoints because the task database itself needs lifecycle care.  ￼

Footgun 7: live DB on network/object storage

Bad:

data.ms on S3FS/NFS/slow network volume

Better:

data.ms on fast persistent local/block storage
dumps/snapshots copied to object storage

This matches both official storage guidance and maintainer recommendations.  ￼

Footgun 8: using master key everywhere

Bad:

Browser has master key.
Phoenix app uses master key for ordinary searches.
CI logs master key.

Better:

master key only manages API keys
server-side admin/indexing key
frontend search key or tenant token

Official docs are explicit that exposing the master key grants complete control.  ￼

Footgun 9: version drift

Bad:

docker pull getmeili/meilisearch:latest
restart
hope

Better:

pin exact version
dump before upgrade
restore into staging
test
upgrade deliberately

Database compatibility across versions is an official upgrade concern.  ￼

Footgun 10: creating an index per tenant by default

Sometimes per-tenant indexes are right, but usually they are an operational tax:

more indexes
more settings drift
more rebuilds
more task overhead
harder global search
harder migrations

Default to shared index with tenant_id filter or tenant tokens unless tenants truly need different settings, languages, ranking, isolation, or lifecycle.

Footgun 11: implicit index creation in production

Explicit creation is easier to diagnose and safer to operate. Meilisearch docs specifically recommend explicit creation in production because implicit creation combines multiple actions into one task.  ￼

Footgun 12: full rebuild into the live index

Bad:

DELETE all docs from products
bulk import new docs
hope users do not search mid-import

Better:

products__build_x
import
wait
smoke test
swap
delete old

⸻

22. Patterns that Scrypath should teach

Pattern: projection modules

Give users a place to define the search document deliberately.

defmodule MyApp.Search.ProductDocument do
  def render(product) do
    %{
      id: product.id,
      title: product.name,
      body: normalize_text(product.description),
      tenant_id: product.org_id,
      status: Atom.to_string(product.status),
      category_id: product.category_id,
      price_cents: product.price_cents
    }
  end
end

Pattern: settings as code

defmodule MyApp.Search.ProductSettings do
  def settings do
    %{
      searchableAttributes: ["title", "body"],
      filterableAttributes: ["tenant_id", "status", "category_id"],
      sortableAttributes: ["price_cents", "inserted_at"],
      displayedAttributes: ["id", "title", "price_cents", "status"],
      rankingRules: [
        "words",
        "typo",
        "proximity",
        "attribute",
        "sort",
        "exactness"
      ]
    }
  end
end

Pattern: settings impact analysis

Scrypath should tell users whether a change is hot-apply-safe or rebuild-worthy.

Change:
  filterableAttributes added category_id
Impact:
  full reindex required
Recommended:
  mix scrypath.index.rebuild products --swap

Pattern: deterministic tests

test "newly indexed products are searchable" do
  product = insert(:product, name: "Sleepy Espresso Machine")
  task = Scrypath.upsert!(Product, product)
  Scrypath.wait!(task)
  assert {:ok, results} = Scrypath.search(Product, "sleepy espresso")
  assert Enum.any?(results.hits, &(&1["id"] == product.id))
end

Pattern: repair from source of truth

mix scrypath.rebuild products --from-postgres --batch-size 1000 --swap

Every adoption doc should say:

If search gets weird, rebuild it.
If rebuild cannot fix it, your projection or settings are wrong.

Pattern: freshness badge

For admin dashboards:

Products index:
  documents: 1,204,992
  pending tasks: 12
  failed tasks last 24h: 0
  oldest pending task age: 38s
  last successful rebuild: 2026-05-29 03:10 UTC
  settings drift: none

⸻

23. What people seem to like

The repeated community theme is that Meilisearch is easy to stand up and pleasant to use compared with heavier search stacks. Hacker News users describe small Docker deployments, simple Kubernetes operation, and successful use with million-plus-record datasets; another user described it as easy to run multiple indexes.  ￼

That matches the product’s design: single binary, REST API, reasonable defaults, typo tolerance, and little ceremony.  ￼

For Scrypath docs, lean into that:

You do not need to become a search engineer to get good search.
But you do need to understand the lifecycle:
settings -> documents -> tasks -> backups -> rebuilds.

⸻

24. What people complain about or trip over

The most credible complaints cluster around:

memory surprises
indexing spikes
large imports
task backlogs
version migrations
lack of default distributed-cluster mental model
sync/staleness concerns

Community comments include reports of high apparent memory use, OOM during indexing, and the need for larger machines during import than during steady-state search. Maintainers often connect this back to mmap/page-cache behavior and indexing resource needs.  ￼

This should not be framed as “Meilisearch bad.” It is just the cost model:

Fast search wants precomputed indexes.
Precomputed indexes cost CPU/RAM/disk to build.
Async writes improve API responsiveness but create consistency and queue semantics.

Scrypath can make those costs less surprising.

⸻

25. A “doctor” command would be incredibly valuable

For your user persona — adopter, evaluator, integrator, day-two operator — the most helpful Scrypath feature may be a diagnostic command.

Example output:

$ mix scrypath.doctor
Meilisearch
  URL:              configured
  health:           available
  version:          v1.x.y
  env:              production
  auth:             scoped admin key works
  metrics:          enabled
Indexes
  products:
    exists:         yes
    primary key:    id
    docs:           124,991
    settings drift: no
    pending tasks:  0
    failed 24h:     0
  articles:
    exists:         yes
    primary key:    id
    docs:           48,110
    settings drift: yes
      filterableAttributes differs
      impact: full reindex recommended
Backups
  latest dump:      2026-05-30 04:00 UTC
  latest snapshot:  unknown
  restore tested:   not recorded
Recommendations
  - Rebuild articles using temp index + swap.
  - Configure snapshot/dump verification metadata.

This turns Meilisearch from a black box into an inspectable subsystem.

⸻

26. Documentation structure I’d give Scrypath

A strong docs IA:

1. Why Scrypath?
   - Ecto source of truth
   - Meilisearch as projection
   - What Scrypath automates
2. Quickstart
   - Docker Compose
   - define index
   - apply settings
   - index records
   - search
3. Core concepts
   - index
   - document
   - settings
   - task
   - rebuild
   - sync mode
4. Designing documents
   - denormalization
   - IDs
   - tenant fields
   - searchable vs displayed vs filterable
   - sensitive data
5. Syncing changes
   - after commit
   - Oban/outbox
   - async vs wait
   - failure/retry
6. Operations
   - health
   - stats
   - tasks
   - metrics
   - backups
   - upgrades
   - rebuilds
   - settings drift
7. Production
   - security
   - keys
   - private networking
   - storage
   - capacity planning
   - Terraform examples
8. Troubleshooting
   - document not found
   - filter does not work
   - search stale
   - high memory
   - OOM during import
   - failed tasks
   - version mismatch

The Scrypath docs should use “operator notes” in sidebars:

Operator note:
Changing filterableAttributes may reindex the whole index.
For large indexes, prefer temp-index rebuild + swap.

That style respects users’ attention while preventing production surprises.

⸻

27. Pasteable context for Codex/Claude

Here is a compact prompt block you can paste into another LLM session:

We are improving docs for Scrypath, an Elixir/Phoenix/Ecto library that integrates with Meilisearch.
Core model:
- Postgres/Ecto is the source of truth.
- Meilisearch is an async, denormalized search projection/read model.
- Scrypath should own projection definitions, settings-as-code, sync orchestration, rebuilds, task monitoring, and operator ergonomics.
Meilisearch concepts to teach:
- Instance: running Meilisearch server.
- Index: collection of JSON documents with UID, primary key, settings.
- Document: denormalized searchable JSON object, not domain model.
- Settings: search schema; searchable/filterable/sortable/displayed attributes, ranking rules, synonyms, stop words, typo tolerance, facets, embedders.
- Task: async operation returned by writes/settings/index ops/dumps/snapshots. Accepted != visible.
- Snapshot: fast same-version backup.
- Dump: portable migration/upgrade export, slower import.
- API keys: master key only for key management; app should use scoped keys.
- Tenant tokens: restrict searches in shared multi-tenant indexes.
Golden paths:
1. Define document projection in code.
2. Define settings in code.
3. Create index explicitly.
4. Apply settings before importing documents.
5. Bulk import in batches.
6. Wait for tasks during admin/test/rebuild flows.
7. Live sync via after-commit outbox/Oban worker.
8. Make upserts idempotent by stable primary key.
9. Rebuild into temp index and swap for zero downtime.
10. Keep Postgres as source of truth and hydrate sensitive records from DB.
Production guidance:
- Pin exact Meilisearch version; do not use latest.
- Set MEILI_ENV=production.
- Use strong master key, secret manager, scoped API keys.
- Keep Meilisearch private or behind TLS/reverse proxy.
- Use persistent fast local/block SSD/NVMe storage.
- Do not put live data.ms on S3FS/NFS/network object storage.
- Configure snapshots/dumps and test restore.
- Monitor /health, /stats, /tasks, /metrics.
- Watch task backlog, failed tasks, indexing latency, disk, RSS, DB size.
- Batch/debounce high-churn writes.
- Treat settings changes like migrations because many trigger reindexing.
- Use temp index + swap for large/reindexing changes.
Footguns to document:
- Meilisearch as source of truth.
- Assuming writes are immediately searchable.
- Changing filterable/searchable/sortable settings casually.
- Indexing giant documents or sensitive fields.
- Too many filterable/sortable/searchable attributes.
- One tiny indexing task per domain event forever.
- Exposing master/admin keys.
- Using implicit index creation in production.
- Running unpinned latest image.
- Upgrading without dump/import rehearsal.
- Full rebuild into live index instead of temp + swap.
- Ignoring task DB growth/compaction.
- Under-sizing RAM/disk for imports.
Desired Scrypath features/docs:
- mix scrypath.doctor
- mix scrypath.settings.diff
- mix scrypath.index.rebuild --swap
- mix scrypath.tasks.failed
- mix scrypath.smoke
- guides for Docker Compose, Terraform, backups, upgrades, DR, and troubleshooting.

⸻

28. The one-page version

Meilisearch is a wonderful fit for Scrypath because it is approachable, fast, and operationally simpler than heavier search stacks. But the library should not hide the wrong things.

Hide the plumbing:

HTTP calls
task polling
batching
index creation
settings application
swap mechanics
Oban retries

Expose the truths:

search is eventually consistent
settings are migrations
documents are projections
backups matter
rebuilds are normal
Postgres remains source of truth

The most memorable line for Scrypath adopters:

Meilisearch is not your database. It is your search-shaped shadow of the database. Scrypath’s job is to keep the shadow accurate, observable, and easy to rebuild.