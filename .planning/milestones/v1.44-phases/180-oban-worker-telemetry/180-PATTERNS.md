# Phase 180: Oban worker telemetry - Pattern Map

**Mapped:** 2026-10-25
**Files analyzed:** 18 (4 new, 14 modified)
**Analogs found:** 17 / 18 (only the static AST scan in the contract test has no in-repo analog; RESEARCH Pattern 5 has a working prototype to use instead)

All analog paths below were checked with `git ls-files` and are tracked source. None are gitignored mirrors.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/scrypath/telemetry.ex` (add `job_stop_metadata/1` and private `cancel_reason/1`) | utility | transform | same file: `stop_metadata/2` + `error_kind/1` (lines 31-82) | exact |
| `lib/scrypath/oban/upsert_worker.ex` (span, facts threading, `missing_removed` emit) | service (Oban worker) | event-driven / batch | `lib/scrypath/sync/related_worker.ex` `resolve/5` (lines 48-59) for the span; `lib/scrypath/operator/failed_work/telemetry.ex` for the point event | exact |
| `lib/scrypath/oban/delete_worker.ex` (span) | service (Oban worker) | event-driven / batch | `lib/scrypath/sync/related_worker.ex` lines 48-59 | exact |
| `lib/scrypath/sync/related_worker.ex` (cancel reason change) | service (Oban worker) | event-driven | same file, `job_result/1` lines 76-82 | exact |
| `guides/telemetry.md` (NEW) | config / docs | n/a | `docs/search-backend-sre.md` lines 19-36 (table) + `guides/per-query-tuning-pipeline.md` lines 85-95 (contract wording); header style from `guides/sync-modes-and-visibility.md` lines 1-15 | role-match |
| `guides/per-query-tuning-pipeline.md` (table becomes a pointer; keep the heading) | docs | n/a | same file lines 85-95 | exact |
| `docs/search-backend-sre.md` (table becomes a pointer plus aggregation advice) | docs | n/a | same file lines 19-36 | exact |
| `guides/related-data-and-reindexing.md` (line 369 4xx row) | docs | n/a | same file lines 369-372 | exact |
| `ARCHITECTURE.md` (Observability bullet, line 170) | docs | n/a | same file lines 164-170 | exact |
| `mix.exs` (extras + Operations group) | config | n/a | same file lines 188-262 | exact |
| `test/support/telemetry_capture.ex` (NEW) | test helper | event-driven | `test/scrypath/telemetry_test.exs` `capture_events/2` + `handle_event/4` (lines 350-396); module header from `test/support/loader_backfill_cases.ex` lines 1-3 | exact |
| `test/support/oban_telemetry_scenarios.ex` (NEW, optional) | test helper | batch | `test/scrypath/oban/worker_test.exs` backends and schemas (lines 7-130, 280-292) | exact |
| `test/scrypath/oban/worker_telemetry_test.exs` (NEW) | test | event-driven | `test/scrypath/telemetry_test.exs` (async: false, lines 1-127) + `test/scrypath/oban/worker_test.exs` (perform calls) | exact |
| `test/scrypath/telemetry_contract_test.exs` (NEW, untagged) | test (contract) | file-I/O / transform | `test/scrypath/docs_contract_test.exs` (compile-time `File.read!` attrs, lines 5-16, 61, 109-116); AST scan has no analog | partial |
| `test/scrypath/telemetry_test.exs` (add `job_stop_metadata/1` unit cases) | test | transform | same file | exact |
| `test/scrypath/docs_contract_test.exs` (`@guide_paths`, OBS pattern, SRE assertion) | test (contract) | file-I/O | same file lines 35-60, 93-117, 668-679 | exact |
| `test/release/package_metadata_test.exs` (Operations list) | test | file-I/O | same file lines 84-92 | exact |
| `test/scrypath/sync/related_worker_test.exs` (~line 501 cancel shape) | test | request-response | same file lines 501-504 | exact |

## Pattern Assignments

### `lib/scrypath/telemetry.ex` (utility, transform)

**Analog:** the same file. Add the new public function next to `stop_metadata/2` and reuse the private classifier.

**Wrapper whose merge semantics dictate the design** (lines 9-15). The stop map is merged onto the start map, so the job stop builder must never return `document_count`:
```elixir
@spec span(event_name(), metadata(), (-> {term(), metadata()})) :: term()
def span(event_name, metadata, fun) when is_list(event_name) and is_map(metadata) do
  :telemetry.span(event_name, metadata, fn ->
    {result, stop_metadata} = fun.()
    {result, Map.merge(metadata, stop_metadata)}
  end)
end
```

**`common_metadata/3`: `extra` is merged last, so `sync_mode: :oban` overrides the config's `:manual`** (lines 17-29):
```elixir
def common_metadata(schema_module, config, extra \\ []) do
  backend = Config.fetch_backend!(config)

  %{
    schema: schema_module,
    backend: backend.name(),
    index: backend.index_name(schema_module, config)
  }
  |> maybe_put(:sync_mode, Keyword.get(config, :sync_mode))
  |> maybe_put(:repo, Keyword.get(config, :repo))
  |> Map.merge(Map.new(extra))
end
```

**Why not to reuse `stop_metadata/2`** (lines 51-57). A bare `:ok` falls through to `result_kind`, which adds an undocumented key:
```elixir
def stop_metadata({:error, reason}, extra) do
  Map.merge(%{error_kind: error_kind(reason)}, Map.new(extra))
end

def stop_metadata(result, extra) do
  Map.merge(%{result_kind: result_kind(result)}, Map.new(extra))
end
```

**Private classifier to reuse, kept private** (lines 75-82). The real value set includes `:cancelled` and `:invalid_task_payload`, so the guide should list all of them or say "an atom":
```elixir
defp error_kind({:http_error, status, _body}) when is_integer(status), do: :http
defp error_kind({:transport_error, _}), do: :transport
defp error_kind({:timeout, _}), do: :timeout
defp error_kind({:task_failed, _}), do: :task_failed
defp error_kind({:cancelled, _}), do: :cancelled
defp error_kind({:invalid_task_payload, _}), do: :invalid_task_payload
defp error_kind(reason) when is_atom(reason), do: reason
defp error_kind(_), do: :other
```

**Conventions to copy:** `@spec` on every public function and `@type metadata :: map()` (lines 6-7). `@moduledoc false` stays (D-14). The new function is `@doc false` + `@spec job_stop_metadata(term()) :: metadata()`. Follow the multi-clause style of `error_kind/1` for `cancel_reason/1`. RESEARCH Pattern 2 has the full sketch. The module must not reference any `Oban.*` module, or `mix verify.no_optional_deps` breaks.

---

### `lib/scrypath/oban/upsert_worker.ex` (Oban worker, event-driven / batch)

**Analog for the span:** `lib/scrypath/sync/related_worker.ex` lines 48-59. This is the only existing worker-side span: `common_metadata` with extras, a literal event-name list, and a stop map built from the result.
```elixir
defp resolve(job, records, missing, opts, config) do
  metadata =
    Telemetry.common_metadata(job.schema, config,
      fan_out: job.fan_out,
      document_count: length(job.document_ids)
    )

  Telemetry.span([:scrypath, :sync, :related, :resolve], metadata, fn ->
    result = sync_resolved(job.fan_out_config, records, opts)
    {result, Telemetry.stop_metadata(result, missing_count: length(missing))}
  end)
end
```
Differences to apply: use `Chunks.distinct_count/1`, not `length/1` (Pitfall 4). Add `sync_mode: :oban`, `attempt` and `max_attempts`. Use `Telemetry.job_stop_metadata/1`, not `stop_metadata/2`.

**Aliases to add:** `alias Scrypath.Telemetry`, the same as `related_worker.ex` line 9. The existing aliases block (lines 7-12) is alphabetical, so insert it after `Projection`.

**Insertion point: the D-02 boundary** (current lines 14-24). Bind the struct as `%Oban.Job{args: args} = oban_job`. The span goes inside the `with` success body, after `Keyword.put(config, :index_name, ...)`. The `else` branch stays unchanged and outside the span:
```elixir
@impl Oban.Worker
def perform(%Oban.Job{args: args}) do
  with {:ok, job} <- JobArgs.decode_upsert(args),
       {:ok, config} <-
         JobArgs.resolve_config([backend: job.backend, sync_mode: :manual] ++ job.opts) do
    config = Keyword.put(config, :index_name, job.index)
    sync(job, args, config)
  else
    {:error, tag} -> {:cancel, {:invalid_job, tag}}
  end
end
```

**Facts threading: the `sync/3` branches** (lines 33-63). Each branch has to return `{result, facts}`, where facts is `%{source:, upserted_count:, missing_count:}` on the loaded and legacy-success branches and `%{}` on cancel and error branches:
- line 34 `{:ok, records, missing_ids}`: `source: :loaded`, `upserted_count: length(documents)` (or `distinct_count` of document ids), `missing_count: Chunks.distinct_count(missing_ids)`
- line 45 `{:ok, documents}` (legacy): `source: :legacy_snapshot`, `upserted_count: length(documents)`, `missing_count: 0`
- lines 48-62: the cancel and error branches return no facts

**`missing_removed` emit site** (lines 37-39). Today's code:
```elixir
with :ok <- write(backend, :upsert_documents, schema_module, documents, config) do
  write(backend, :delete_documents, schema_module, missing_ids, config)
end
```
becomes a two-clause `with` that calls `emit_missing_removed(missing_ids, metadata)` only after the delete `write` returns `:ok`. `write/5` already returns `:ok` for `[]` (line 68), and `Chunks.each_ok/2` halts at the first error (lines 70-76). Pass the **start** metadata into `sync` (D-09).

**Point-event analog:** `lib/scrypath/operator/failed_work/telemetry.ex` lines 5-17. It uses a literal name, a `%{count: n}` measurement and a flat map of atoms:
```elixir
:telemetry.execute(
  [:scrypath, :operator, :failed_work, :observed],
  %{count: 1},
  %{ ... }
)
```
Keep the event name a literal list at the call site (D-17(b) guard). Do not write `metadata.prefix ++ [...]`.

**Guard:** all code stays inside `if Code.ensure_loaded?(Oban.Worker) and Code.ensure_loaded?(Oban.Job) do` (line 1). Keep the comment style: a short "why" comment above non-obvious branches (lines 31-32, 42-43, 52-53).

---

### `lib/scrypath/oban/delete_worker.ex` (Oban worker, event-driven / batch)

**Analog:** the same span shape as above (`related_worker.ex` lines 48-59). The insertion point is lines 12-21:
```elixir
def perform(%Oban.Job{args: args}) do
  with {:ok, job} <- JobArgs.decode_delete(args),
       {:ok, config} <-
         JobArgs.resolve_config([backend: job.backend, sync_mode: :manual] ++ job.opts) do
    config = Keyword.put(config, :index_name, job.index)
    write(job.backend, job.schema, job.document_ids, config)
  else
    {:error, tag} -> {:cancel, {:invalid_job, tag}}
  end
end
```
Wrap the `write(...)` call: `Telemetry.span([:scrypath, :oban, :delete], metadata, fn -> result = write(...); {result, Telemetry.job_stop_metadata(result)} end)`. Delete has no in-boundary cancel and no upsert-only keys. Add `alias Scrypath.Telemetry` to lines 7-9.

**Note:** both workers share the start-metadata builder (`common_metadata(job.schema, config, sync_mode: :oban, attempt:, max_attempts:, document_count: Chunks.distinct_count(job.document_ids))`). Each worker can carry a private `start_metadata/3`, or it can be a shared `@doc false` helper. That helper must not live in `Scrypath.Telemetry` if it pattern-matches `%Oban.Job{}`.

---

### `lib/scrypath/sync/related_worker.ex` (Oban worker, D-18)

**Analog:** the same file, lines 76-82:
```elixir
defp job_result(:ok), do: :ok
defp job_result({:ok, _result}), do: :ok

defp job_result({:error, {:http_error, status, body}}) when status in 400..499,
  do: {:cancel, "HTTP #{status}: #{inspect(body)}"}

defp job_result({:error, reason}), do: {:error, reason}
```
Change line 79 to `{:error, {:http_error, status, _body}}` and line 80 to `do: {:cancel, {:http_error, status}}`. The tuple shape matches the existing `{:cancel, {:invalid_job, tag}}` tags (lines 18, 32, 37, 41).

---

### `test/support/telemetry_capture.ex` (NEW test helper)

**Analog:** `test/scrypath/telemetry_test.exs` lines 350-396:
```elixir
defp capture_events(prefixes, fun) do
  parent = self()
  ref = make_ref()
  handler_id = "scrypath-telemetry-test-#{System.unique_integer([:positive])}"

  event_names =
    for prefix <- prefixes,
        suffix <- [:start, :stop, :exception] do
      prefix ++ [suffix]
    end

  :ok =
    :telemetry.attach_many(handler_id, event_names, &__MODULE__.handle_event/4, {parent, ref})

  fun.()

  :telemetry.detach(handler_id)

  receive_events(ref, [])
end

defp receive_events(ref, events) do
  receive do
    {^ref, event} -> receive_events(ref, [event | events])
  after
    50 -> Enum.reverse(events)
  end
end

defp find_event(events, name) do
  Enum.find(events, fn event -> event.name == name end) ||
    flunk("expected event #{inspect(name)}, got #{inspect(Enum.map(events, & &1.name))}")
end

def handle_event(event_name, measurements, metadata, {parent, ref}) do
  send(parent, {ref, %{name: event_name, measurements: measurements, metadata: metadata}})
end
```
Changes required (Pitfall 5): take **full** event names, not prefixes, so the helper can attach `:missing_removed`. Detach in `ExUnit.Callbacks.on_exit/1` instead of after `fun.()`, so a raising scenario (the exception case) doesn't leak the handler. Keep the handler a public module function (`&__MODULE__.handle_event/4`) to avoid telemetry's local-function warning. Keep the `%{name:, measurements:, metadata:}` event shape and the `find_event/2` flunk message.

**Module header convention** (`test/support/loader_backfill_cases.ex` lines 1-3): `defmodule Scrypath.TestSupport.<Name> do` / `@moduledoc false`, plus a short comment block that explains usage. `test/test_helper.exs` loads `test/support/**/*.ex` with `Code.require_file/1`, so no registration is needed.

---

### `test/support/oban_telemetry_scenarios.ex` (NEW, optional) and `test/scrypath/oban/worker_telemetry_test.exs` (NEW)

**Analog:** `test/scrypath/oban/worker_test.exs`.

**Recording backend** (lines 7-47). It sends a message per call and returns `{:ok, %{document_ids: ...}}`. Copy it, and add variants:
- a raising backend (`upsert_documents/3` and `delete_documents/3` call `raise`) for the exception scenario
- a backend that fails the second `delete_documents` call (`{:error, {:timeout, _}}` or `:timeout`) for the "failed chunk, no event" case. It needs a counter (process dictionary or Agent) because the backend has no state.

**Transient-error backend** (lines 49-71): `upsert_documents/3` and `delete_documents/3` return `{:error, :timeout}`. Use it for the `outcome: :error, error_kind: :timeout` scenario.

**Loader schemas** (lines 73-110): `LoaderPost` drops id 404 (missing ids), `GoneLoaderPost` returns `[]` (all ids missing, useful for the 1,500-id case), `BrokenLoaderPost` returns a non-list (in-boundary `:invalid_search_records` cancel).

**Args builders** (lines 117-130 `upsert_args/4`, lines 280-292 `delete_args/1`):
```elixir
defp upsert_args(schema, backend, ids, extra \\ %{}) do
  Map.merge(
    %{
      "schema" => to_string(schema),
      "backend" => to_string(backend),
      "index" => "tenant_queryable_post",
      "sync_mode" => "oban",
      "document_count" => length(ids),
      "document_ids" => ids,
      "repo" => to_string(FakeRepo)
    },
    extra
  )
end
```
**Legacy snapshot fixture** (lines 136-140): `%{"documents" => [%{"id" => 1, "data" => %{"title" => "Old title"}, "source" => "fields"}]}`. Drop `"repo"` from the args to reach the `:repo_required` legacy branch (compare the line 177-182 test, which cancels when no snapshot is present).

**Decode-failure fixture** (lines 264-277 "workers cancel impossible payload problems"): `"schema" => "MissingSchema"`. Assert that no `[:scrypath, :oban, *]` event fires.

**Perform call shape:** `Scrypath.Oban.UpsertWorker.perform(%Oban.Job{args: args})`, the pattern used throughout this file. New tests **must** add `attempt: n, max_attempts: 8` (Pitfall 3: the default `attempt` is 0).

**Test module shape:** copy the `test/scrypath/telemetry_test.exs` header (lines 1-2, 61-65): `use ExUnit.Case, async: false`, `setup do FakeRepo.reset() ... end`. Do **not** add telemetry assertions to `worker_test.exs`, which is `async: true` (line 2).

**Assertion style to copy** (telemetry_test.exs lines 93-104): `find_event` then direct `assert stop.metadata.key == value` and `refute Map.has_key?(stop.metadata, :key)`. The dedupe rule test (lines 107-127) is the model for asserting that `document_count` matches between start and stop.

---

### `test/scrypath/telemetry_contract_test.exs` (NEW, untagged contract test)

**Analog (partial):** `test/scrypath/docs_contract_test.exs`.

**Compile-time file reads** (lines 5, 16, 61):
```elixir
@search_backend_sre_docs File.read!("docs/search-backend-sre.md")
@guides Enum.into(@guide_paths, %{}, fn path -> {path, File.read!(path)} end)
```
Use `@telemetry_guide File.read!("guides/telemetry.md")`. For `lib/**/*.ex`, read at runtime inside the test (`Path.wildcard("lib/**/*.ex")`), or use `@external_resource` per file so a recompile picks up changes. Runtime reading is simpler and avoids stale compile caches.

**Failure-message style** (lines 109-116): `refute ... , "remove #{label} from published doc #{path} ..."`. Drift failures should likewise print both difference sets in the message.

**Do NOT copy:** `@moduletag :docs_contract` (line 3). CI runs `--exclude docs_contract` (Pitfall 1), so this file stays untagged and `async: false` (it attaches handlers).

**AST scan and guard:** no in-repo analog. `test/mix/tasks/verify.phase97_test.exs` and its siblings use `Path.wildcard("lib...")` for file listing only. Use RESEARCH Pattern 5 (prototyped: 14 names; one allowlisted non-literal site, `lib/scrypath/telemetry.ex` `span/3`). Write the parser and scanner as pure functions over strings so a negative-proof unit case can feed a guide with a row missing.

**Key-contract runtime capture:** reuse `Scrypath.TestSupport.TelemetryCapture` and the scenario fixtures above. The implicit key set is `telemetry_span_context` on every span event, plus `kind`, `reason` and `stacktrace` on `:exception` (Pitfall 2).

---

### `test/scrypath/docs_contract_test.exs` (modify)

- `@guide_paths` (lines 35-60): add `"guides/telemetry.md"`. It flows into `@published_markdown_for_hygiene` (lines 78-85) automatically.
- Hygiene patterns (lines 94-107): add `{~r/\bOBS-\d{2}\b/, "OBS-NN requirement-style IDs"}`, in the same tuple shape as `{~r/\bFACET-\d{2}\b/, "FACET-NN requirement-style IDs"}`.
- Line 90 `assert String.contains?(@per_query_tuning_pipeline, "## Telemetry catalog")`: keep the heading in the guide.
- Lines 668-679, the SRE test: it asserts `"[:scrypath, :search]"`, `"[:scrypath, :meilisearch, :request]"` and `"[:scrypath, :operator, :failed_work, :observed]"`. Either keep those names in the SRE aggregation prose or add a `@telemetry_guide` attribute, retarget the three names at it, and add `"guides/telemetry.md"` to the SRE assertion list. Rename the test title ("keeps telemetry table") if the table moves.

---

### `test/release/package_metadata_test.exs` (modify)

**Analog:** the same file, lines 76-92. Add `assert "guides/telemetry.md" in docs[:extras]` next to the line 82 `per-query-tuning-pipeline` assertion, and add `"guides/telemetry.md"` to the exact Operations list in the **same position** as in `mix.exs`.

---

### `test/scrypath/sync/related_worker_test.exs` (modify)

**Analog:** the same file, lines 501-504:
```elixir
test "perform/1 cancels job on 4xx http error" do
  assert {:cancel, "HTTP 400: \"Bad Request\""} =
           RelatedWorker.perform(error_job("400 Error"))
end
```
becomes `assert {:cancel, {:http_error, 400}} = ...`. The 5xx test at lines 506-509 is unchanged.

---

### `test/scrypath/telemetry_test.exs` (modify, unit cases for `job_stop_metadata/1`)

Pure-function cases: `:ok` → `%{outcome: :ok}`; `{:error, :timeout}` → `error_kind: :timeout`; `{:cancel, {:invalid_job, {:invalid_arg, "document_ids"}}}` → `cancel_reason: :invalid_arg`; `{:cancel, {:invalid_job, :invalid_search_records}}` → `:invalid_search_records`. Assert `refute Map.has_key?(m, :document_count)` and `refute Map.has_key?(m, :result_kind)`. No Oban needed.

---

### `mix.exs` (config)

**Analog:** the same file. `extras:` (lines 188-220): add `"guides/telemetry.md"` near `"guides/per-query-tuning-pipeline.md"` (line 216). `groups_for_extras` `Operations:` (lines 247-255): add it to the list. Keep the package metadata test in sync. `files:` (line 272) already ships `guides`, so no change is needed there.

---

### `guides/telemetry.md` (NEW docs)

**Header and intro style** (`guides/sync-modes-and-visibility.md` lines 1-15): an H1 title, a one-sentence framing paragraph that names Scrypath, `## The Contract` with a pipe table and `|------|` separators.

**Contract wording to move here** (`guides/per-query-tuning-pipeline.md` line 87):
> Telemetry is a **public observability contract** for event names and documented metadata keys. **Additive** metadata in minor releases is acceptable; **renaming or removing** events or documented keys is **breaking**.

**Row content to carry over** (`docs/search-backend-sre.md` lines 25-34) for the existing events' "When" prose, plus `per-query-tuning-pipeline.md` lines 91-93 for `search`, `search_many` and `search_many.partial`. The cardinality line comes from SRE line 21 ("use `schema`, `backend`, `index`, `sync_mode`; avoid high-cardinality tags such as raw query text or primary keys").

**Table format (D-16, six fixed columns):** Event | Kind | Measurements | Start metadata | Stop-only metadata | When. The event cell is a backticked list literal, so the parser can match rows with ``^\| `\[:scrypath`` and run `Code.string_to_quoted!/1`. Mark optional keys with `` `key` (optional) ``, **not** a trailing `?`, because `retryable?` is a real key (`lib/scrypath/operator/failed_work/telemetry.ex` line 14). Put the exception keys in a fixed prose rule, not a column.

**Hygiene:** no `OBS-NN` and no `(D-xx)` strings (docs_contract_test.exs lines 94-107).

---

### `docs/search-backend-sre.md` and `guides/per-query-tuning-pipeline.md` (docs, table to pointer)

- SRE lines 19-36: keep the `## Scrypath telemetry (application signals)` heading, the cardinality paragraph (line 21) and the "**Dashboard-first:**" line (36). Replace the table (lines 23-34) with a link `[Telemetry](../guides/telemetry.md)` (the `docs/` → `guides/` link style matches `../guides/sync-modes-and-visibility.md`). Keep the alert-fatigue advice for `failed_work.observed`, and add the dashboard guidance for `missing_removed` and the Oban `outcome` / final-attempt alerts.
- Per-query lines 85-95: keep `## Telemetry catalog`, replace the table with a link `[Telemetry](telemetry.md)`, and keep the one-line contract statement or move it to the guide.

### `guides/related-data-and-reindexing.md` (docs)

Line 369: `| Backend HTTP 4xx (e.g. bad request) | \`{:cancel, ...}\` | ...` → `` `{:cancel, {:http_error, status}}` ``. Match the backticked tuple style of lines 371-372.

### `ARCHITECTURE.md` (docs)

Lines 166-170 are a layered bullet list. Replace the line 170 bullet ("Oban job lifecycle remains on Oban's own telemetry events. Scrypath emits search semantics, not a second queue lifecycle.") with a bullet in the same style as lines 168-169: `` `[:scrypath, :oban, :upsert | :delete, ...]` `` carry search semantics (index, document counts, outcome, missing-record removals), while queue lifecycle (queue, job id, `state`) stays on `[:oban, :job, ...]`. Add a link to `guides/telemetry.md`. No test asserts the old sentence.

## Shared Patterns

### Optional-dependency guard
**Source:** `lib/scrypath/oban/upsert_worker.ex` line 1, `lib/scrypath/sync/related_worker.ex` lines 1 and 84-88
**Apply to:** every worker edit. `Scrypath.Telemetry` additions must stay Oban-free.
```elixir
if Code.ensure_loaded?(Oban.Worker) and Code.ensure_loaded?(Oban.Job) do
  defmodule Scrypath.Oban.UpsertWorker do
```

### Span emission
**Source:** `lib/scrypath/sync/related_worker.ex` lines 49-58, `lib/scrypath/telemetry.ex` lines 9-29
**Apply to:** both worker spans. Use a literal event list, start metadata from `common_metadata/3` with extras, and a stop map that never repeats start keys.

### Point event with count measurement
**Source:** `lib/scrypath/operator/failed_work/telemetry.ex` lines 6-16
**Apply to:** `[:scrypath, :oban, :upsert, :missing_removed]`. Use `:telemetry.execute(<literal list>, %{count: n}, metadata)`.

### Distinct id counting
**Source:** `lib/scrypath/chunks.ex` lines 45-50 (`distinct_count/1`, the same identity as `Chunks.ids/1`)
**Apply to:** `document_count`, `missing_count`, and the `missing_removed` `count`.

### Cancel tag shape
**Source:** `lib/scrypath/oban/upsert_worker.ex` lines 22, 49, 55, 59 (`{:cancel, {:invalid_job, tag}}`)
**Apply to:** `cancel_reason/1` flattening (strip `:invalid_job`, keep the atom head) and the D-18 `{:cancel, {:http_error, status}}`.

### Telemetry test capture
**Source:** `test/scrypath/telemetry_test.exs` lines 350-396
**Apply to:** `worker_telemetry_test.exs` and `telemetry_contract_test.exs` through the new `test/support/telemetry_capture.ex`. Use `async: false`, a unique handler id, and `on_exit` detach.

### Docs and package wiring stay in lockstep
**Source:** `mix.exs` lines 188-255, `test/release/package_metadata_test.exs` lines 76-92, `test/scrypath/docs_contract_test.exs` lines 35-60
**Apply to:** the plan that adds `guides/telemetry.md`. All three change in the same plan (Pitfall 7).

## No Analog Found

| File / part | Role | Data Flow | Reason |
|-------------|------|-----------|--------|
| `test/scrypath/telemetry_contract_test.exs`: AST name scan + literal-name guard + guide-table parser | test (contract) | transform | No test parses Elixir source ASTs or markdown tables today. Use the RESEARCH Pattern 5 prototype (`Code.string_to_quoted/2` + `Macro.prewalk/3`; guard on `{{:., _, [mod, fun]}, _, [first | _]}` with `fun in [:span, :execute]`; allowlist `lib/scrypath/telemetry.ex` `span/3`). |

## Metadata

**Analog search scope:** `lib/scrypath/` (telemetry, oban, sync, operator/failed_work, chunks), `test/scrypath/`, `test/support/`, `test/release/`, `test/mix/tasks/`, `guides/`, `docs/`, `mix.exs`, `ARCHITECTURE.md`
**Files scanned:** ~22
**Pattern extraction date:** 2026-10-25
