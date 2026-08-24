# Phase 146: ScrypathOps Web/Client Remediation - Pattern Map

**Mapped:** 2026-08-24  
**Files analyzed:** 4 planned files (3 implementation files; 1 execution evidence artifact)  
**Analogs found:** 4 / 4

## Scope and Preservation Boundary

The planned implementation is limited to ScrypathOps dependency intent, its solver-generated lock closure, a direct production-client compatibility test, and compact phase evidence. `scrypath_ops/config/prod.exs`, `scrypath_ops/config/test.exs`, `ScrypathOps.Mailer`, routes, LiveViews, templates, layouts, CSS, JavaScript, and UI assets are regression references only and must remain unchanged. The UI contract requires a no-UI-file diff and `mix verify.opsui` proof.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `scrypath_ops/mix.exs` | config | transform (declaration -> solver constraints) | `examples/phoenix_meilisearch/mix.exs` | exact role / close dependency cohort |
| `scrypath_ops/mix.lock` | config | transform (solver output -> deterministic resolution) | `examples/phoenix_meilisearch/mix.lock` | exact role / same remediation workflow |
| `scrypath_ops/test/scrypath_ops/swoosh_api_client_req_test.exs` | test | request-response | `test/scrypath/meilisearch/client_test.exs` | same Req.Test transport seam; production client differs |
| `.planning/phases/146-scrypathops-web-client-remediation/146-SUMMARY.md` | config / evidence report | batch | `.planning/phases/145-legacy-phoenix-and-ecto-decimal-remediation/145-02-SUMMARY.md` | exact evidence-report role |

## Pattern Assignments

### `scrypath_ops/mix.exs` (config, transform)

**Analog:** `examples/phoenix_meilisearch/mix.exs`

Use the established `defp deps/0` list layout and pin only the approved direct ownership boundary. The legacy remediation is the closest completed fixed-compatible cohort: its direct requirements are explicit while non-owned packages remain transitive.

**Dependency declaration pattern** ([`examples/phoenix_meilisearch/mix.exs:40`](/Users/jon/projects/scrypath/examples/phoenix_meilisearch/mix.exs:40)-[`mix.exs:54`](/Users/jon/projects/scrypath/examples/phoenix_meilisearch/mix.exs:54)):

```elixir
defp deps do
  [
    {:phoenix, "~> 1.8.9"},
    {:plug, "~> 1.19.5"},
    {:phoenix_ecto, "~> 4.5"},
    {:ecto_sql, "~> 3.14.0"},
    {:postgrex, "~> 0.22.4"},
    {:telemetry_metrics, "~> 1.0"},
    {:telemetry_poller, "~> 1.0"},
    {:jason, "~> 1.2"},
    {:dns_cluster, "~> 0.2.0"},
    {:bandit, "~> 1.12.1"},
    {:oban, "~> 2.21"},
    {:scrypath, path: "../.."}
  ]
end
```

**Apply to the existing Ops list** ([`scrypath_ops/mix.exs:41`](/Users/jon/projects/scrypath/scrypath_ops/mix.exs:41)-[`mix.exs:66`](/Users/jon/projects/scrypath/scrypath_ops/mix.exs:66)):

```elixir
{:phoenix, "~> 1.8.5"}
{:postgrex, ">= 0.0.0"}
{:phoenix_live_view, "~> 1.1.0"}
{:swoosh, "~> 1.16"}
{:req, "~> 0.6.1"}
{:bandit, "~> 1.5"}
```

Replace only those approved requirement strings with Phoenix `~> 1.8.9`, Postgrex `~> 0.22.4`, LiveView `~> 1.1.33`, Swoosh `~> 1.26.3`, retained Req `~> 0.6.1`, and Bandit `~> 1.12.1`. Do not add Plug, Mint, hpax, Finch, Ecto, Decimal, Phoenix Ecto, or Ecto SQL as direct dependencies, and do not add `override: true`. Keep aliases and application configuration unchanged.

### `scrypath_ops/mix.lock` (config, transform)

**Analog:** `examples/phoenix_meilisearch/mix.lock`, with the Phase 145 causal-lock review recorded in [`145-01-SUMMARY.md:54`](/Users/jon/projects/scrypath/.planning/phases/145-legacy-phoenix-and-ecto-decimal-remediation/145-01-SUMMARY.md:54)-[`145-01-SUMMARY.md:59`](/Users/jon/projects/scrypath/.planning/phases/145-legacy-phoenix-and-ecto-decimal-remediation/145-01-SUMMARY.md:59).

**Causal closure review pattern**:

```markdown
- Changed only the planned direct requirements.
- Refreshed only their causal lock closure: direct package dependents and required
  transitives.
- Retained the prior Req/Mint/hpax handoff unchanged when already compliant.
```

**Existing Ops closure to inspect before and after solving** ([`scrypath_ops/mix.lock:4`](/Users/jon/projects/scrypath/scrypath_ops/mix.lock:4), [`mix.lock:26`](/Users/jon/projects/scrypath/scrypath_ops/mix.lock:26), [`mix.lock:31`](/Users/jon/projects/scrypath/scrypath_ops/mix.lock:31), [`mix.lock:35`](/Users/jon/projects/scrypath/scrypath_ops/mix.lock:35), [`mix.lock:40`](/Users/jon/projects/scrypath/scrypath_ops/mix.lock:40), [`mix.lock:43`](/Users/jon/projects/scrypath/scrypath_ops/mix.lock:43), [`mix.lock:45`](/Users/jon/projects/scrypath/scrypath_ops/mix.lock:45)-[`mix.lock:48`](/Users/jon/projects/scrypath/scrypath_ops/mix.lock:48)):

```elixir
"bandit": {:hex, :bandit, "1.11.1", ...}
"hpax": {:hex, :hpax, "1.0.4", ...}
"mint": {:hex, :mint, "1.9.3", ...}
"phoenix": {:hex, :phoenix, "1.8.7", ...}
"phoenix_live_view": {:hex, :phoenix_live_view, "1.1.31", ...}
"plug": {:hex, :plug, "1.19.2", ...}
"postgrex": {:hex, :postgrex, "0.22.2", ...}
"req": {:hex, :req, "0.6.3", ...}
"swoosh": {:hex, :swoosh, "1.26.0", ...}
```

Do not hand-edit checksum or dependency tuple structures. Generate via the approved targeted resolution, retain only explainable causal changes, review each changed row, then prove `mix deps.get --check-locked`. The detached fresh-resolution procedure removes only a disposable worktree copy of this file; it never rewrites the primary lock.

### `scrypath_ops/test/scrypath_ops/swoosh_api_client_req_test.exs` (test, request-response)

**Analog:** `test/scrypath/meilisearch/client_test.exs`

Use the root project’s focused, async ExUnit + `Req.Test` pattern. It already tests a real client over a local Req plug, not a fake production adapter.

**Module/import pattern** ([`test/scrypath/meilisearch/client_test.exs:1`](/Users/jon/projects/scrypath/test/scrypath/meilisearch/client_test.exs:1)-[`client_test.exs:6`](/Users/jon/projects/scrypath/test/scrypath/meilisearch/client_test.exs:6)):

```elixir
defmodule Scrypath.Meilisearch.ClientTest do
  use ExUnit.Case, async: true

  alias Scrypath.Meilisearch.Client

  describe "get_settings/2 (TUNE-05 wire primitive)" do
```

Adapt the module and call `Swoosh.ApiClient.Req.init/0` and `post/4` directly. Do not alter the global test client baseline, which intentionally remains `Swoosh.Adapters.Test` and `:api_client, false` ([`scrypath_ops/config/test.exs:24`](/Users/jon/projects/scrypath/scrypath_ops/config/test.exs:24)-[`test.exs:28`](/Users/jon/projects/scrypath/scrypath_ops/config/test.exs:28)). Production selection remains a reference-only invariant: `config :swoosh, api_client: Swoosh.ApiClient.Req` ([`scrypath_ops/config/prod.exs:23`](/Users/jon/projects/scrypath/scrypath_ops/config/prod.exs:23)-[`prod.exs:27`](/Users/jon/projects/scrypath/scrypath_ops/config/prod.exs:27)).

**Request assertion pattern** ([`test/scrypath/meilisearch/client_test.exs:107`](/Users/jon/projects/scrypath/test/scrypath/meilisearch/client_test.exs:107)-[`client_test.exs:130`](/Users/jon/projects/scrypath/test/scrypath/meilisearch/client_test.exs:130)):

```elixir
stub = Module.concat(__MODULE__, FacetSearchOkStub)

Req.Test.stub(stub, fn conn ->
  assert conn.method == "POST"
  assert conn.request_path == "/indexes/posts_v2/facet-search"
  {:ok, body, conn} = Plug.Conn.read_body(conn)
  params = Jason.decode!(body)

  assert params["facetName"] == "genre"
  Req.Test.json(conn, %{"facetHits" => [%{"value" => "comedy"}]})
end)
```

Adapt it to inspect the Swoosh POST URL, raw request body, provider headers, Swoosh user-agent, and caller `email.private[:client_options]`. Include intentionally conflicting caller `headers`, `body`, and `decode_body` options to prove Swoosh’s values take precedence; assert raw response preservation and `{:ok, status, headers, body}` normalization.

**Transport-error pattern** ([`test/scrypath/meilisearch/client_test.exs:39`](/Users/jon/projects/scrypath/test/scrypath/meilisearch/client_test.exs:39)-[`client_test.exs:50`](/Users/jon/projects/scrypath/test/scrypath/meilisearch/client_test.exs:50)):

```elixir
stub = Module.concat(__MODULE__, GetSettingsTransportErrorStub)

Req.Test.stub(stub, fn conn ->
  Req.Test.transport_error(conn, :timeout)
end)

assert {:error, {:transport_error, %Req.TransportError{reason: :timeout}}} =
         Client.get_settings("posts_v2",
           meilisearch_url: "http://localhost:7700",
           req_options: [plug: {Req.Test, stub}, retry: false]
         )
```

For the Swoosh contract, keep `retry: false` inside that email’s `private[:client_options]` and assert the real `Swoosh.ApiClient.Req` propagates the `Req.TransportError` shape it returns. Never contact a provider or use credentials/network. If direct invocation cannot carry all needed test options, follow the async-false restore discipline from [`scrypath_ops/test/scrypath_ops/application_test.exs:4`](/Users/jon/projects/scrypath/scrypath_ops/test/scrypath_ops/application_test.exs:4)-[`application_test.exs:21`](/Users/jon/projects/scrypath/scrypath_ops/test/scrypath_ops/application_test.exs:21): capture prior env, restore/delete it in `on_exit/1`, and then restart the application.

### `.planning/phases/146-scrypathops-web-client-remediation/146-SUMMARY.md` (config / evidence report, batch)

**Analog:** `.planning/phases/145-legacy-phoenix-and-ecto-decimal-remediation/145-02-SUMMARY.md`

Use the completed remediation’s compact, structured evidence shape rather than raw command logs.

**Front matter / evidence layout** ([`145-02-SUMMARY.md:1`](/Users/jon/projects/scrypath/.planning/phases/145-legacy-phoenix-and-ecto-decimal-remediation/145-02-SUMMARY.md:1)-[`145-02-SUMMARY.md:44`](/Users/jon/projects/scrypath/.planning/phases/145-legacy-phoenix-and-ecto-decimal-remediation/145-02-SUMMARY.md:44), [`145-02-SUMMARY.md:75`](/Users/jon/projects/scrypath/.planning/phases/145-legacy-phoenix-and-ecto-decimal-remediation/145-02-SUMMARY.md:75)-[`145-02-SUMMARY.md:117`](/Users/jon/projects/scrypath/.planning/phases/145-legacy-phoenix-and-ecto-decimal-remediation/145-02-SUMMARY.md:117)):

```markdown
---
phase: 145-legacy-phoenix-and-ecto-decimal-remediation
plan: 02
subsystem: dependency security
tags: [elixir, phoenix, ecto, plug, hex, audit]
---

## Verification Evidence

### Environment

| Item | Value |
| --- | --- |
| UTC evidence window | ... |
| Elixir / OTP | ... |
| Mix / Hex | ... |

### Deterministic Recovery Gates

| Command | Exit | Classification |
| --- | --- | --- |
| `mix deps.get --check-locked` | 0 | deterministic checked lock |
```

Record only the candidate SHA, UTC window, environment/tool versions, commands with exits, fixed-version matrix, audit result, causal lock rows, and deterministic-versus-network classification. Explicitly state Postgrex dual-source re-check result or a blocking stop. Do not commit raw logs, disposable locks, advisory snapshots, dependency trees, provider credentials, or generated service artifacts.

## Shared Patterns

### Dependency Ownership and Reproducibility

**Sources:** [`scrypath_ops/mix.exs:41`](/Users/jon/projects/scrypath/scrypath_ops/mix.exs:41), [`examples/phoenix_meilisearch/mix.exs:40`](/Users/jon/projects/scrypath/examples/phoenix_meilisearch/mix.exs:40), [`145-01-SUMMARY.md:54`](/Users/jon/projects/scrypath/.planning/phases/145-legacy-phoenix-and-ecto-decimal-remediation/145-01-SUMMARY.md:54)

Apply fixed-compatible three-part pessimistic bounds only at direct ownership points; retain the Phase 144 Req/Mint/hpax handoff and all designated transitive packages. Solver output is reviewed causal closure, not an opportunity for package-head cleanup.

### Test Isolation and Error Handling

**Sources:** [`test/scrypath/meilisearch/client_test.exs:39`](/Users/jon/projects/scrypath/test/scrypath/meilisearch/client_test.exs:39), [`scrypath_ops/test/scrypath_ops/application_test.exs:8`](/Users/jon/projects/scrypath/scrypath_ops/test/scrypath_ops/application_test.exs:8)

Use `Req.Test` with per-test module names and `retry: false` for deterministic error cases. Preserve the normal Swoosh test configuration; any temporary app config must restore the exact prior/unset state in `on_exit/1`. Assert returned tuples/errors rather than rescuing or hiding transport errors.

### Existing Regression Gate

**Source:** [`lib/mix/tasks/verify.opsui.ex:24`](/Users/jon/projects/scrypath/lib/mix/tasks/verify.opsui.ex:24)-[`verify.opsui.ex:48`](/Users/jon/projects/scrypath/lib/mix/tasks/verify.opsui.ex:48)

```elixir
def run(args) do
  Mix.Task.run("app.start")
  ensure_no_args!(args)
  ops_dir = Path.expand("scrypath_ops", File.cwd!())
  script = "export CI=true; printf 'n\\n' | mix deps.get && mix test"
  {out, status} = System.cmd("bash", ["-lc", script], cd: ops_dir, stderr_to_stdout: true)
  Mix.shell().info(out)
  if status != 0, do: Mix.raise("verify.opsui failed: `#{script}` (in #{ops_dir}) exited #{status}")
end
```

Do not duplicate route, LiveView, endpoint, Repo, browser, or upstream-exploit tests; `mix verify.opsui` is the retained integration proof for those boundaries.

## No Analog Found

None. The only new source file is a focused client contract test; the root Req.Test suite provides the closest transport analogue while production configuration supplies the Swoosh-specific invariant.

## Metadata

**Analog search scope:** `scrypath_ops/`, root `test/`, `lib/mix/tasks/`, Phase 144 and 145 evidence artifacts  
**Files scanned:** 13 primary analog/reference files  
**Pattern extraction date:** 2026-08-24
