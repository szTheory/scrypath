# Phase 144: Root HTTP Client Dependency Remediation - Pattern Map

**Mapped:** 2026-08-22  
**Files analyzed:** 14  
**Analogs found:** 12 / 14

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `.planning/ROADMAP.md` | config | transform | `.planning/ROADMAP.md` Phase 145 criteria | exact |
| `.planning/REQUIREMENTS.md` | config | transform | existing EVID requirement wording | exact |
| `mix.exs` | config | transform | `mix.exs` dependency list | exact |
| `scrypath_ops/mix.exs` | config | transform | root `mix.exs` dependency list | role-match |
| `examples/scrypath_ecommerce/mix.exs` | config | transform | `scrypath_ops/mix.exs` dependency list | exact |
| `mix.lock` | config | transform | current root lock closure | exact |
| `scrypath_ops/mix.lock` | config | transform | current root lock closure | role-match |
| `examples/phoenix_meilisearch/mix.lock` | config | transform | current root lock closure | role-match |
| `examples/scrypath_ecommerce/mix.lock` | config | transform | current root lock closure | role-match |
| `test/scrypath/meilisearch/client_test.exs` | test | request-response | same file’s Req.Test GET/error cases | exact |
| `test/scrypath/telemetry_test.exs` | test | event-driven | same file’s request-span test and capture helper | exact |
| `lib/scrypath/meilisearch/client.ex` (only if a demonstrated upgrade failure requires it) | service | request-response | same file’s private `run_request/5` seam | exact |
| `.planning/phases/144-root-http-client-dependency-remediation/144-SUMMARY.md` | config | batch | prior phase summary convention unavailable in active scope | no analog |
| `.planning/phases/144-root-http-client-dependency-remediation/144-VERIFICATION.md` | config | batch | prior phase verification convention unavailable in active scope | no analog |

## Pattern Assignments

### `.planning/ROADMAP.md` and `.planning/REQUIREMENTS.md` (config, transform)

**Analog:** Their existing phase/requirement entries, especially `.planning/ROADMAP.md` lines 30-39 and `.planning/REQUIREMENTS.md` lines 22-26.

Keep the existing concise declarative shape; update only Phase 144 criterion 4 and EVID-02 so they truthfully describe the single atomic cross-graph Req handoff, then preserve the ordered later graph-local batches.

```markdown
**Success Criteria** (what must be TRUE):
  1. ...
  4. [one bounded, explained cross-graph compatibility handoff; later graph-local work remains ordered]

- [ ] **EVID-02:** [one minimal explained shared Req compatibility handoff, followed by graph-local commits]
```

Do not move Phase 145-147 ownership or introduce a new requirement: the traceability table at `.planning/REQUIREMENTS.md` lines 49-60 remains the boundary.

---

### `mix.exs`, `scrypath_ops/mix.exs`, and `examples/scrypath_ecommerce/mix.exs` (config, transform)

**Analog:** existing `defp deps/0` lists: root `mix.exs` lines 88-99, Ops `scrypath_ops/mix.exs` lines 41-63, and ecommerce `examples/scrypath_ecommerce/mix.exs` lines 34-56.

**Dependency declaration pattern:** retain a narrow direct Hex constraint in the existing list; change only the declared floor.

```elixir
# mix.exs, existing form at lines 88-99
defp deps do
  [
    {:ecto, "~> 3.13"},
    {:nimble_options, "~> 1.1"},
    {:oban, "~> 2.21", optional: true},
    {:req, "~> 0.5"},
    {:jason, "~> 1.4"},
    {:plug, "~> 1.18", only: :test}
  ]
end
```

Apply the decided `{:req, "~> 0.6.1"}` substitution in all three manifests; alter the root test-only Plug entry to `{:plug, "~> 1.19.5", only: :test}`. Preserve list position, option scope, path dependencies, and all other direct dependencies. In particular, ecommerce’s path topology at lines 34-37 and Ops’s root path dependency at lines 41-44 must remain unchanged. Do not add direct Mint/hpax entries, overrides, or security-ignore settings.

---

### `mix.lock`, `scrypath_ops/mix.lock`, `examples/phoenix_meilisearch/mix.lock`, and `examples/scrypath_ecommerce/mix.lock` (config, transform)

**Analog:** current root closure at `mix.lock` lines 17-31, mirrored in Ops at `scrypath_ops/mix.lock` lines 20-46 and ecommerce at `examples/scrypath_ecommerce/mix.lock` lines 14-38.

**Lock update pattern:** lockfiles are Mix solver output, never manually version-pinned. Regenerate each independent graph after its applicable manifest/path dependency changes, then review the causal closure only.

```elixir
# Current root Req closure, mix.lock lines 17-31
"finch": {:hex, :finch, "0.22.0", ... [{:mint, "~> 1.8", ...}], ...},
"hpax": {:hex, :hpax, "1.0.3", ...},
"mint": {:hex, :mint, "1.8.0", ... [{:hpax, "~> 0.1.1 or ~> 0.2.0 or ~> 1.0", ...}], ...},
"plug": {:hex, :plug, "1.19.2", ...},
"req": {:hex, :req, "0.5.18", ... [{:finch, "~> 0.21.0 or ~> 0.22.0", ...}], ...}
```

Treat Req, Finch, Mint, hpax, root Plug, and unavoidable solver-caused rows as the sole review set. The legacy example has no direct Req declaration: its lock is updated because its root path dependency is resolved in that graph. Validate every touched graph with `mix deps.get --check-locked`; do not hand-edit hashes or retain unrelated lock churn.

---

### `test/scrypath/meilisearch/client_test.exs` (test, request-response)

**Analog:** `test/scrypath/meilisearch/client_test.exs` lines 6-37.

**Imports/setup pattern** (lines 1-4):

```elixir
defmodule Scrypath.Meilisearch.ClientTest do
  use ExUnit.Case, async: true

  alias Scrypath.Meilisearch.Client
```

**Req.Test contract pattern** (lines 7-20): assert the wire request inside a uniquely named stub, then invoke the public client function with the standard `meilisearch_url` and injected plug.

```elixir
stub = Module.concat(__MODULE__, GetSettingsOkStub)

Req.Test.stub(stub, fn conn ->
  assert conn.method == "GET"
  assert conn.request_path == "/indexes/posts_v2/settings"
  Req.Test.json(conn, %{"rankingRules" => ["words", "typo"]})
end)

assert {:ok, %{"rankingRules" => ["words", "typo"]}} =
         Client.get_settings("posts_v2",
           meilisearch_url: "http://localhost:7700",
           req_options: [plug: {Req.Test, stub}]
         )
```

**Error assertion pattern** (lines 23-36): produce the backend response through `Req.Test` and assert the public tagged tuple, not a Req-internal response.

```elixir
assert {:error, {:http_error, 404, _body}} =
         Client.get_settings("missing_index",
           meilisearch_url: "http://localhost:7700",
           req_options: [plug: {Req.Test, stub}]
         )
```

Add only the three causal migration cases here: `Req.Test.transport_error/2` with `retry: false` and the existing injected plug; default API-key plus caller-header merging; and `Client.tasks/2` list filters encoded once as comma-separated query values. Assert `conn`’s observable headers/query parameters and the stable tuple. Do not test Req compression, multipart, redirect, or retry internals.

---

### `test/scrypath/telemetry_test.exs` (test, event-driven)

**Analog:** request-span assertion at lines 200-235 and capture helpers at lines 292-338.

**Capture pattern:** attach to start/stop/exception variants of the public event prefix, execute the public operation, then assert only the selected metadata.

```elixir
client_events =
  capture_events([[:scrypath, :meilisearch, :request]], fn ->
    assert {:ok, %{"taskUid" => 301, "status" => "enqueued"}} =
             Client.upsert_documents("telemetry_posts", documents,
               meilisearch_url: "http://localhost:7700",
               req_options: [plug: {Req.Test, req_stub()}]
             )
  end)

request_stop = find_event(client_events, [:scrypath, :meilisearch, :request, :stop])
assert request_stop.metadata.method == :post
assert request_stop.metadata.path == "/indexes/telemetry_posts/documents"
assert request_stop.metadata.status_code == 202
```

```elixir
defp capture_events(prefixes, fun) do
  parent = self()
  ref = make_ref()
  handler_id = "scrypath-telemetry-test-#{System.unique_integer([:positive])}"

  event_names =
    for prefix <- prefixes, suffix <- [:start, :stop, :exception], do: prefix ++ [suffix]
  :telemetry.attach_many(handler_id, event_names, &__MODULE__.handle_event/4, {parent, ref})
  # execute fun, receive the messages, and detach handler in the existing helper
end
```

Add one error-span case using the same helper and a retry-disabled `Req.Test.transport_error/2` request. Require error metadata to be present, then explicitly refute `:headers`, `:body`, API-key values, and any other request payload fields. Keep this test module `async: false`, because it attaches global telemetry handlers.

---

### `lib/scrypath/meilisearch/client.ex` (service, request-response; conditional only)

**Analog:** the existing single Req seam at lines 137-176.

**Core request, normalization, and telemetry pattern:**

```elixir
Telemetry.span([:scrypath, :meilisearch, :request], metadata, fn ->
  response =
    request(config)
    |> Req.request([method: method, url: path] ++ req_opts)

  {normalize_response(response), response_metadata(response)}
end)

defp normalize_response({:ok, %Req.Response{status: status, body: body}})
     when status >= 200 and status < 300 and is_map(body),
     do: {:ok, body}

defp normalize_response({:ok, %Req.Response{status: status, body: body}}),
  do: {:error, {:http_error, status, body}}

defp normalize_response({:error, exception}), do: {:error, {:transport_error, exception}}
```

**Options and auth merge pattern** (lines 152-159 and 211-215): caller options are retained, a base URL is inserted only when missing, and default API-key headers prepend to caller headers.

```elixir
config
|> Keyword.get(:req_options, [])
|> Keyword.put_new(:base_url, base_url!(config))
|> Keyword.update(:headers, default_headers(config), &(default_headers(config) ++ &1))
|> Req.new()
```

Do not edit this file unless Req 0.6 produces an actual compile or focused contract failure. If that happens, make the smallest private change in this seam, preserve all the above return/telemetry meanings and JSON-only defaults, and add its focused regression test before proceeding. This phase has no analog for a new public transport abstraction because one is explicitly out of scope.

---

### `144-SUMMARY.md` and `144-VERIFICATION.md` (config, batch)

**No close in-scope analog found.** Use the research-prescribed compact audit-record structure rather than raw logs: candidate SHA; timestamp; OS/Elixir/OTP/Hex; commands and exits; selected Req/Mint/hpax/Plug versions; audit result; deterministic versus network-dependent classification; and the separately reported live-smoke availability/result. Do not commit disposable locks, registry snapshots, full dependency trees, or command transcripts.

## Shared Patterns

### Private Req boundary and stable errors

**Source:** `lib/scrypath/meilisearch/client.ex` lines 137-176  
**Apply to:** focused client tests and any contingency compatibility fix.

Route calls through the private `run_request/5` seam and assert only stable public result tuples. Transport errors normalize to `{:error, {:transport_error, exception}}`; non-2xx or non-map successes normalize to `{:error, {:http_error, status, body}}`.

### Caller options and API-key headers

**Source:** `lib/scrypath/meilisearch/client.ex` lines 152-159 and 211-215  
**Apply to:** the header-merge contract test.

The client owns the default `x-meili-api-key` header but preserves supplied headers and options. Verify this at the plug boundary; never inspect Req struct internals.

### Telemetry privacy

**Source:** `lib/scrypath/meilisearch/client.ex` lines 137-149 and 175-176; `test/scrypath/telemetry_test.exs` lines 200-235 and 292-338.  
**Apply to:** error-span coverage.

Span metadata contains request identity (`method`, `path`, optional index) plus status or inspected error. Tests must prove failures do not publish headers, request bodies, or API keys.

### Verification convention

**Source:** `CONTRIBUTING.md` lines 75 and 81-98.  
**Apply to:** phase verification.

Run the deterministic root bundle (`mix deps.get`, warnings-as-errors compile, fast non-integration tests, `mix verify --exclude integration`, `mix verify.phase11`, and `mix verify.phase99`) and `mix deps.get --check-locked` in each of the four affected graphs. `mix verify.opsui` is the established path-dependent Ops check. Report `mix verify.meilisearch_smoke` only as supplemental service-dependent evidence. Fresh lockless resolution and `mix hex.audit` are network-dependent proof, not substitutes for the locked gates.

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `144-SUMMARY.md` | config | batch | No active in-scope phase evidence record is a suitable concrete analog; use the locked compact audit format. |
| `144-VERIFICATION.md` | config | batch | No active in-scope verification artifact provides a closer applicable template. |

## Metadata

**Analog search scope:** root library, Req tests, telemetry tests, all four Mix graphs, roadmap/requirements, and contributor verification guidance.  
**Files scanned:** 16  
**Pattern extraction date:** 2026-08-22
