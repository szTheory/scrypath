# Phase 90: Async Execution and Error Propagation - Discuss Phase

## Core Decisions & Grey Area Resolutions

Based on deep research into Elixir open-source library best practices, the Scrypath design goals, and Oban idioms, here is the cohesive architecture for Phase 90.

### 1. Worker Design: Internal Workers + Config over Public Macros
**Decision: Use the internal `Scrypath.Sync.RelatedWorker` and do not expose a `use Scrypath.Oban.Worker` macro.**

* **The Rationale**: Exposing a macro forces the developer to write boilerplate just to proxy calls to the library. Idiomatic Elixir libraries prefer configuration over macros.
* **The DX**: Developers should never have to think about the worker module. They should just call `Scrypath.sync_related(Post, records, sync_mode: :oban, oban: [queue: :search, max_attempts: 5])`. The library handles the enqueueing using its internal worker.
* **Flexibility**: If a user has a highly bespoke need, they can bypass `sync_mode: :oban` and enqueue their own Oban job that simply calls `Scrypath.sync_related(..., sync_mode: :inline)` inside its `perform/1` function.

### 2. Oban Error Handling: Distinguish Transient vs. Unrecoverable
**Decision: `RelatedWorker` must bubble up transient errors and explicitly cancel on unrecoverable errors to prevent retry storms and silent drops.**

Currently, `Scrypath.Sync.RelatedWorker` ends with `:ok` regardless of whether `Scrypath.Sync.sync_records` succeeds or fails. This is a critical silent drop.

* **Transient Errors (`{:error, reason}`)**: Network timeouts or 502/503s from Meilisearch must be returned as `{:error, reason}`. This allows Oban's standard exponential backoff to handle the retry safely.
* **Unrecoverable Errors (`{:cancel, reason}`)**: If `sync_records` fails because of a missing index configuration, invalid schema, or 400 Bad Request, retrying will never fix it. The worker must intercept these structured errors and return `{:cancel, {:invalid_request, reason}}` (or `:discard`). This halts the Oban retry cycle immediately.

### 3. Midway Failures & `failed_records`: The Handoff Model
**Decision: Abandon the concept of tracking individual `failed_records` inline. Return success/failure based strictly on the "handoff" boundary.**

When using an async search engine and Oban queues, returning an array of "which specific records failed midway" at the call-site is an anti-pattern.

* **When `sync_mode: :oban`**: `sync_related/3` is only responsible for inserting the Oban job into Postgres. If the DB insert succeeds, it returns `{:ok, %Scrypath.Operations.Result{status: :accepted}}`. If the DB insert fails, the *entire batch* fails to enqueue, returning `{:error, reason}`.
* **When `sync_mode: :inline`**: The function sends a bulk HTTP request to Meilisearch. Meilisearch returns a `task_uid` (accepted). If the HTTP request fails, the *entire batch* failed. If the Meilisearch async task later fails processing a specific document, that is an engine-level concern.

We will rely on Telemetry + Oban Web for observing any records that fail to sync, and Meilisearch Task API for engine-side document rejections.

## Actionable Plan Updates

Plan 90-01, 90-02, and 90-03 will be adapted to execute this architecture. `sync_related/3` will properly surface the enqueue/HTTP batch errors, and `RelatedWorker` will properly leverage Oban retries instead of swallowing errors.
