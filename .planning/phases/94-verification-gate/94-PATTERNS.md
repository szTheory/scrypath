# Phase 94: Verification Gate - Pattern Map

**Mapped:** 2024-05-26
**Files analyzed:** 4
**Analogs found:** 4 / 4

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/mix/tasks/verify.phase94.ex` | mix task | hermetic test execution | `lib/mix/tasks/verify.phase91.ex` | exact |
| `mix.exs` | config | configuration | `mix.exs` (existing aliases) | exact |
| `.github/workflows/ci.yml` | CI config | CI pipeline | `.github/workflows/ci.yml` (Phase 91 step) | exact |
| `CONTRIBUTING.md` | documentation | contributor guidance | `CONTRIBUTING.md` (Phase 82/43/41 blocks) | exact |

## Pattern Assignments

### `lib/mix/tasks/verify.phase94.ex` (mix task, hermetic test execution)

**Analog:** `lib/mix/tasks/verify.phase91.ex`

**Imports pattern** (lines 1-7):
```elixir
defmodule Mix.Tasks.Verify.Phase94 do
  @moduledoc false
  use Mix.Task

  @shortdoc "Runs focused tenant-safety and multitenancy verification (Phase 94)"
```

**Core execution pattern** (lines 13-20):
```elixir
  @impl true
  def run(args) do
    Mix.Task.run("app.start")
    ensure_no_args!(args)

    run_test!(@focused_tests, "Phase 94 tenant-safety verification")

    Mix.shell().info("==> Building docs with warnings as errors")
    Mix.Task.reenable("docs")
    Mix.Task.run("docs", ["--warnings-as-errors"])
  end
```

**Helper pattern** (lines 22-31):
```elixir
  defp run_test!(args, label) do
    Mix.shell().info("==> Running #{label}")
    Mix.Task.reenable("test")
    Mix.Task.run("test", args)
  end

  defp ensure_no_args!([]), do: :ok

  defp ensure_no_args!(args) do
    Mix.raise("verify.phase94 does not accept arguments, got: #{Enum.join(args, " ")}")
  end
end
```

---

### `mix.exs` (config, configuration)

**Analog:** Existing `verify.phase*` entries in `mix.exs`

**Core Pattern** (lines 59-60):
```elixir
        "verify.phase91": :test,
        "verify.phase94": :test,
```
Add the new alias under `preferred_envs:` in `def cli do`.

---

### `.github/workflows/ci.yml` (CI config, CI pipeline)

**Analog:** Existing Phase 91 registration in `ci.yml`

**Core Pattern** (lines 140-141):
```yaml
      - name: Tenant-safety + docs-contract gate (`mix verify.phase94`)
        run: mix verify.phase94
```
Add as a step within the `quality` job in the workflow.

---

### `CONTRIBUTING.md` (documentation, contributor guidance)

**Analog:** Phase 82 and Phase 43 documentation blocks

**Core Pattern** (approx lines 77-80):
```markdown
The Phase 94 verify alias is the focused gate for the tenant-safety and multitenancy contracts. Run the shell command **mix verify.phase94** when you change `tenant_field:` auto-merge behavior, `schema_capabilities/1` `:tenant` reflection, `tenant_scope:` injection, or the canonical `guides/multitenancy.md` guide anchors. It stays narrower than the default fast suite and mirrors the same check CI runs in the **`quality`** job.
```

## Shared Patterns

### Focused Testing List
**Source:** `lib/mix/tasks/verify.phase91.ex`
**Apply to:** `verify.phase94.ex`
**Pattern:**
```elixir
  @focused_tests [
    "test/scrypath/schema_test.exs",
    "test/scrypath/metadata_test.exs",
    "test/scrypath/options_test.exs",
    "test/scrypath/projection_test.exs",
    "test/scrypath/docs_contract_test.exs"
  ]
```
These are the files that contain `tenant_field`, `schema_capabilities`, and related tenant tests.

## Metadata

**Analog search scope:** `lib/mix/tasks/`, `mix.exs`, `.github/workflows/ci.yml`, `CONTRIBUTING.md`
**Files scanned:** 12
**Pattern extraction date:** 2024-05-26