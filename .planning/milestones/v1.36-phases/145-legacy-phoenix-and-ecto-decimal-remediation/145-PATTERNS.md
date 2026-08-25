# Phase 145: Legacy Phoenix and Ecto/Decimal Remediation - Pattern Map

**Mapped:** 2026-08-22  
**Files analyzed:** 5 planned files  
**Analogs found:** 5 / 5

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
| --- | --- | --- | --- | --- |
| `examples/phoenix_meilisearch/mix.exs` | config | transform (manifest → resolver) | same file, `deps/0` | exact |
| `examples/phoenix_meilisearch/mix.lock` | config | transform (resolver → deterministic lock) | same file, current Hex rows | exact |
| `examples/phoenix_meilisearch/test/scrypath_demo/ecto_compatibility_test.exs` | test | CRUD | `test/smoke/meilisearch_stack_test.exs` + `test/support/data_case.ex` | role-and-flow match |
| `examples/phoenix_meilisearch/test/scrypath_demo_web/endpoint_compatibility_test.exs` | test | request-response / event-driven | `test/support/conn_case.ex` + `test/scrypath_demo_web/controllers/error_json_test.exs` | role-and-flow match |
| `145-03-SUMMARY.md` (or the execution plan's compact phase evidence section) | documentation/evidence | batch | `144-03-SUMMARY.md` | exact |

## Pattern Assignments

### `examples/phoenix_meilisearch/mix.exs` (config, manifest-to-resolver transform)

**Analog:** `examples/phoenix_meilisearch/mix.exs`

Preserve the generated Mix project layout and change only the four direct cohort rows. `phoenix_ecto`, telemetry packages, Oban, and the path dependency are not part of this dependency ownership change.

**Dependency-list pattern** ([lines 40-53](../../../examples/phoenix_meilisearch/mix.exs#L40-L53)):

```elixir
defp deps do
  [
    {:phoenix, "~> 1.8.5"},
    {:phoenix_ecto, "~> 4.5"},
    {:ecto_sql, "~> 3.13"},
    {:postgrex, ">= 0.0.0"},
    # unchanged direct dependencies
    {:bandit, "~> 1.5"},
    {:oban, "~> 2.21"},
    {:scrypath, path: "../.."}
  ]
end
```

Replace only the four designated requirements with the locked three-part cohort bounds:

```elixir
{:phoenix, "~> 1.8.9"}
{:ecto_sql, "~> 3.14.0"}
{:postgrex, "~> 0.22.4"}
{:bandit, "~> 1.12.1"}
```

**Existing deterministic gate pattern** ([lines 62-68](../../../examples/phoenix_meilisearch/mix.exs#L62-L68)):

```elixir
test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
precommit: ["compile --warnings-as-errors", "deps.unlock --unused", "format", "test"]
```

Do not add a Mix task or alias. The existing alias owns the clean-database posture; the executor invokes the separate already-migrated `mix ecto.migrate --quiet` check explicitly.

---

### `examples/phoenix_meilisearch/mix.lock` (config, resolver-to-lock transform)

**Analog:** `examples/phoenix_meilisearch/mix.lock`

**Current lock-row pattern** ([line 1](../../../examples/phoenix_meilisearch/mix.lock#L1), selected rows reported by `rg`):

```elixir
"bandit": {:hex, :bandit, "1.10.4", ..., [{:hpax, "~> 1.0", ...}, {:plug, "~> 1.18", ...}], ...},
"ecto": {:hex, :ecto, "3.13.5", ..., [{:decimal, "~> 2.0", ...}], ...},
"ecto_sql": {:hex, :ecto_sql, "3.13.5", ..., [{:ecto, "~> 3.13.0", ...}], ...},
"phoenix": {:hex, :phoenix, "1.8.5", ..., [{:plug, "~> 1.14", ...}], ...},
"postgrex": {:hex, :postgrex, "0.22.0", ..., [{:decimal, "~> 1.5 or ~> 2.0", ...}], ...}
```

Treat the lock as Mix-generated resolution, not hand-maintained configuration. Refresh only the causal closure of Phoenix, Bandit, Ecto SQL, Postgrex, and the pre-existing Phase 144 Req/Mint/hpax handoff; then explain each moved row. The acceptance proof checks Ecto/Decimal and Plug transitively, so never add `:ecto`, `:decimal`, `:mint`, or `:hpax` to `mix.exs`, and never use `override: true`.

**Validation pattern:** `mix deps.get --check-locked` is the project's lock consistency check; run it before database and endpoint gates. The detached probe must remove only its disposable lock, use isolated Mix build/deps paths, assert the locked bounds, and run unsuppressed `mix hex.audit`.

---

### `examples/phoenix_meilisearch/test/scrypath_demo/ecto_compatibility_test.exs` (test, CRUD)

**Analogs:** `examples/phoenix_meilisearch/test/support/data_case.ex`; `examples/phoenix_meilisearch/test/smoke/meilisearch_stack_test.exs`; existing schemas `lib/scrypath_demo/blog/{author,post}.ex`.

**Imports and Sandbox pattern** ([`data_case.ex` lines 19-40](../../../examples/phoenix_meilisearch/test/support/data_case.ex#L19-L40)):

```elixir
use ScrypathDemo.DataCase, async: true

# DataCase makes Repo, Ecto.Changeset, Ecto.Query, and errors_on/1 available.
pid = Ecto.Adapters.SQL.Sandbox.start_owner!(ScrypathDemo.Repo, shared: not tags[:async])
on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
```

Use the case template; do not copy the owner lifecycle into the new test or start a second database harness. Keep the database contract `async: true`; it must not spawn a Repo-using listener/process.

**Fixture/insert pattern** ([`meilisearch_stack_test.exs` lines 31-47](../../../examples/phoenix_meilisearch/test/smoke/meilisearch_stack_test.exs#L31-L47)):

```elixir
{:ok, post} =
  %Post{}
  |> Post.changeset(%{title: "Smoke title", body: "Body", status: "published"})
  |> Repo.insert()
```

For this deterministic contract, define private test-local helpers for a valid `Author` and `Post` if they improve readability. Use `Author.changeset/2` and `Post.changeset/2`; assert invalid changesets and `errors_on/1` required-field errors before inserting a representative author/post. Query the persisted post, preload `:author`, and assert title, body, status, denormalized `author_name`, association, and `inserted_at`/`updated_at` timestamps.

**Schema/validation contract** ([`author.ex` lines 19-25, 42-46](../../../examples/phoenix_meilisearch/lib/scrypath_demo/blog/author.ex#L19-L25); [`post.ex` lines 10-23](../../../examples/phoenix_meilisearch/lib/scrypath_demo/blog/post.ex#L10-L23)):

```elixir
schema "authors" do
  field(:name, :string)
  has_many(:posts, ScrypathDemo.Blog.Post)
  timestamps(type: :utc_datetime)
end

post
|> Ecto.Changeset.cast(attrs, [:title, :body, :status, :author_id, :author_name])
|> Ecto.Changeset.validate_required([:title, :body, :status])
```

Do not call `Blog.update_author/3`: its [lines 37-48](../../../examples/phoenix_meilisearch/lib/scrypath_demo/blog.ex#L37-L48) intentionally update rows and call `Scrypath.sync_related/3`, which would make this Ecto proof depend on Meilisearch.

---

### `examples/phoenix_meilisearch/test/scrypath_demo_web/endpoint_compatibility_test.exs` (test, request-response and event-driven)

**Analogs:** `examples/phoenix_meilisearch/test/support/conn_case.ex`; `examples/phoenix_meilisearch/test/scrypath_demo_web/controllers/error_json_test.exs`; configured endpoint/router.

**ConnCase imports/setup pattern** ([`conn_case.ex` lines 20-37](../../../examples/phoenix_meilisearch/test/support/conn_case.ex#L20-L37)):

```elixir
@endpoint ScrypathDemoWeb.Endpoint

use ScrypathDemoWeb, :verified_routes
import Plug.Conn
import Phoenix.ConnTest
import ScrypathDemoWeb.ConnCase

setup tags do
  ScrypathDemo.DataCase.setup_sandbox(tags)
  {:ok, conn: Phoenix.ConnTest.build_conn()}
end
```

Put the fast pipeline checks in a `use ScrypathDemoWeb.ConnCase` module. Request an existing unmatched `/api/...` path through the real endpoint/router; send the malformed cookie with the built connection; assert the existing JSON 404 shape and non-crashing behavior. Do not add a route or inspect a nonexistent session workflow.

**JSON error assertion pattern** ([`error_json_test.exs` lines 1-11](../../../examples/phoenix_meilisearch/test/scrypath_demo_web/controllers/error_json_test.exs#L1-L11)):

```elixir
use ScrypathDemoWeb.ConnCase, async: true

test "renders 404" do
  assert ScrypathDemoWeb.ErrorJSON.render("404.json", %{}) ==
           %{errors: %{detail: "Not Found"}}
end
```

**Real listener boundary** ([`config/test.exs` lines 17-22](../../../examples/phoenix_meilisearch/config/test.exs#L17-L22); [`endpoint.ex` lines 37-48](../../../examples/phoenix_meilisearch/lib/scrypath_demo_web/endpoint.ex#L37-L48)):

```elixir
config :scrypath_demo, ScrypathDemoWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  server: false

plug Plug.RequestId
plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]
plug Plug.Parsers, parsers: [:urlencoded, :multipart, :json], pass: ["*/*"],
  json_decoder: Phoenix.json_library()
plug Plug.Session, @session_options
plug ScrypathDemoWeb.Router
```

In the same file, isolate the real HTTP contract in `async: false`. Attach a unique telemetry handler for `[:bandit, :request, :stop]`, start the configured Phoenix/Bandit endpoint Plug with `start_supervised!/1` on loopback port `0`, obtain its public adapter server info/bound port, make one normal HTTP/1 JSON request using existing `Req`, assert the stable JSON error response and matching stop event, then detach the handler in `on_exit`. Do not use a fixed port, sleep, `:httpc`, a new dependency, WebSocket/HTTP2 assertions, or a permanent endpoint configuration change.

---

### `145-03-SUMMARY.md` (documentation/evidence, batch)

**Analog:** [`144-03-SUMMARY.md` lines 36-89](../144-root-http-client-dependency-remediation/144-03-SUMMARY.md#L36-L89)

Record compact evidence only after the candidate is complete: candidate SHA, UTC timestamp, host/Elixir/OTP/Mix/Hex versions, commands and exit statuses, the reviewed causal lock rows, fresh selected versions and dependency paths, audit status, and hard-versus-supplemental classification. The prior phase keeps this information as tables rather than raw logs:

```markdown
### Deterministic Checked-Lock and Root Release-Train Proof

| Command | Exit | Classification |
| --- | --- | --- |
| `mix deps.get --check-locked` | 0 | deterministic |

### Supplemental Live Smoke

... recorded as passed, failed, or unavailable — never as a pass when prerequisites are absent.

### Current-Registry Detached Probe

| Package | Fresh version | Required bound | Compact path |
| --- | --- | --- | --- |
```

The phase-specific record should cover the legacy graph only and use Phase 145 bounds. Do not commit raw command logs, temporary locks/worktrees, dependency trees, service artifacts, or advisory snapshots.

## Shared Patterns

### Generated SQL Sandbox lifecycle

**Source:** [`examples/phoenix_meilisearch/test/support/data_case.ex` lines 30-40](../../../examples/phoenix_meilisearch/test/support/data_case.ex#L30-L40)  
**Apply to:** database contract and any test using Repo.

```elixir
setup tags do
  ScrypathDemo.DataCase.setup_sandbox(tags)
  :ok
end

def setup_sandbox(tags) do
  pid = Ecto.Adapters.SQL.Sandbox.start_owner!(ScrypathDemo.Repo, shared: not tags[:async])
  on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
end
```

Use `DataCase` or `ConnCase` rather than manually checking out or changing Sandbox mode. A test that starts a real endpoint stays serial and ensures all spawned work is supervised and stopped before teardown.

### Endpoint and JSON boundary

**Source:** [`endpoint.ex` lines 37-48](../../../examples/phoenix_meilisearch/lib/scrypath_demo_web/endpoint.ex#L37-L48); [`router.ex` lines 4-10](../../../examples/phoenix_meilisearch/lib/scrypath_demo_web/router.ex#L4-L10)  
**Apply to:** endpoint compatibility test only.

```elixir
pipeline :api do
  plug :accepts, ["json"]
end

scope "/api", ScrypathDemoWeb do
  pipe_through :api
end
```

Exercise this existing unmatched route boundary. The test validates compatibility; it must not expand the API surface.

### Existing HTTP client and supervised test cleanup

**Source:** [`examples/phoenix_meilisearch/AGENTS.md`](../../../examples/phoenix_meilisearch/AGENTS.md); [`meilisearch_stack_test.exs` lines 61-70](../../../examples/phoenix_meilisearch/test/smoke/meilisearch_stack_test.exs#L61-L70)  
**Apply to:** real listener test and optional live-smoke reporting.

Use the already-present `Req` client. Start processes with `start_supervised!/1`; synchronize by event/message rather than `Process.sleep/1`; make cleanup deterministic with `on_exit` and telemetry detachment.

### Evidence taxonomy

**Source:** [`144-03-SUMMARY.md` lines 47-89](../144-root-http-client-dependency-remediation/144-03-SUMMARY.md#L47-L89)  
**Apply to:** all final phase evidence.

Keep reviewed-lock commands, clean-DB tests, no-op migration, legacy `precommit`, and root fast tests as hard deterministic evidence. The detached fresh resolution/audit is network-dependent evidence; the Postgres/Meilisearch smoke is supplemental and may be unavailable. Neither an outage nor missing services is a passing result.

## No Analog Found

None. The precise ephemeral Bandit startup invocation remains an execution-time compatibility probe because test configuration sets the permanent endpoint server to `false`, but its required supervision, loopback, port-0, Req, telemetry, and cleanup patterns all have direct project analogs and locked research guidance.

## Metadata

**Analog search scope:** `examples/phoenix_meilisearch/{mix.exs,mix.lock,config,test.exs,lib,test}`, Phase 144 evidence artifacts, and relevant Phoenix/Ecto/Elixir project references under `prompts/`.  
**Files scanned:** 14  
**Pattern extraction date:** 2026-08-22
