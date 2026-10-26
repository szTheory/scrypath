# Phase 181: Schema hook contract and no-Oban build - Pattern Map

**Mapped:** 2026-10-26
**Files analyzed:** 11 (6 source/docs modified, 1 test created, 4 tests extended)
**Analogs found:** 11 / 11 (all git-tracked; verified with `git ls-files`)

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/scrypath/schema.ex` (callbacks, `@optional_callbacks`, `__before_compile__`, `__using__` injection) | public API / compile-time macro | transform (compile time) | `lib/scrypath/backend.ex` (callbacks + `@optional_callbacks` + `@doc` on a callback); `lib/scrypath/options.ex:736` (`IO.warn`) | role-match (no `@before_compile` exists in lib/) |
| `lib/scrypath/sync/related_enqueue.ex` (drop `if Code.ensure_loaded?` split) | service | request-response (job build + enqueue) | `lib/scrypath/oban/enqueue.ex:58-87` (`upsert_job_changeset/4` → `job_changeset/4`) | exact |
| `lib/scrypath/oban/enqueue.ex` (promote `job_changeset/4` to `@doc false def`) | service | request-response | same file: `unique_opts/0` (l.89-109), `enqueue_chunks/3` (l.111-122) | exact |
| `lib/mix/tasks/verify.no_optional_deps.ex` (isolated `MIX_BUILD_PATH`, prod env, absence guard, pure seam fns) | mix task | batch / file-I/O (subprocess compile) | itself (l.1-43) + `lib/mix/tasks/verify.workspace_clean.ex:80-90` (public pure seam `build_pathspecs/0`) | exact |
| `lib/mix/tasks/verify/capability.ex` (`run(:core, …)` composes `verify.no_optional_deps`, injectable runner) | mix task orchestrator | batch | same file: `backend!/1` (l.49-60) and `run_deep_quality_sequence/2` (l.87-96) | exact |
| `test/scrypath/schema_test.exs` (extend) | test | — | same file, `Code.compile_string` tests (l.34-43, 96-109) | exact |
| `test/mix/tasks/verify_capability_test.exs` (extend: core sequence) | test | — | same file, `assert_deep_quality_sequence/2` (l.71-103) | exact |
| `test/mix/tasks/verify_no_optional_deps_test.exs` (NEW, Wave 0) | test | file-I/O | `test/mix/tasks/verify_workspace_clean_test.exs:1-37` + `test/mix/tasks/dependency_audit_test.exs:432-447` (tmp fixture dir) | role-match |
| `test/mix/tasks/workflow_wiring_test.exs` (extend: no-blanket-suppression contract) | test (source contract) | file-I/O | same file l.1-16, 179-190 (`File.read!` + `refute =~`) | exact |
| `test/scrypath/sync/related_test.exs` (existing; regression guard, no edit expected) | test | — | itself l.138-178 | exact |
| `CONTRIBUTING.md` (core row l.32, quality-baseline block l.49-54), `.planning/PROJECT.md` (l.528, l.530 checkboxes) | docs | — | n/a (text edits) | — |

## Pattern Assignments

### `lib/scrypath/schema.ex` (public API / compile-time macro)

**Analog A — callback declaration style:** `lib/scrypath/backend.ex` lines 12-35

```elixir
  @callback name() :: atom()
  ...
  @doc """
  Optional federated multi-search over multiple schemas in one HTTP round-trip.
  ...
  """
  @callback search_many([{module(), Query.t(), keyword()}], keyword()) ::
              {:ok, map()} | {:error, term()}

  @optional_callbacks [search_many: 2]
```
Copy: a `@doc """..."""` heredoc directly above each `@callback` (RESEARCH requires non-`:none` docs), then a single `@optional_callbacks [search_document: 1, search_document_id: 1, search_records: 2]` (Backend uses the bracketed list form — keep it consistent). Callback typespecs come from RESEARCH Pattern 1 (lines 112-119).

**Analog B — injection point:** `lib/scrypath/schema.ex` lines 28-34 (current)

```elixir
  defmacro __using__(opts) do
    opts = expand_schema_option_aliases(opts, __CALLER__)
    config = Options.validate_schema_options!(opts)

    quote bind_quoted: [config: Macro.escape(config)] do
      Module.register_attribute(__MODULE__, :scrypath_config, persist: true)
      @scrypath_config config
```
Insert `@behaviour Scrypath.Schema` and `@before_compile Scrypath.Schema` as the first two lines inside the `quote` (before `Module.register_attribute`). Place the callbacks + `@hooks` module attribute + `__before_compile__/1` after `alias Scrypath.Options` (l.26) and before `defmacro __using__`; keep private helpers (l.55-92) at the bottom.

**Analog C — warning emission:** `lib/scrypath/options.ex` lines 735-739

```elixir
      IO.warn(
        "[scrypath] tenant_field #{inspect(field)} is not listed in fields:. It has been auto-added ...",
        []
      )
```
Copy the `"[scrypath] "` message prefix convention, but pass `env` (or `file: env.file, line: line` from `Module.get_definition/2` meta) instead of `[]` so the diagnostic is located (RESEARCH Pattern 1, lines 124-137 for the body). `IO.warn`, not `raise`.

**Moduledoc:** extend the existing `@moduledoc` (l.2-24): add a "Hooks" section listing the three optional callbacks with `c:search_records/2` style links, and the Pitfall 5 note ("If your schema uses `@impl`, mark hooks `@impl Scrypath.Schema`"). Note l.23 "The macro does not generate runtime APIs" stays true.

---

### `lib/scrypath/sync/related_enqueue.ex` (service, job build)

**Analog:** `lib/scrypath/oban/enqueue.ex` lines 58-72 (main path already uses the runtime-guarded builder)

```elixir
  def upsert_job_changeset(schema_module, document_ids, config, job_opts \\ [])
      when is_list(document_ids) do
    ...
    payload = Payload.build_upsert(schema_module, document_ids, config)

    job_changeset(payload, @upsert_worker, config, job_opts)
  end
```

**Current code to replace** (`related_enqueue.ex` l.1-2, 35-50, 77-86):
```elixir
if Code.ensure_loaded?(Oban.Job) do
  defmodule Scrypath.Sync.RelatedEnqueue do
  ...
          queue = to_string(Config.oban_queue(config))
          max_attempts = Config.oban_max_attempts(config)
          ...
          |> Enum.map(fn chunk ->
            Oban.Job.new(job_args(schema_module, chunk, fan_out_key, config),
              worker: @worker,
              queue: queue,
              max_attempts: max_attempts,
              unique: Enqueue.unique_opts()
            )
          end)
          |> Enqueue.enqueue_chunks(config, %{})
...
else
  defmodule Scrypath.Sync.RelatedEnqueue do ... raise ArgumentError, "Oban dependency is required ..." end
end
```
Target: one unconditional `defmodule` (dedent one level), keep `@moduledoc false`, `@worker`, `@spec enqueue/4`, `Enqueue.ensure_durable_api_key!/1`, `Loader.ensure_loadable!/2`, the `[]` noop branch, and `job_args/4` verbatim. Replace the `Enum.map` body with
`&Enqueue.job_changeset(job_args(schema_module, &1, fan_out_key, config), @worker, config, [])`. Remove now-unused `queue`/`max_attempts` locals and the `Config` alias if unused (Credo strict). Do not add `@compile {:no_warn_undefined, ...}` here — no direct `Oban.*` reference remains.

---

### `lib/scrypath/oban/enqueue.ex` (service)

**Analog:** same file, sibling `@doc false` public helpers, lines 89-122

```elixir
  @doc false
  # The unique policy shared by every Scrypath sync job (upsert, delete, related).
  ...
  @spec unique_opts() :: keyword()
  def unique_opts, do: [period: :infinity, states: [:available, :scheduled, :retryable]]

  @doc false
  # Inserts one job per changeset ...
  @spec enqueue_chunks([Changeset.t()], keyword(), map()) ::
          {:ok, Result.t()} | {:error, term()}
  def enqueue_chunks(changesets, config, metadata_extra)
```
Promote `defp job_changeset(payload, worker, config, job_opts)` (l.224-236) to `@doc false` + comment + `@spec job_changeset(map(), String.t(), keyword(), keyword()) :: Changeset.t()` + `def`. Body unchanged; it already guards via `oban_job_module!/0` (l.251-258):
```elixir
  defp oban_job_module! do
    if Code.ensure_loaded?(Oban.Job) do
      Oban.Job
    else
      raise ArgumentError,
            "Oban dependency is required for sync_mode :oban. Add {:oban, \"~> 2.21\", optional: true} to your deps."
    end
  end
```
Optionally move the promoted function up near `unique_opts/0` so public helpers are grouped. Keep `@compile {:no_warn_undefined, [Oban, Oban.Job, Oban.Repo]}` (l.3) as is.

---

### `lib/mix/tasks/verify.no_optional_deps.ex` (mix task, subprocess compile)

**Analog (self), current lines 9-31:**
```elixir
  @impl true
  def run(args) do
    ensure_no_args!(args)

    Mix.shell().info("==> Compiling Scrypath without optional dependencies (warnings are errors)")
    ...
    {output, status} =
      System.cmd(
        mix_executable!(),
        ["compile", "--force", "--no-optional-deps", "--warnings-as-errors"],
        env: [{"MIX_ENV", Atom.to_string(Mix.env())}],
        stderr_to_stdout: true
      )

    Mix.shell().info(output)

    if status != 0 do
      Mix.raise("root compile without optional dependencies failed")
    end
  end
```
Keep: `ensure_no_args!/1`, `mix_executable!/0`, the `==> Compiling Scrypath without optional dependencies` info line (hosted-evidence string in RESEARCH validation map), `Mix.raise` on non-zero. Change: env to `[{"MIX_ENV", "prod"}, {"MIX_BUILD_PATH", build_path}]`; defensive `File.rm_rf!` of optional dep dirs under `build_path` before compile; post-compile absence guard (RESEARCH Pattern 2, lines 157-169).

**Testability seam analog:** `lib/mix/tasks/verify.workspace_clean.ex` lines 79-87
```elixir
  @doc """
  Returns the pathspec list used by `run/1` — derived from
  `mix.exs` `package.files` plus `"test"`.

  Exposed publicly for testability.
  """
  @spec build_pathspecs() :: [String.t()]
  def build_pathspecs do
    project = Mix.Project.config()
```
Expose pure public functions, e.g. `isolated_build_path/0`, `compile_env/1` (returns the env list), `optional_deps/0` (from `Mix.Project.config()[:deps]`), and `assert_optional_deps_absent!(build_path)` (raises `Mix.Error` when `<build>/lib/<optional dep>` or `<build>/lib/scrypath/ebin/Elixir.Scrypath.Oban.UpsertWorker.beam` exists). Unit tests call these without spawning a compile.

---

### `lib/mix/tasks/verify/capability.ex` (orchestrator)

**Analog 1 — composition (Phase 178 `verify.postgres` into backend), lines 49-60:**
```elixir
  defp backend!(args) do
    ...
    run_task!("verify.meilisearch_smoke", task_args)
    run_task!("verify.postgres", task_args)
  end
```
**Analog 2 — injectable runner, lines 31-35 and 87-96:**
```elixir
  @doc false
  @spec run_deep_quality_without_audit() :: :ok
  @spec run_deep_quality_without_audit(keyword()) :: :ok
  def run_deep_quality_without_audit(opts \\ []),
    do: run_deep_quality_sequence(false, opts)
  ...
  defp run_deep_quality_sequence(include_audit?, opts) do
    task_runner = Keyword.get(opts, :task_runner, &run_deep_quality_task!/2)
    ...
    task_runner.("verify.no_optional_deps", [])
```
Target: `def run(:core, args), do: run_core(args)` plus `@doc false def run_core(args, opts \\ [])` with `task_runner = Keyword.get(opts, :task_runner, &run_task!/2)`, calling `task_runner.("verify", args)` then `task_runner.("verify.no_optional_deps", [])`, returning `:ok`. Leave `run_deep_quality_sequence/2` unchanged (its sequence is pinned at test l.71-86). `run_task!/2` (l.138-143) already does `Mix.Task.reenable` + info line.

Note: `lib/mix/tasks/verify/core.ex` (l.6 `def run(args), do: Mix.Tasks.Verify.Capability.run(:core, args)`) needs no change.

---

### `test/scrypath/schema_test.exs` (extend)

**Analog:** same file lines 34-43 (compile-string fixture) and 96-109 (assert on compile failure)
```elixir
    test "reflects tenant_field if declared" do
      [{mod, _}] =
        Code.compile_string("""
        defmodule TenantFieldSchemaTest do
          use Scrypath, fields: [:title], tenant_field: :account_id
        end
        """)
```
Add a new `describe "hook contract"` block. Wrap `Code.compile_string` in `Code.with_diagnostics/1` (RESEARCH Code Examples, lines 304-332). Use unique fixture module names (`Scrypath.SchemaHookArityFixture`, `...OkFixture`, `...DefpFixture`, `...HelperArityFixture` for the "extra arity alongside correct one stays silent" case). Contract/docs assertions per RESEARCH lines 337-346 (`behaviour_info(:optional_callbacks)`, `SearchablePost.module_info(:attributes)` `:behaviour`, `Code.fetch_docs` callback docs non-empty). File is `async: true`; keep it that way (compile_string with distinct module names is safe).

---

### `test/mix/tasks/verify_capability_test.exs` (extend)

**Analog:** same file lines 88-103
```elixir
  defp assert_deep_quality_sequence(run, expected) do
    calls_key = {__MODULE__, make_ref()}

    task_runner = fn task, args ->
      Process.put(calls_key, Process.get(calls_key, []) ++ [{:task, task, args}])
      :ok
    end
    ...
    assert :ok = run.(task_runner: task_runner, command_runner: command_runner)
    assert Process.get(calls_key) == expected
  end
```
Add test "core runs the root gate then the no-optional-deps build" calling `Mix.Tasks.Verify.Capability.run_core(["--exclude", "integration"], task_runner: ...)` and asserting `[{:task, "verify", ["--exclude", "integration"]}, {:task, "verify.no_optional_deps", []}]`. Reuse the Process-dictionary recorder (factor a small `recording_runner/1` helper or pass a dummy `command_runner` and reuse the existing helper).

---

### `test/mix/tasks/verify_no_optional_deps_test.exs` (NEW)

**Analog 1 — module shape / arg guard:** `test/mix/tasks/verify_workspace_clean_test.exs` lines 1-37
```elixir
defmodule Mix.Tasks.Verify.WorkspaceCleanTest do
  use ExUnit.Case, async: false
  ...
  describe "run/1 arg guard" do
    test "raises Mix.Error when argument is passed" do
      assert_raise Mix.Error, ~r/verify\.workspace_clean does not accept arguments/, fn ->
        Mix.Task.reenable("verify.workspace_clean")
        Mix.Task.run("verify.workspace_clean", ["stray-arg"])
      end
    end
  end
```
**Analog 2 — temp fixture dir:** `test/mix/tasks/dependency_audit_test.exs` lines 432-447
```elixir
  defp fixture_repo do
    root =
      Path.join(
        System.tmp_dir!(),
        "scrypath-dependency-audit-test-#{System.unique_integer([:positive, :monotonic])}"
      )
    ...
    on_exit(fn -> File.rm_rf!(root) end)
    root
  end
```
Tests: (a) fake build dir with `lib/oban/` → `assert_raise Mix.Error` from the absence guard; (b) fake build dir with `lib/scrypath/ebin/Elixir.Scrypath.Oban.UpsertWorker.beam` → raises; (c) clean fake dir → `:ok`; (d) compile env contains `{"MIX_BUILD_PATH", path}` and `{"MIX_ENV", "prod"}`, and isolated path differs from `Mix.Project.build_path()`; (e) arg guard. `async: true` is fine if no global shell/env mutation; otherwise `async: false` like the analog.

---

### `test/mix/tasks/workflow_wiring_test.exs` (extend, source contract)

**Analog:** same file lines 179-190
```elixir
      mix_exs = File.read!("mix.exs")

      refute mix_exs =~ "\"verify.phase100\": :test",
             "verify.phase100 must remain unregistered; phase100 trust checks run in verify.phase99"
```
Add a `describe "HYG-02 no blanket compiler suppression"`: `refute File.read!("mix.exs") =~ "elixirc_options"`; scan `Path.wildcard("lib/**/*.ex")` and refute `Code.put_compiler_option`; for every `@compile {:no_warn_undefined, ...}` match, assert named modules all start with `Oban` (current sites: `lib/scrypath/oban.ex:16`, `lib/scrypath/oban/inspect.ex:3`, `lib/scrypath/oban/enqueue.ex:3`). Optionally also assert `File.read!("lib/mix/tasks/verify/capability.ex") =~ ~s|"verify.no_optional_deps"|` in core context — the sequence test is the stronger guard.

---

### `test/scrypath/sync/related_test.exs` (regression guard — no edit expected)

Lines 138-178 already pin the related-job shape the refactor must preserve: worker `"Scrypath.Sync.RelatedWorker"`, ≤1000 sorted ids per chunk, `unique[:states] == [:available, :scheduled, :retryable]`, `unique[:period] == :infinity`, and queue `"test_queue"` (l.304-306). Run alongside `test/scrypath/oban/enqueue_unique_test.exs` (real Oban Lite) and `test/scrypath/sync/related_worker_test.exs`.

## Shared Patterns

### Mix task argument guard + failure
**Source:** `lib/mix/tasks/verify.no_optional_deps.ex:33-42`, `lib/mix/tasks/verify/capability.ex:43-47`
```elixir
  defp ensure_no_args!([]), do: :ok

  defp ensure_no_args!(args) do
    Mix.raise("verify.no_optional_deps does not accept arguments, got: #{Enum.join(args, " ")}")
  end
```
**Apply to:** all mix-task edits. Failures use `Mix.raise/1`; progress uses `Mix.shell().info("==> ...")`.

### Injectable runner for sequence tests
**Source:** `lib/mix/tasks/verify/capability.ex:87-96` + `test/mix/tasks/verify_capability_test.exs:88-103`
**Apply to:** the new `run(:core, …)` composition.

### Runtime-guarded optional dependency (no compile-time `if Code.ensure_loaded?` module split)
**Source:** `lib/scrypath/oban/enqueue.ex:3` (`@compile {:no_warn_undefined, [Oban, Oban.Job, Oban.Repo]}`) + `oban_job_module!/0` (l.251-258)
**Apply to:** `related_enqueue.ex`. Never silence via `apply/3`, `elixirc_options`, or `Code.put_compiler_option` (RESEARCH Anti-Patterns).

### `@doc false` public internals with `@spec`
**Source:** `lib/scrypath/oban/enqueue.ex:89-122`, `lib/mix/tasks/verify/capability.ex:31-41`
**Apply to:** promoted `Enqueue.job_changeset/4`, `Capability.run_core/2`, no_optional_deps seam fns (or public `@doc` like workspace_clean if it should appear in `mix help`).

### Compile-time diagnostics in tests
**Source:** `test/scrypath/schema_test.exs:34-43` (`Code.compile_string`) + RESEARCH Code Examples (`Code.with_diagnostics/1`)
**Apply to:** all hook-contract tests. No stderr regex / `capture_io`.

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `Scrypath.Schema.__before_compile__/1` (inside `lib/scrypath/schema.ex`) | compile-time macro | transform | No `@before_compile`/`Module.definitions_in` usage exists in `lib/`. Use RESEARCH Pattern 1 prototype (lines 121-137); verified on 1.17.3 and 1.19.0 |
| `MIX_BUILD_PATH` isolation in `verify.no_optional_deps` | mix task | file-I/O | No existing task sets `MIX_BUILD_PATH`. Use RESEARCH Pattern 2 (lines 157-169) |

## Notes for Planner

- Adopter-impact check (RESEARCH A4): grep `@impl` in `examples/scrypath_ecommerce/lib/scrypath_ecommerce/catalog/{product,variant,category}.ex` and `scrypath_ops/test/support/ops_schemas.ex` before landing the `@behaviour` injection.
- Docs targets: `CONTRIBUTING.md:32` (core row → mention no-optional-deps compile), `CONTRIBUTING.md:49-54` (no_optional_deps description), `CONTRIBUTING.md:220` (CI `core` job row); `.planning/PROJECT.md:528` and `:530` checkboxes.
- `ci.yml` stays untouched; `workflow_wiring_test.exs:12-15` and `docs_contract_test.exs` CI pins need no change.
- Shell needs `ASDF_ELIXIR_VERSION=1.19.0-otp-28 ASDF_ERLANG_VERSION=28.1` prefix (RESEARCH Pitfall 6).

## Metadata

**Analog search scope:** `lib/scrypath/`, `lib/mix/tasks/`, `test/scrypath/`, `test/mix/tasks/`, `CONTRIBUTING.md`, `.planning/PROJECT.md`
**Files scanned:** ~20
**Pattern extraction date:** 2026-10-26
