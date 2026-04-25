# Phase 69: Adopter verify spine - Pattern Map

**Mapped:** 2026-04-22
**Files analyzed:** 7
**Analogs found:** 7 / 7

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/mix/tasks/verify.adopter.ex` | utility | batch | `lib/mix/tasks/verify.opsui.ex` | exact |
| `mix.exs` | config | request-response | `mix.exs` | exact |
| `test/scrypath/docs_contract_test.exs` | test | transform | `test/scrypath/docs_contract_test.exs` | exact |
| `README.md` | config | transform | `README.md` | exact |
| `CONTRIBUTING.md` | config | transform | `CONTRIBUTING.md` | exact |
| `.github/workflows/ci.yml` | config | batch | `.github/workflows/ci.yml` | exact |
| `test/mix/tasks/verify_adopter_test.exs` | test | batch | `test/mix/tasks/verify_workspace_clean_test.exs` | role-match |

## Pattern Assignments

### `lib/mix/tasks/verify.adopter.ex` (utility, batch)

**Primary analog:** `lib/mix/tasks/verify.opsui.ex`

**Task surface pattern** ([lib/mix/tasks/verify.opsui.ex](/Users/jon/projects/scrypath/lib/mix/tasks/verify.opsui.ex:1), lines 1-22):
```elixir
defmodule Mix.Tasks.Verify.Opsui do
  use Mix.Task

  @shortdoc "Runs ScrypathOps (`scrypath_ops`) tests the same way the scrypath-ops CI job does"

  @moduledoc """
  Runs the `scrypath_ops` application tests the same way the **`scrypath-ops`** GitHub Actions job does.
  ...
  This task does not accept arguments. For the full CI ↔ **`mix verify.*`** matrix and job names, see
  [CONTRIBUTING.md](CONTRIBUTING.md).
  """
```

**Root orchestration pattern** ([lib/mix/tasks/verify.opsui.ex](/Users/jon/projects/scrypath/lib/mix/tasks/verify.opsui.ex:24), lines 24-49):
```elixir
@impl true
def run(args) do
  Mix.Task.run("app.start")
  ensure_no_args!(args)

  ops_dir = Path.expand("scrypath_ops", File.cwd!())

  unless File.dir?(ops_dir) do
    Mix.raise("verify.opsui: expected #{ops_dir} to exist")
  end

  Mix.shell().info("==> verify.opsui: cd scrypath_ops && mix deps.get && mix test")

  script = "export CI=true; printf 'n\\n' | mix deps.get && mix test"

  {out, status} =
    System.cmd("bash", ["-lc", script], cd: ops_dir, stderr_to_stdout: true)

  Mix.shell().info(out)

  if status != 0 do
    Mix.raise("verify.opsui failed: `#{script}` (in #{ops_dir}) exited #{status}")
  end
end
```

**No-arg guard pattern** ([lib/mix/tasks/verify.opsui.ex](/Users/jon/projects/scrypath/lib/mix/tasks/verify.opsui.ex:51), lines 51-55):
```elixir
defp ensure_no_args!([]), do: :ok

defp ensure_no_args!(args) do
  Mix.raise("verify.opsui does not accept arguments, got: #{Enum.join(args, " ")}")
end
```

**Secondary analog for strict flag parsing and loud live-mode failure:** `lib/mix/tasks/verify.phase5.ex`

**Strict option parsing** ([lib/mix/tasks/verify.phase5.ex](/Users/jon/projects/scrypath/lib/mix/tasks/verify.phase5.ex:19), lines 19-27):
```elixir
@impl true
def run(args) do
  Mix.Task.run("app.start")

  {opts, _argv, _invalid} =
    OptionParser.parse(args,
      strict: [skip_integration: :boolean]
    )
```

**Loud env prerequisite pattern** ([lib/mix/tasks/verify.phase5.ex](/Users/jon/projects/scrypath/lib/mix/tasks/verify.phase5.ex:60), lines 60-71):
```elixir
defp ensure_integration_env! do
  unless System.get_env("SCRYPATH_MEILISEARCH_URL") do
    Mix.raise("""
    SCRYPATH_MEILISEARCH_URL is required for live integration verification.

    Example:
      SCRYPATH_INTEGRATION=1 SCRYPATH_MEILISEARCH_URL=http://127.0.0.1:7700 mix verify.phase5
    """)
  end

  System.put_env("SCRYPATH_INTEGRATION", "1")
end
```

**Secondary analog for curated fast-mode test invocation:** `lib/mix/tasks/verify.phase43.ex`

**Focused fast slice pattern** ([lib/mix/tasks/verify.phase43.ex](/Users/jon/projects/scrypath/lib/mix/tasks/verify.phase43.ex:7), lines 7-25):
```elixir
@focused_tests [
  "test/scrypath/docs_contract_test.exs",
  "test/scrypath/per_query_tuning_test.exs",
  "test/scrypath/search_test.exs",
  "test/scrypath/search_many_test.exs"
]

defp run_test!(args, label) do
  Mix.shell().info("==> Running #{label}")
  Mix.Task.reenable("test")
  Mix.Task.run("test", args)
end
```

**What to copy for `verify.adopter`:**
- `use Mix.Task`, real `@shortdoc`, real `@moduledoc`, and `Mix.Task.run("app.start")`
- `OptionParser.parse(..., strict: [live: :boolean, fast: :boolean])` style parsing if `--fast` is kept
- `Path.expand("examples/phoenix_meilisearch", File.cwd!())` + `System.cmd("bash", ["-lc", script], cd: example_dir, stderr_to_stdout: true)` for `--live`
- `Mix.raise` on missing env or missing example dir; never silently downgrade to fast mode
- `Mix.Task.reenable("test")` / `Mix.Task.run("test", [...])` for the fast docs-contract slice

---

### `mix.exs` (config, request-response)

**Analog:** `mix.exs`

**CLI preferred env registration pattern** ([mix.exs](/Users/jon/projects/scrypath/mix.exs:37), lines 37-67):
```elixir
def cli do
  [
    preferred_envs: [
      "verify.phase41": :test,
      "verify.phase43": :test,
      "verify.opsui": :test,
      "verify.meilisearch_smoke": :test,
      "verify.release_publish": :test,
      "verify.workspace_clean": :test,
      "verify.release_parity": :test,
      ...
    ]
  ]
end
```

**What to copy:**
- Add `"verify.adopter": :test` into the existing `preferred_envs` list
- Keep the registration adjacent to the other `verify.*` tasks; do not invent a separate CLI config shape

---

### `test/scrypath/docs_contract_test.exs` (test, transform)

**Analog:** `test/scrypath/docs_contract_test.exs`

**File-level fixture loading pattern** ([test/scrypath/docs_contract_test.exs](/Users/jon/projects/scrypath/test/scrypath/docs_contract_test.exs:4), lines 4-27):
```elixir
@readme File.read!("README.md")
@contributing File.read!("CONTRIBUTING.md")
@example_readme File.read!("examples/phoenix_meilisearch/README.md")
@support_guide File.read!("guides/support-and-compatibility.md")
@ci_workflow File.read!(".github/workflows/ci.yml")
@verify_phase41 File.read!("lib/mix/tasks/verify.phase41.ex")
@verify_phase43 File.read!("lib/mix/tasks/verify.phase43.ex")
@verify_opsui File.read!("lib/mix/tasks/verify.opsui.ex")
```

**Docs parity assertion pattern** ([test/scrypath/docs_contract_test.exs](/Users/jon/projects/scrypath/test/scrypath/docs_contract_test.exs:370), lines 370-384):
```elixir
test "CONTRIBUTING documents default test path and live integration jobs (VRFY)" do
  assert_contains_all(@contributing, [
    "mix test --exclude integration",
    "**`phase5-verification`**",
    "**`phoenix-example-integration`**",
    "examples/phoenix_meilisearch"
  ])

  assert String.contains?(@contributing, "Service: Meilisearch")
  assert String.contains?(@contributing, "Services: Postgres")
end
```

**CI ordering contract pattern** ([test/scrypath/docs_contract_test.exs](/Users/jon/projects/scrypath/test/scrypath/docs_contract_test.exs:425), lines 425-441):
```elixir
test "CI workflow includes Phoenix example integration job wired to example path" do
  assert_contains_all(@ci_workflow, [
    "phoenix-example-integration:",
    "examples/phoenix_meilisearch",
    "SCRYPATH_EXAMPLE_INTEGRATION",
    "mix deps.get",
    "mix test"
  ])

  [_head, job_tail] = String.split(@ci_workflow, "phoenix-example-integration:", parts: 2)
  job_head = String.slice(job_tail, 0, 4000)
  assert ordered?(job_head, "cd examples/phoenix_meilisearch", "mix deps.get")
  assert ordered?(job_head, "mix deps.get", "mix test")
end
```

**Task marker assertion pattern** ([test/scrypath/docs_contract_test.exs](/Users/jon/projects/scrypath/test/scrypath/docs_contract_test.exs:548), lines 548-552):
```elixir
test "verify.opsui Mix task keeps orchestration markers (Phase 53)" do
  assert String.contains?(@verify_opsui, "cd: ops_dir")
  assert String.contains?(@verify_opsui, "mix test")
  assert String.contains?(@verify_opsui, "ensure_no_args!")
end
```

**What to copy for adopter contracts:**
- Add `@verify_adopter File.read!("lib/mix/tasks/verify.adopter.ex")`
- Keep assertions bounded and string-based, not snapshot-based
- Pin:
  - `README.md` and `CONTRIBUTING.md` mentioning `mix verify.adopter`
  - `verify.adopter` help text mentioning fast vs live and prerequisites
  - `examples/phoenix_meilisearch/README.md` retaining the canonical `cd -> mix deps.get -> mix test` live path
  - `.github/workflows/ci.yml` job(s) using `mix verify.adopter` and `mix verify.adopter --live`

---

### `README.md` (config, transform)

**Analog:** `README.md`

**Maintainer-facing root command pattern** ([README.md](/Users/jon/projects/scrypath/README.md:27), lines 27-30):
```markdown
**Operator UI (maintainers):** ... From the repository root, **`mix verify.opsui`** runs the same checks ...

**Integration smoke (optional):** ... From the clone root, run **`cd examples/phoenix_meilisearch && ./scripts/smoke.sh`**
```

**Adopter wayfinding spine pattern** ([README.md](/Users/jon/projects/scrypath/README.md:17), lines 17-25):
```markdown
**Start here:** ... [guides/golden-path.md](guides/golden-path.md).

**Canonical example proof:** ... [examples/phoenix_meilisearch/README.md](examples/phoenix_meilisearch/README.md).

**Support contract:** ... [guides/support-and-compatibility.md](guides/support-and-compatibility.md).
```

**What to copy:**
- Add one maintainer-facing bullet/paragraph near the existing `mix verify.opsui` / integration-smoke guidance
- Use the same structure: what the command proves, where it runs from, and where CI/job-name details live
- Keep the README at the “entrypoint + wayfinding” level; do not restate the whole example README

---

### `CONTRIBUTING.md` (config, transform)

**Analog:** `CONTRIBUTING.md`

**Verification section pattern** ([CONTRIBUTING.md](/Users/jon/projects/scrypath/CONTRIBUTING.md:18), lines 18-45):
```markdown
## Verification

Use the normal fast suite during development:

```sh
mix test --exclude integration
```

Run the full integration verification (`mix verify.phase5`) when you change ...
```

**CI matrix row pattern** ([CONTRIBUTING.md](/Users/jon/projects/scrypath/CONTRIBUTING.md:62), lines 62-75):
```markdown
| **`phoenix-example-integration`** | Services: Postgres 16 + Meilisearch v1.15. `SCRYPATH_EXAMPLE_INTEGRATION=1`, `PGPORT=5433`, `SCRYPATH_MEILISEARCH_URL=http://127.0.0.1:7700`. **CI** runs **`cd examples/phoenix_meilisearch`**, then **`mix deps.get`**, then **`mix test`** ... |
| **`scrypath-ops-path-check` / `scrypath-ops`** | ... Local contributors should use **`mix verify.opsui`** from the repo root ... |
```

**What to copy:**
- Explain `mix verify.adopter` as the fast default and `mix verify.adopter --live` as the service-backed path
- Keep the job-table style that names the CI job and the exact command sequence
- Preserve the distinction between CI’s canonical live path and `./scripts/smoke.sh` as local DX only

---

### `.github/workflows/ci.yml` (config, batch)

**Analog:** `.github/workflows/ci.yml`

**Existing service-backed example job pattern** ([.github/workflows/ci.yml](/Users/jon/projects/scrypath/.github/workflows/ci.yml:273), lines 273-343):
```yaml
phoenix-example-integration:
  runs-on: ubuntu-latest

  services:
    postgres:
      image: postgres:16-alpine
    meilisearch:
      image: getmeili/meilisearch:v1.15

  env:
    PGPORT: "5433"
    SCRYPATH_MEILISEARCH_URL: http://127.0.0.1:7700
    SCRYPATH_EXAMPLE_INTEGRATION: "1"

  steps:
    ...
    - name: Phoenix example integration (`examples/phoenix_meilisearch`)
      run: |
        cd examples/phoenix_meilisearch
        mix deps.get
        mix test
```

**Existing “root task in CI” pattern** ([.github/workflows/ci.yml](/Users/jon/projects/scrypath/.github/workflows/ci.yml:120), lines 120-124):
```yaml
- name: Federation docs gate (`mix verify.phase41`)
  run: mix verify.phase41

- name: Per-query runtime gate (`mix verify.phase43`)
  run: mix verify.phase43
```

**What to copy:**
- The non-service adopter gate should invoke `mix verify.adopter`
- The service-backed adopter job should invoke `mix verify.adopter --live`
- Keep `services:`, readiness checks, and env setup in GitHub Actions; do not push them into the Mix task
- Preserve explicit `PGPORT`, `SCRYPATH_MEILISEARCH_URL`, and `SCRYPATH_EXAMPLE_INTEGRATION`

---

### `test/mix/tasks/verify_adopter_test.exs` (test, batch)

**Analog 1:** `test/mix/tasks/verify_workspace_clean_test.exs`

**Arg-guard and output capture pattern** ([test/mix/tasks/verify_workspace_clean_test.exs](/Users/jon/projects/scrypath/test/mix/tasks/verify_workspace_clean_test.exs:26), lines 26-47):
```elixir
describe "run/1 arg guard" do
  test "raises Mix.Error when argument is passed" do
    assert_raise Mix.Error, ~r/verify\.workspace_clean does not accept arguments/, fn ->
      Mix.Task.reenable("verify.workspace_clean")
      Mix.Task.run("verify.workspace_clean", ["stray-arg"])
    end
  end
end
```

**Analog 2:** `test/mix/tasks/workflow_wiring_test.exs`

**CLI registration / workflow wiring pattern** ([test/mix/tasks/workflow_wiring_test.exs](/Users/jon/projects/scrypath/test/mix/tasks/workflow_wiring_test.exs:120), lines 120-129):
```elixir
describe "mix.exs cli.preferred_envs registrations" do
  test "verify.workspace_clean is registered as :test" do
    envs = Scrypath.MixProject.cli()[:preferred_envs]
    assert envs[:"verify.workspace_clean"] == :test
  end
end
```

**What to copy if a dedicated task test is needed:**
- `use ExUnit.Case, async: false`
- `Mix.Task.reenable("verify.adopter")` before each invocation
- `assert_raise Mix.Error` for invalid flag combinations or missing live prerequisites
- Keep pure/wiring assertions small; leave docs/help/CI string parity in `docs_contract_test.exs`

## Shared Patterns

### Semantic Root Mix Tasks
**Sources:** [lib/mix/tasks/verify.opsui.ex](/Users/jon/projects/scrypath/lib/mix/tasks/verify.opsui.ex:1), [mix.exs](/Users/jon/projects/scrypath/mix.exs:37)

Apply to `lib/mix/tasks/verify.adopter.ex` and `mix.exs`.

```elixir
defmodule Mix.Tasks.Verify.Opsui do
  use Mix.Task
  @shortdoc "..."
  @moduledoc "..."
end
```

```elixir
preferred_envs: [
  "verify.opsui": :test,
  ...
]
```

### Loud Live-Mode Prerequisites
**Sources:** [lib/mix/tasks/verify.phase5.ex](/Users/jon/projects/scrypath/lib/mix/tasks/verify.phase5.ex:60), [lib/mix/tasks/verify.meilisearch_smoke.ex](/Users/jon/projects/scrypath/lib/mix/tasks/verify.meilisearch_smoke.ex:57)

Apply to `verify.adopter --live`.

```elixir
unless System.get_env("SCRYPATH_MEILISEARCH_URL") do
  Mix.raise("""
  SCRYPATH_MEILISEARCH_URL is required ...
  """)
end
```

### Bounded Docs Contracts
**Source:** [test/scrypath/docs_contract_test.exs](/Users/jon/projects/scrypath/test/scrypath/docs_contract_test.exs:425)

Apply to `README.md`, `CONTRIBUTING.md`, `lib/mix/tasks/verify.adopter.ex`, `.github/workflows/ci.yml`, and the example README contract.

```elixir
assert ordered?(job_head, "cd examples/phoenix_meilisearch", "mix deps.get")
assert ordered?(job_head, "mix deps.get", "mix test")
```

### CI Owns Services; Mix Owns Orchestration
**Sources:** [.github/workflows/ci.yml](/Users/jon/projects/scrypath/.github/workflows/ci.yml:276), [lib/mix/tasks/verify.opsui.ex](/Users/jon/projects/scrypath/lib/mix/tasks/verify.opsui.ex:37)

Apply to `.github/workflows/ci.yml` and `lib/mix/tasks/verify.adopter.ex`.

```yaml
services:
  postgres:
  meilisearch:
env:
  PGPORT: "5433"
  SCRYPATH_MEILISEARCH_URL: http://127.0.0.1:7700
```

```elixir
Mix.shell().info("==> verify.opsui: cd scrypath_ops && mix deps.get && mix test")
{out, status} = System.cmd("bash", ["-lc", script], cd: ops_dir, stderr_to_stdout: true)
```

## No Analog Found

None. Every planned file has a close repo-local pattern already.

## Metadata

**Analog search scope:** `lib/mix/tasks/`, `test/scrypath/`, `test/mix/tasks/`, repo root docs, `guides/`, `examples/phoenix_meilisearch/`, `.github/workflows/`

**Files scanned:** 14

**Pattern extraction date:** 2026-04-22
