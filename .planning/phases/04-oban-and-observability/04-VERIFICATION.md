---
phase: 04-oban-and-observability
verified: 2026-04-16T02:21:23Z
status: passed
score: 11/11 must-haves verified
overrides_applied: 0
---

# Phase 4: Oban and Observability Verification Report

**Phase Goal:** Add the production async path and instrumentation needed for serious application use.
**Verified:** 2026-04-16T02:21:23Z
**Status:** passed
**Re-verification:** No - initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A developer can enqueue durable indexing work through Oban. | ✓ VERIFIED | `Scrypath.Sync` routes `sync_mode: :oban` through `Scrypath.Oban.Enqueue`, decorates accepted results, and tests assert real job metadata is returned on shared verbs. [sync.ex](/Users/jon/projects/scrypath/lib/scrypath/sync.ex#L56), [enqueue.ex](/Users/jon/projects/scrypath/lib/scrypath/oban/enqueue.ex#L12), [sync_test.exs](/Users/jon/projects/scrypath/test/scrypath/sync_test.exs#L311) |
| 2 | Async sync is documented with clear consistency expectations and failure semantics. | ✓ VERIFIED | README and architecture docs define the sync mode matrix, the shared async lifecycle, and explicit statements about retries, discarded jobs, stale deletes, drift, and `:oban` meaning enqueue acceptance only. [README.md](/Users/jon/projects/scrypath/README.md#L137), [README.md](/Users/jon/projects/scrypath/README.md#L147), [ARCHITECTURE.md](/Users/jon/projects/scrypath/ARCHITECTURE.md#L75), [ARCHITECTURE.md](/Users/jon/projects/scrypath/ARCHITECTURE.md#L97) |
| 3 | Telemetry spans and metadata cover key search and indexing workflows. | ✓ VERIFIED | Shared span helper wraps sync, search, and hydration; Meilisearch request and task-wait spans stay on backend prefixes; telemetry tests assert metadata shape and event names. [telemetry.ex](/Users/jon/projects/scrypath/lib/scrypath/telemetry.ex#L9), [sync.ex](/Users/jon/projects/scrypath/lib/scrypath/sync.ex#L19), [search.ex](/Users/jon/projects/scrypath/lib/scrypath/search.ex#L17), [hydration.ex](/Users/jon/projects/scrypath/lib/scrypath/hydration.ex#L23), [client.ex](/Users/jon/projects/scrypath/lib/scrypath/meilisearch/client.ex#L49), [tasks.ex](/Users/jon/projects/scrypath/lib/scrypath/meilisearch/tasks.ex#L17), [telemetry_test.exs](/Users/jon/projects/scrypath/test/scrypath/telemetry_test.exs#L63) |
| 4 | Optional dependencies remain optional and the core path stays lightweight. | ✓ VERIFIED | `mix.exs` declares Oban as optional, `Scrypath.Oban` modules avoid hard compile dependency, and tests compile the integration files without Oban on the code path. [mix.exs](/Users/jon/projects/scrypath/mix.exs#L23), [oban.ex](/Users/jon/projects/scrypath/lib/scrypath/oban.ex#L5), [oban_test.exs](/Users/jon/projects/scrypath/test/scrypath/oban_test.exs#L111) |
| 5 | The public write surface remains the existing `Scrypath.*` verbs rather than a second sync API. | ✓ VERIFIED | The Oban path is selected through `sync_mode: :oban` inside the existing shared sync functions, while `Scrypath.Oban` exposes only `Ecto.Multi` helpers. [sync.ex](/Users/jon/projects/scrypath/lib/scrypath/sync.ex#L56), [oban.ex](/Users/jon/projects/scrypath/lib/scrypath/oban.ex#L12), [oban_test.exs](/Users/jon/projects/scrypath/test/scrypath/oban_test.exs#L50) |
| 6 | Selecting `sync_mode: :oban` validates explicit readiness and fails clearly when required config or modules are missing. | ✓ VERIFIED | Runtime options require `oban_queue`; config readiness checks dependency/module/attempt settings; tests cover missing queue and unavailable configured instance. [options.ex](/Users/jon/projects/scrypath/lib/scrypath/options.ex#L53), [options.ex](/Users/jon/projects/scrypath/lib/scrypath/options.ex#L136), [config.ex](/Users/jon/projects/scrypath/lib/scrypath/config.ex#L13), [config.ex](/Users/jon/projects/scrypath/lib/scrypath/config.ex#L68), [sync_test.exs](/Users/jon/projects/scrypath/test/scrypath/sync_test.exs#L368), [sync_test.exs](/Users/jon/projects/scrypath/test/scrypath/sync_test.exs#L383) |
| 7 | Oban-bound upsert and delete work is expressed as JSON-safe batch payloads built before enqueue. | ✓ VERIFIED | `Scrypath.Oban.Payload` serializes schema/backend/index ids and projected docs into string-keyed JSON-safe payloads and rejects structs/unsupported nested values; tests lock the format. [payload.ex](/Users/jon/projects/scrypath/lib/scrypath/oban/payload.ex#L6), [payload.ex](/Users/jon/projects/scrypath/lib/scrypath/oban/payload.ex#L36), [payload_test.exs](/Users/jon/projects/scrypath/test/scrypath/oban/payload_test.exs#L53), [payload_test.exs](/Users/jon/projects/scrypath/test/scrypath/oban/payload_test.exs#L124) |
| 8 | The Oban path preserves the accepted-not-completed result contract. | ✓ VERIFIED | `decorate_result/2` returns `status: :accepted` for `:oban`, and sync tests assert accepted results with queue-visible job metadata. [sync.ex](/Users/jon/projects/scrypath/lib/scrypath/sync.ex#L94), [sync_test.exs](/Users/jon/projects/scrypath/test/scrypath/sync_test.exs#L317) |
| 9 | Upsert and delete jobs execute through separate workers using prebuilt payloads rather than reloading rows. | ✓ VERIFIED | Enqueue chooses dedicated worker names; workers deserialize payloads, validate args, execute backend writes, and worker tests confirm no source-row reload behavior. [enqueue.ex](/Users/jon/projects/scrypath/lib/scrypath/oban/enqueue.ex#L9), [upsert_worker.ex](/Users/jon/projects/scrypath/lib/scrypath/oban/upsert_worker.ex#L10), [delete_worker.ex](/Users/jon/projects/scrypath/lib/scrypath/oban/delete_worker.ex#L9), [worker_test.exs](/Users/jon/projects/scrypath/test/scrypath/oban/worker_test.exs#L62) |
| 10 | A narrow `Scrypath.Oban` helper exists for `Ecto.Multi` composition without becoming a second sync API family. | ✓ VERIFIED | `Scrypath.Oban` only offers `enqueue_upsert/5` and `enqueue_delete/5`, inserts job changesets into `Ecto.Multi`, and tests explicitly refute mirrored sync verbs. [oban.ex](/Users/jon/projects/scrypath/lib/scrypath/oban.ex#L12), [oban_test.exs](/Users/jon/projects/scrypath/test/scrypath/oban_test.exs#L50), [oban_test.exs](/Users/jon/projects/scrypath/test/scrypath/oban_test.exs#L59) |
| 11 | Meilisearch request and task-wait detail is exposed only on backend-specific prefixes. | ✓ VERIFIED | Common telemetry metadata stays low-cardinality without task uid/poll count, while Meilisearch spans include request path/status and task wait details; tests assert both boundaries. [telemetry.ex](/Users/jon/projects/scrypath/lib/scrypath/telemetry.ex#L17), [client.ex](/Users/jon/projects/scrypath/lib/scrypath/meilisearch/client.ex#L49), [tasks.ex](/Users/jon/projects/scrypath/lib/scrypath/meilisearch/tasks.ex#L17), [telemetry_test.exs](/Users/jon/projects/scrypath/test/scrypath/telemetry_test.exs#L63), [telemetry_test.exs](/Users/jon/projects/scrypath/test/scrypath/telemetry_test.exs#L151) |

**Score:** 11/11 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `mix.exs` | Optional Oban dependency wiring | ✓ VERIFIED | Declares `{:oban, "~> 2.21", optional: true}`. [mix.exs](/Users/jon/projects/scrypath/mix.exs#L23) |
| `lib/scrypath/options.ex` | Explicit Oban runtime options and validation | ✓ VERIFIED | Adds `:oban`, `:oban_queue`, `:oban_max_attempts` and conditional validation for `sync_mode: :oban`. [options.ex](/Users/jon/projects/scrypath/lib/scrypath/options.ex#L37) |
| `lib/scrypath/config.ex` | Centralized Oban readiness checks | ✓ VERIFIED | Guards dependency presence, configured instance, queue, and attempts. [config.ex](/Users/jon/projects/scrypath/lib/scrypath/config.ex#L13) |
| `lib/scrypath/sync.ex` | Shared sync orchestration dispatching into enqueue path | ✓ VERIFIED | Preserves shared verbs and result envelope while routing Oban mode to enqueue. [sync.ex](/Users/jon/projects/scrypath/lib/scrypath/sync.ex#L56) |
| `lib/scrypath/oban/payload.ex` | JSON-safe batch payload builders | ✓ VERIFIED | Builds normalized upsert/delete worker args. [payload.ex](/Users/jon/projects/scrypath/lib/scrypath/oban/payload.ex#L6) |
| `lib/scrypath/oban/enqueue.ex` | Durable job changesets and inserts | ✓ VERIFIED | Converts payloads into worker jobs and returns queue metadata. [enqueue.ex](/Users/jon/projects/scrypath/lib/scrypath/oban/enqueue.ex#L37) |
| `lib/scrypath/oban/upsert_worker.ex` | Upsert worker executing serialized docs | ✓ VERIFIED | Validates payload, rebuilds `Scrypath.Document` structs, retries transient backend failures, cancels invalid jobs. [upsert_worker.ex](/Users/jon/projects/scrypath/lib/scrypath/oban/upsert_worker.ex#L10) |
| `lib/scrypath/oban/delete_worker.ex` | Delete worker executing resolved ids | ✓ VERIFIED | Validates delete payload, uses resolved ids, cancels invalid jobs. [delete_worker.ex](/Users/jon/projects/scrypath/lib/scrypath/oban/delete_worker.ex#L9) |
| `lib/scrypath/oban.ex` | Narrow `Ecto.Multi` helper | ✓ VERIFIED | Only adds transactional enqueue helpers. [oban.ex](/Users/jon/projects/scrypath/lib/scrypath/oban.ex#L12) |
| `lib/scrypath/telemetry.ex` | Shared span helper and metadata shaper | ✓ VERIFIED | Defines common span wrapper and low-cardinality result metadata extraction. [telemetry.ex](/Users/jon/projects/scrypath/lib/scrypath/telemetry.ex#L9) |
| `lib/scrypath/search.ex` | Search workflow instrumentation | ✓ VERIFIED | Emits shared search span around backend search and result decoration. [search.ex](/Users/jon/projects/scrypath/lib/scrypath/search.ex#L17) |
| `lib/scrypath/hydration.ex` | Hydration workflow instrumentation | ✓ VERIFIED | Emits shared hydration span around repo-backed record loading. [hydration.ex](/Users/jon/projects/scrypath/lib/scrypath/hydration.ex#L23) |
| `lib/scrypath/meilisearch/client.ex` | Backend-specific request spans | ✓ VERIFIED | Emits request spans with method/path/status metadata. [client.ex](/Users/jon/projects/scrypath/lib/scrypath/meilisearch/client.ex#L49) |
| `lib/scrypath/meilisearch/tasks.ex` | Backend-specific task-wait spans | ✓ VERIFIED | Emits wait spans with task uid, poll count, and final status. [tasks.ex](/Users/jon/projects/scrypath/lib/scrypath/meilisearch/tasks.ex#L17) |
| `README.md` | Public async contract docs | ✓ VERIFIED | Documents mode matrix, lifecycle, and operational realities. [README.md](/Users/jon/projects/scrypath/README.md#L137) |
| `ARCHITECTURE.md` | Internal boundary and observability docs | ✓ VERIFIED | Documents common-vs-backend telemetry split and sync guarantees. [ARCHITECTURE.md](/Users/jon/projects/scrypath/ARCHITECTURE.md#L75) |
| `test/scrypath/sync_test.exs` | Shared verb and Oban contract coverage | ✓ VERIFIED | Covers accepted result semantics, missing config, and optional dep shape. [sync_test.exs](/Users/jon/projects/scrypath/test/scrypath/sync_test.exs#L311) |
| `test/scrypath/oban/payload_test.exs` | Payload contract coverage | ✓ VERIFIED | Covers JSON-safe upsert/delete payloads and rejection paths. [payload_test.exs](/Users/jon/projects/scrypath/test/scrypath/oban/payload_test.exs#L53) |
| `test/scrypath/oban/enqueue_test.exs` | Durable enqueue coverage | ✓ VERIFIED | Covers one-job insert behavior for upsert and delete. [enqueue_test.exs](/Users/jon/projects/scrypath/test/scrypath/oban/enqueue_test.exs#L40) |
| `test/scrypath/oban_test.exs` | Transactional helper and optional compile-path coverage | ✓ VERIFIED | Covers narrow helper surface and compile-without-Oban behavior. [oban_test.exs](/Users/jon/projects/scrypath/test/scrypath/oban_test.exs#L50) |
| `test/scrypath/oban/worker_test.exs` | Worker execution and retry/cancel coverage | ✓ VERIFIED | Covers backend execution, no reload path, cancel semantics, and retryable errors. [worker_test.exs](/Users/jon/projects/scrypath/test/scrypath/oban/worker_test.exs#L62) |
| `test/scrypath/telemetry_test.exs` | Telemetry contract coverage | ✓ VERIFIED | Covers common spans, backend-specific spans, and docs assertions. [telemetry_test.exs](/Users/jon/projects/scrypath/test/scrypath/telemetry_test.exs#L63) |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `lib/scrypath/options.ex` | `lib/scrypath/config.ex` | runtime options feed explicit Oban readiness checks | ✓ WIRED | Resolved runtime options include Oban config consumed by `ensure_oban_ready!/1`. [options.ex](/Users/jon/projects/scrypath/lib/scrypath/options.ex#L136), [config.ex](/Users/jon/projects/scrypath/lib/scrypath/config.ex#L13) |
| `lib/scrypath/config.ex` | `lib/scrypath/sync.ex` | shared sync path guards Oban readiness before dispatch | ✓ WIRED | Both upsert and delete branches call `Config.ensure_oban_ready!/1` before enqueue. [sync.ex](/Users/jon/projects/scrypath/lib/scrypath/sync.ex#L56), [sync.ex](/Users/jon/projects/scrypath/lib/scrypath/sync.ex#L71) |
| `lib/scrypath/sync.ex` | `lib/scrypath/oban/enqueue.ex` | `sync_mode: :oban` dispatch | ✓ WIRED | Shared sync verbs route into enqueue helpers and preserve the common result envelope. [sync.ex](/Users/jon/projects/scrypath/lib/scrypath/sync.ex#L56), [enqueue.ex](/Users/jon/projects/scrypath/lib/scrypath/oban/enqueue.ex#L12) |
| `lib/scrypath/oban/payload.ex` | Oban jobs | payload builders become worker args | ✓ WIRED | Enqueue changesets use payload builders directly before job creation. [enqueue.ex](/Users/jon/projects/scrypath/lib/scrypath/oban/enqueue.ex#L37), [enqueue.ex](/Users/jon/projects/scrypath/lib/scrypath/oban/enqueue.ex#L49) |
| `lib/scrypath/oban/enqueue.ex` | `lib/scrypath/oban/upsert_worker.ex` | worker name and serialized documents | ✓ WIRED | Upsert jobs target `Scrypath.Oban.UpsertWorker` with serialized docs. [enqueue.ex](/Users/jon/projects/scrypath/lib/scrypath/oban/enqueue.ex#L9), [worker_test.exs](/Users/jon/projects/scrypath/test/scrypath/oban/worker_test.exs#L62) |
| `lib/scrypath/oban/enqueue.ex` | `lib/scrypath/oban/delete_worker.ex` | worker name and resolved ids | ✓ WIRED | Delete jobs target `Scrypath.Oban.DeleteWorker` with id-only payloads. [enqueue.ex](/Users/jon/projects/scrypath/lib/scrypath/oban/enqueue.ex#L10), [worker_test.exs](/Users/jon/projects/scrypath/test/scrypath/oban/worker_test.exs#L90) |
| `lib/scrypath/oban.ex` | `Ecto.Multi` | transactional enqueue composition | ✓ WIRED | Public helper appends named job inserts to a multi using the configured Oban module. [oban.ex](/Users/jon/projects/scrypath/lib/scrypath/oban.ex#L12), [oban_test.exs](/Users/jon/projects/scrypath/test/scrypath/oban_test.exs#L59) |
| `lib/scrypath/telemetry.ex` | `lib/scrypath/sync.ex` | common sync spans | ✓ WIRED | Shared span helper wraps upsert and delete workflows. [telemetry.ex](/Users/jon/projects/scrypath/lib/scrypath/telemetry.ex#L9), [sync.ex](/Users/jon/projects/scrypath/lib/scrypath/sync.ex#L19) |
| `lib/scrypath/telemetry.ex` | `lib/scrypath/search.ex` and `lib/scrypath/hydration.ex` | common search/hydration spans | ✓ WIRED | Shared span helper wraps both workflows. [search.ex](/Users/jon/projects/scrypath/lib/scrypath/search.ex#L17), [hydration.ex](/Users/jon/projects/scrypath/lib/scrypath/hydration.ex#L23) |
| `lib/scrypath/meilisearch/client.ex` and `lib/scrypath/meilisearch/tasks.ex` | backend-specific telemetry surface | explicit Meilisearch prefixes | ✓ WIRED | Request and wait spans are emitted under `[:scrypath, :meilisearch, ...]`. [client.ex](/Users/jon/projects/scrypath/lib/scrypath/meilisearch/client.ex#L55), [tasks.ex](/Users/jon/projects/scrypath/lib/scrypath/meilisearch/tasks.ex#L17) |
| `README.md` and `ARCHITECTURE.md` | public/operator contract | async lifecycle and failure semantics | ✓ WIRED | Both docs describe the same mode matrix and lifecycle. [README.md](/Users/jon/projects/scrypath/README.md#L137), [ARCHITECTURE.md](/Users/jon/projects/scrypath/ARCHITECTURE.md#L83) |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `lib/scrypath/sync.ex` | `documents` | `Projection.document/2` from caller records, then `Enqueue.enqueue_upsert/3` or backend upsert | Yes | ✓ FLOWING |
| `lib/scrypath/sync.ex` | `document_ids` | caller ids or `Identity.document_id/2`, then `Enqueue.enqueue_delete/3` or backend delete | Yes | ✓ FLOWING |
| `lib/scrypath/oban/enqueue.ex` | `job.args` | `Payload.build_upsert/3` and `Payload.build_delete/3` serialized into Oban job changesets | Yes | ✓ FLOWING |
| `lib/scrypath/oban/upsert_worker.ex` | `documents` | persisted JSON args normalized back into `%Scrypath.Document{}` structs | Yes | ✓ FLOWING |
| `lib/scrypath/oban/delete_worker.ex` | `document_ids` | persisted JSON args delivered directly to backend delete callback | Yes | ✓ FLOWING |
| `lib/scrypath/search.ex` | `raw_result` and `hits` | backend `search/3` response, then `SearchResult.new/4` and optional hydration | Yes | ✓ FLOWING |
| `lib/scrypath/hydration.ex` | `records` and `missing_ids` | repo query over hit ids with order restored in Elixir | Yes | ✓ FLOWING |
| `lib/scrypath/meilisearch/tasks.ex` | normalized task state | client task polling response sequence | Yes | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Phase 4 Oban and telemetry contracts pass their targeted suite | `mix test test/scrypath/sync_test.exs test/scrypath/oban/payload_test.exs test/scrypath/oban/enqueue_test.exs test/scrypath/oban_test.exs test/scrypath/oban/worker_test.exs test/scrypath/telemetry_test.exs` | `32 tests, 0 failures` | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| `SYNC-05` | `04-01`, `04-02`, `04-03` | Developer can choose Oban-backed asynchronous synchronization for production workflows. | ✓ SATISFIED | Shared `Scrypath.*` verbs support `sync_mode: :oban`, enqueue returns accepted metadata, workers execute persisted payloads, and `Scrypath.Oban` supports transaction composition. [sync.ex](/Users/jon/projects/scrypath/lib/scrypath/sync.ex#L56), [sync_test.exs](/Users/jon/projects/scrypath/test/scrypath/sync_test.exs#L311), [enqueue.ex](/Users/jon/projects/scrypath/lib/scrypath/oban/enqueue.ex#L61), [worker_test.exs](/Users/jon/projects/scrypath/test/scrypath/oban/worker_test.exs#L62), [oban.ex](/Users/jon/projects/scrypath/lib/scrypath/oban.ex#L12) |
| `OPER-04` | `04-03` | Developer can observe indexing and query workflows through Telemetry events. | ✓ SATISFIED | Common spans cover sync/search/hydration and backend-specific spans cover request/task wait details with stable metadata. [telemetry.ex](/Users/jon/projects/scrypath/lib/scrypath/telemetry.ex#L17), [telemetry_test.exs](/Users/jon/projects/scrypath/test/scrypath/telemetry_test.exs#L63), [telemetry_test.exs](/Users/jon/projects/scrypath/test/scrypath/telemetry_test.exs#L151) |

No orphaned Phase 4 requirements were found in [.planning/REQUIREMENTS.md](/Users/jon/projects/scrypath/.planning/REQUIREMENTS.md#L20); the only Phase 4 requirement IDs are `SYNC-05` and `OPER-04`, and both are claimed by Phase 4 plans.

### Anti-Patterns Found

No blocker or warning anti-patterns found in the Phase 4 implementation files. Targeted scans only hit expected error-message literals, not placeholders, hollow returns, or console-log-only behavior.

### Residual Risk

The phase goal is achieved, but the verification surface is still unit-level around Oban integration. Current tests use doubles for inserts and worker execution rather than a live Oban-backed repo transaction. That is a coverage gap, not a goal gap.

### Gaps Summary

No gaps found. The phase goal is achieved in the codebase: Scrypath now has a real Oban-backed async path on the shared sync verbs, validated JSON-safe worker payloads, dedicated workers with explicit retry/cancel behavior, a narrow `Ecto.Multi` helper, layered telemetry for common and backend-specific workflows, and operator-facing docs that state the async lifecycle and consistency semantics plainly.

---

_Verified: 2026-04-16T02:21:23Z_
_Verifier: Claude (gsd-verifier)_
