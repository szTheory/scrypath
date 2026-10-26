# Telemetry

Scrypath emits [`:telemetry`](https://hexdocs.pm/telemetry/readme.html) events for search, hydration, sync, Oban jobs, backend requests, settings work, and operator failure reporting. This page is the catalog of every event Scrypath emits and the metadata keys each one documents.

Event names and documented metadata keys are a **public observability contract**. **Additive** metadata keys in minor releases are acceptable; **renaming or removing** an event or a documented key is **breaking**.

## Reading the table

- **Kind** is `span` or `event`. A `span` row lists the event prefix; Scrypath emits `prefix ++ [:start]`, `prefix ++ [:stop]`, and `prefix ++ [:exception]` through `:telemetry.span/3`. An `event` row is a single `:telemetry.execute/3` call under exactly that name.
- **Measurements** for spans are telemetry's standard ones: `monotonic_time` and `system_time` on `:start`, `duration` and `monotonic_time` on `:stop` and `:exception`.
- **Start metadata** is what the `:start` event carries. For an `event` row it is the event's whole metadata.
- **Stop-only metadata** lists the keys `:stop` adds. Stop metadata is the start metadata plus these keys, so a key from the start column can appear again on `:stop` with its final value.
- Every span's `:exception` event carries the start metadata plus `kind`, `reason`, and `stacktrace`. That rule applies to every span row and is not repeated in the table.
- A key marked `(optional)` may be absent. An em dash (—) means none.

## Events

| Event | Kind | Measurements | Start metadata | Stop-only metadata | When |
|---|---|---|---|---|---|
| `[:scrypath, :search]` | span | standard span measurements | `schema`, `backend`, `index`, `sync_mode` (optional), `repo` (optional), `search_scope` (optional), `scoped_facet` (optional), `ranking_score_details` (optional) | `hit_count` (optional), `record_count` (optional), `missing_count` (optional), `error_kind` (optional) | around one single-index search, including facet-scoped searches |
| `[:scrypath, :search_many]` | span | standard span measurements | `schema_count`, `raw_entry_count` | `error_kind` (optional) | around one multi-search call, from entry validation to the merged result |
| `[:scrypath, :search_many, :partial]` | event | `count` | `failure_count` | — | after a multi-search where some indexes failed but the call returned a partial result |
| `[:scrypath, :search_facet_values]` | span | standard span measurements | `schema`, `backend`, `index`, `sync_mode` (optional), `repo` (optional) | `hit_count` (optional), `error_kind` (optional) | around one facet-value search |
| `[:scrypath, :hydration]` | span | standard span measurements | `schema`, `repo`, `hit_count` | `record_count`, `missing_count` | around the repo batch load that turns search hits into records |
| `[:scrypath, :sync, :upsert]` | span | standard span measurements | `schema`, `backend`, `index`, `sync_mode`, `repo` (optional), `document_count` | `status` (optional), `mode` (optional), `error_kind` (optional) | around one sync of records; in `:oban` mode this is the enqueue, with `status` `:accepted` |
| `[:scrypath, :sync, :delete]` | span | standard span measurements | `schema`, `backend`, `index`, `sync_mode`, `repo` (optional), `document_count` | `status` (optional), `mode` (optional), `error_kind` (optional) | around one delete by document id; in `:oban` mode this is the enqueue, with `status` `:accepted` |
| `[:scrypath, :sync, :related, :resolve]` | span | standard span measurements | `schema`, `backend`, `index`, `sync_mode`, `repo` (optional), `fan_out`, `document_count` | `status` (optional), `mode` (optional), `missing_count` (optional), `error_kind` (optional) | around resolving related records from trigger records and syncing them, inline or in the related Oban job |
| `[:scrypath, :meilisearch, :request]` | span | standard span measurements | `method`, `path`, `index` (optional), `source_index` (optional), `target_index` (optional), `task_uid` (optional), `filters` (optional), `operation` (optional) | `status_code` (optional), `error_kind` (optional) | around one HTTP request to Meilisearch |
| `[:scrypath, :meilisearch, :task_wait]` | span | standard span measurements | `task_uid`, `initial_status`, `poll_interval_ms`, `timeout_ms` | `poll_count`, `final_status` (optional), `error_kind` (optional) | while Scrypath polls a Meilisearch task until it finishes or times out |
| `[:scrypath, :settings, :hot_apply]` | span | standard span measurements | `schema`, `index`, `families` | `error_kind` (optional) | around a hot settings update on a live index |
| `[:scrypath, :reindex, :settings_verified]` | span | standard span measurements | `schema`, `target_index` | `result` | around the settings read-back after a reindex applies settings |
| `[:scrypath, :reindex, :verify_skipped]` | event | — | `schema`, `target_index`, `reason` | — | when a reindex skips the settings read-back because the caller opted out |
| `[:scrypath, :operator, :failed_work, :observed]` | event | `count` | `reason_class`, `schema`, `mode`, `operation` (optional), `retryable?` (optional) | — | once per failed-work row each time `Scrypath.failed_sync_work/2` builds the rows from backend tasks or Oban jobs |
| `[:scrypath, :oban, :upsert]` | span | standard span measurements | `schema`, `backend`, `index`, `sync_mode`, `repo` (optional), `attempt`, `max_attempts`, `document_count` | `outcome`, `error_kind` (optional), `cancel_reason` (optional), `source` (optional), `upserted_count` (optional), `missing_count` (optional) | around one Oban upsert job after its args decode |
| `[:scrypath, :oban, :delete]` | span | standard span measurements | `schema`, `backend`, `index`, `sync_mode`, `repo` (optional), `attempt`, `max_attempts`, `document_count` | `outcome`, `error_kind` (optional) | around one Oban delete job after its args decode |
| `[:scrypath, :oban, :upsert, :missing_removed]` | event | `count` | `schema`, `backend`, `index`, `sync_mode`, `repo` (optional), `attempt`, `max_attempts`, `document_count` | — | after an upsert job confirmed removal of ids whose records no longer exist |

## Oban jobs

The `[:scrypath, :oban, :upsert]` and `[:scrypath, :oban, :delete]` spans wrap the work of one Oban job, so `sync_mode` is `:oban` on them. They are a different moment from the `[:scrypath, :sync, :upsert]` and `[:scrypath, :sync, :delete]` spans: in `:oban` mode those fire when the job is enqueued and report `status` `:accepted`. The worker spans fire when the job runs and the backend write happens.

`document_count` on the worker spans is the number of ids in the job args: the ids requested for an upsert job, the ids to delete for a delete job. `attempt` and `max_attempts` come from the Oban job.

Queue lifecycle stays on Oban's own events. To see the queue, job id, and job state, join with `[:oban, :job, :start]`, `[:oban, :job, :stop]`, and `[:oban, :job, :exception]`, which run in the same process as the Scrypath span:

- A job whose args fail to decode, or whose config cannot be resolved, emits **no** Scrypath event. To count these jobs, use Oban's `[:oban, :job, :stop]` with `state` `:cancelled` and `worker` `"Scrypath.Oban.UpsertWorker"` or `"Scrypath.Oban.DeleteWorker"`. Such a job may also appear among the rows `Scrypath.failed_sync_work/2` returns, but `[:scrypath, :operator, :failed_work, :observed]` fires once per row on each call to that function (a page load, a mix task), not when the job is cancelled. Do not use it as a counter.
- When the worker returns `{:error, _}` or raises, Oban reports an `[:oban, :job, :exception]` event. Its `state` is `:failure` while attempts remain and `:discard` on the last attempt, when Oban stops retrying. Scrypath reports a returned `{:error, _}` as `:stop` with `outcome` `:error`. The Scrypath `:exception` event means the job raised; it carries no `outcome`.
- A job that hits its Oban timeout or is killed mid-run emits no Scrypath `:stop` or `:exception`. Oban still reports it as `[:oban, :job, :exception]` with the same `state` rule. A job whose node dies outright emits nothing until Oban rescues it.
- To alert on a job that has used its last attempt, combine three matches. On the worker span's `:stop`, match `attempt == max_attempts` and `outcome != :ok`. On the worker span's `:exception`, match `attempt == max_attempts`. To also catch timeouts and killed jobs, match Oban's `[:oban, :job, :exception]` with `state` `:discard` and `worker` `"Scrypath.Oban.UpsertWorker"` or `"Scrypath.Oban.DeleteWorker"`. The Oban match alone covers all three cases but carries none of the Scrypath tags.

## Outcome, error_kind and cancel_reason

`outcome` maps the worker's return value:

- `:ok` — the job finished.
- `:error` — the job returned `{:error, _}` and Oban retries it.
- `:cancel` — the job returned `{:cancel, _}` and Oban does not retry it. Only upsert jobs report it: a delete job cancels only when its args fail to decode or its config cannot be resolved, both before the span starts, so the delete span's `outcome` is `:ok` or `:error`.

`error_kind` is present only when `outcome` is `:error`. It is an atom: `:http`, `:transport`, `:timeout`, `:task_failed`, `:cancelled`, `:invalid_task_payload`, an atom reason passed through as is, or `:other`.

`cancel_reason` is present only when `outcome` is `:cancel`, so only on the upsert span. It is one of `:repo_required`, `:search_records_required`, `:invalid_search_records`, or `:invalid_arg`. It is always a bare atom; the detail that came with the cancel (a key name, a returned value) is never part of the metadata.

`source` is present on upsert job stops: `:loaded` when the job loaded current records, `:legacy_snapshot` when it replayed a document snapshot from a job enqueued by an older Scrypath release. Watch `:legacy_snapshot` fall to zero before you drop support for those jobs.

`upserted_count` is the number of documents the job planned to upsert, and `missing_count` is the number of ids with no current record, which the job removes from the index. On the legacy snapshot path `missing_count` is `0`.

Counts describe what the job planned; `outcome` is authoritative. A job halts at the first failed chunk, and after that failure the counts still describe the plan, not what reached the index.

## Missing-record removals

An upsert job loads the current record for each id. An id with no record (deleted, or excluded by the schema's search scope) is removed from the index instead of upserted. After those removals succeed, the job emits `[:scrypath, :oban, :upsert, :missing_removed]` with `count` set to the number of those ids.

- `count` is the number of ids whose source record is missing and which the job confirmed absent from the index. Meilisearch treats deleting an id that is not in the index as a successful no-op, so this is **not** a count of documents that were present.
- The event fires once per job, only when `count` is greater than zero and only after every delete chunk for those ids succeeded. A failed chunk returns `{:error, _}` with no event; the retry reloads records and recomputes the missing ids, so retries never count the same removal twice.
- The event never fires on the legacy snapshot path, which loads no records.

The event and the stop `missing_count` answer different questions. The event counts ids **removed**; `missing_count` counts ids the load **found** missing, which is useful on traces. Count the event, not the metadata, or dashboards sum the same ids twice.

## Cardinality

Not every metadata value is bounded. On the Oban worker spans and the `missing_removed` event, values are atoms, integers, modules, or the index name, and none of them is a list, a tuple, or an id. Other events carry keys that grow without limit.

Tag metrics on `backend`, `index`, `sync_mode`, `outcome`, `error_kind`, `cancel_reason`, and `source`. The `index` name already separates schemas. `schema` is a module atom; as `Scrypath.Operator.FailedWork` notes, treat it as unsafe for strict low-cardinality label rules unless you aggregate, and keep it for logs, traces, and handlers that filter on it.

Never tag on these keys:

- `path` on `[:scrypath, :meilisearch, :request]`: it embeds index names and task uids, for example `/tasks/12345`.
- `task_uid` on `[:scrypath, :meilisearch, :request]` and `[:scrypath, :meilisearch, :task_wait]`: a new integer for every Meilisearch task.
- `filters` on `[:scrypath, :meilisearch, :request]`: a keyword list of task filters.
- `families` on `[:scrypath, :settings, :hot_apply]`: a list of settings keys.
- `source_index` and `target_index`: a reindex creates a new index name each run.
- `reason` and `stacktrace` on any `:exception` event (see below).

Also never tag on document ids, document bodies, error bodies, raw query text, or Oban job ids. The worker spans leave job ids out on purpose; join with Oban's events when a trace needs them.

The `reason` and `stacktrace` on `:exception` events are diagnostic only. Log them or attach them to traces, but never use `reason` as a metric tag: it can hold an exception message or other unbounded data.

## Dashboards

- Alert on the rate of `outcome` `:cancel` on the upsert span, plus Oban's cancelled worker jobs for decode failures: a cancelled job will not be retried, so its index change is lost until the next sync or backfill.
- Alert on final-attempt failures: `attempt == max_attempts` with `outcome != :ok` on `:stop`, plus `attempt == max_attempts` on `:exception`. Back that with Oban's `[:oban, :job, :exception]` at `state` `:discard` for jobs that time out or are killed (see [Oban jobs](#oban-jobs)).
- Chart `[:scrypath, :oban, :upsert, :missing_removed]` `count` per index. A rise usually tracks deletes or soft deletes in the app; do not page on it.
- For search health, backend requests, and alert-fatigue guidance, see [Search backend operations](../docs/search-backend-sre.md).
