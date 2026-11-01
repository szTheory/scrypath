# Phase 183: Maintainer tooling outside the Hex package - Pattern Map

**Mapped:** 2026-10-27
**Files analyzed:** 24 distinct file groups (3 new source files, 1 renamed test, 53 moved task files treated as one group, 14 path-coupled tests treated as one group, 11 modified config/test/doc files plus the 4 doc files)
**Analogs found:** 22 / 24 (2 have only a partial analog; see "No Analog Found")

All analog paths below were checked with `git ls-files` and are git-tracked. No gitignored mirror paths are named. Line numbers refer to the working tree on branch `planning/v1.45-foundation-ci` before any phase 183 edit.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `test/support/repo_tooling.ex` (new, `Scrypath.RepoTooling`) | utility (test support) | file-I/O (read source text) | `test/support/telemetry_contract.ex` (`@moduledoc false` pure helper) | role-match |
| `test/support/release/package_contract.ex` (new, `Scrypath.Release.PackageContract`) | utility (pure checker + thin runner) | transform (dir to violations) | `lib/mix/tasks/verify.release_parity.ex` `compute/2`; `lib/mix/tasks/verify.workspace_clean.ex` `classify/3` | exact (pattern) |
| `test/release/package_contents_test.exs` (new) | test (integration + mutation) | batch (build archive, check) | `test/release/consumer_smoke_test.exs` | exact |
| `dev/mix/tasks/**` (53 files moved, `git mv`) | task (Mix.Task) | request-response | the files themselves in `lib/mix/tasks/` | exact (move) |
| `dev/mix/tasks/verify.namespace_fence.ex` (rename of `lib/mix/tasks/scrypath.namespace_fence.ex`) | task | request-response | `lib/mix/tasks/scrypath.namespace_fence.ex` | exact (move + name edit) |
| `test/mix/tasks/verify_namespace_fence_test.exs` (rename of `test/mix/tasks/scrypath/namespace_fence_test.exs`) | test | transform | `test/mix/tasks/scrypath/namespace_fence_test.exs` | exact (move + name edit) |
| `mix.exs` (modify) | config | n/a | `scrypath_ops/mix.exs` lines 9, 35-36 | exact |
| D-04 guard test (new `describe`, in `package_contents_test.exs` or `verify_capability_test.exs`) | test | transform | `test/mix/tasks/verify_capability_test.exs` lines 76-82; `test/mix/tasks/dependency_audit_test.exs` lines 429-431 | exact |
| `test/release/consumer_smoke_test.exs` (extend, L2) | test (integration) | batch | itself (lines 6-71, 140-196) | exact |
| `test/release/package_metadata_test.exs` (add `refute "dev"`) | test | transform | itself, lines 35-52 | exact |
| `dev/mix/tasks/verify.phase11.ex` (add test path) + `test/scrypath/docs_contract_test.exs` pin | task + test | request-response | `verify.phase11.ex` lines 25-35; `docs_contract_test.exs` lines 946-955 | exact |
| `dev/mix/tasks/verify/capability.ex` (rename call sites) + `test/mix/tasks/verify_capability_test.exs` lines 88, 97 | task + test | request-response | itself | exact |
| `dev/mix/tasks/verify.workspace_clean.ex` pathspecs + `test/mix/tasks/verify_workspace_clean_test.exs` | task + test | transform | itself, lines 85-97 and 9-30 | exact |
| 14 path-coupled test files (convert to `Scrypath.RepoTooling`) | test | file-I/O | each file's own `File.read!("lib/mix/tasks/...")` site | exact |
| `test/mix/tasks/workflow_wiring_test.exs` (HYG-02 scans + `@verify_task`) | test | file-I/O | itself, lines 8, 16-35 | exact |
| `.formatter.exs`, `.credo.exs` | config | n/a | themselves | exact |
| `scripts/ci/beam_cache.cjs` (4 `sourceRoots`) + `scripts/ci/beam_cache.test.cjs` fixture | config + test | transform | themselves, lines 18/24/30/36 and 180-240 | exact |
| `.github/workflows/ci.yml` line 359 | config (CI) | event-driven | itself | exact |
| `CODEOWNERS` (optional) | config | n/a | itself (1 line) | exact |
| `CONTRIBUTING.md`, `README.md`, `guides/support-and-compatibility.md`, `guides/outside-adopter-intake.md` (+ optional `docs/releasing.md`) | docs | n/a | themselves | exact |

## Pattern Assignments

### `mix.exs` (config)

**Analog:** `scrypath_ops/mix.exs` (same repo, same shape; the research prototype matches it)

**Env-keyed `elixirc_paths`** (`scrypath_ops/mix.exs` lines 9, 35-36):
```elixir
      elixirc_paths: elixirc_paths(Mix.env()),
...
  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
```
Phase 183 form (D-05): `defp elixirc_paths(:test), do: ["lib", "dev/mix/tasks"]` and `defp elixirc_paths(_), do: ["lib"]`. Insert `elixirc_paths: elixirc_paths(Mix.env()),` in `project/0` of the root `mix.exs` between `start_permanent:` (line 15) and `deps:` (line 16). Keep it `defp` (research F7: a test can read only the current env's value through `Scrypath.MixProject.project()[:elixirc_paths]`). No `File.dir?` guard.

**`preferred_envs`** (`mix.exs` lines 45-105): keyword list, one `"verify.xxx": :test` entry per task. Add `"verify.namespace_fence": :test,` next to `"verify.workspace_clean": :test` (line 84) and keep the existing `"scrypath.index.contract_drift"` / `scrypath.settings.*` entries at lines 98-101 untouched.

**Do not change** `docs/0` (lines 183-267) or `package/0` `files:` (line 274-275). Research F1 overturned the D-07 `filter_modules`; the planner should leave `docs/0` alone.

---

### `test/support/repo_tooling.ex` (utility, file-I/O)

**Analog:** `test/support/telemetry_contract.ex` (lines 1-12 show the `@moduledoc false` + comment-explains-contract shape) and `test/support/fake_repo.ex` (smallest support module).

**Module-doc convention** (`test/support/fake_repo.ex` lines 1-4):
```elixir
defmodule Scrypath.TestSupport.FakeRepo do
  @moduledoc false

  # Oban job args name the repo; workers only accept a module that looks like an Ecto repo.
```
Naming note: every other support module is `Scrypath.TestSupport.*`. CONTEXT D-14 locks the names `Scrypath.RepoTooling` and `Scrypath.Release.PackageContract`, so use those; do not rename them to `TestSupport`.

**Load order** (`test/test_helper.exs` lines 21-24): support files are loaded with `Code.require_file/1` right after `ExUnit.start()`, before test files compile, so `@attr Scrypath.RepoTooling.task_source!(...)` works at compile time inside test modules:
```elixir
ExUnit.start()

"test/support/**/*.ex"
|> Path.wildcard()
|> Enum.each(&Code.require_file/1)
```
`mix.exs` line 27 and 179-181 (`test_ignore_filters: [&support_file?/1]`) keeps `test/support/**` out of test discovery; nested `test/support/release/` needs no config change.

**Body to copy** (RESEARCH Pattern 4; one root constant so step 3 of D-16 is a one-line flip):
```elixir
defmodule Scrypath.RepoTooling do
  @moduledoc false
  @tasks_root "lib/mix/tasks"   # step 1 of D-16; flip to "dev/mix/tasks" in step 3

  def tasks_root, do: @tasks_root
  def task_path(relative), do: Path.join(@tasks_root, relative)
  def task_source!(relative), do: relative |> task_path() |> File.read!()
end
```

---

### `test/support/release/package_contract.ex` (utility, transform)

**Analog 1:** `lib/mix/tasks/verify.release_parity.ex` pure `compute/2` plus thin `run/1` (lines 80-99; moduledoc rationale lines 33-36).

**Pure function pattern to mirror** (lines 80-99):
```elixir
  @spec compute(MapSet.t(String.t()), MapSet.t(String.t())) ::
          :parity | {:drift, [String.t()], [String.t()]}
  def compute(%MapSet{} = git_paths, %MapSet{} = hex_paths) do
    only_in_git =
      git_paths |> MapSet.difference(hex_paths) |> MapSet.to_list() |> Enum.sort()
    ...
    case {only_in_git, only_in_hex} do
      {[], []} -> :parity
      {og, oh} -> {:drift, og, oh}
    end
  end
```

**Analog 2:** `lib/mix/tasks/verify.workspace_clean.ex` `classify/3` (lines 53-77): pure classifier returning tagged tuples, with a `@spec` and a docstring explaining it is split out for testability without a real subprocess:
```elixir
  @spec classify(String.t(), integer(), non_neg_integer()) ::
          {:ok, String.t()} | {:dirty, String.t()} | {:git_error, String.t()}
  def classify("", 0, pathspec_count) do
    {:ok, "Workspace clean across #{pathspec_count} pathspecs"}
  end
```

**Body to copy:** RESEARCH.md "Pattern 2" (lines 343-411 of 183-RESEARCH.md) is a prototype that passed the control plus all five D-11 mutations. It defines `@public_tasks`, `@allowed_top_level`, `check/1` (thin I/O), `classify/2` (pure), `collect_task_modules/1` (AST via `Code.string_to_quoted!/1` and a nested-aware `modules/2` walk) and returns `:ok | {:error, [sorted_lines]}`. Use `Mix.Task.task_name/1` for name mapping (do not hand-roll).

**Analog 3 (AST parse-then-walk shape, partial):** `test/mix/tasks/workflow_wiring_test.exs` lines 881-896 parses source with `Code.string_to_quoted!/1` and walks it with `Macro.prewalk/3`; this is the repo's only in-repo AST scan, and its positive/negative in-memory fixtures (lines 37-65) are the model for testing `collect_task_modules/1` without touching files:
```elixir
  defp assert_oban_suppressions!(source, path) do
    {_ast, {sites, tokens}} =
      source
      |> Code.string_to_quoted!()
      |> Macro.prewalk({[], 0}, fn
        {:no_warn_undefined, target} = node, {sites, tokens} ->
          {node, {[target | sites], tokens}}
```

**Deviation from the analogs, deliberate:** `compute/2` returns `:parity | {:drift, ...}`; the new checker returns `:ok | {:error, [String.t()]}` (sorted lines, tag + task + module + path + `fix:` hint). Keep the per-line shape `[unexpected-task] name Module path fix: ...`, `[missing-task] name fix: ...`, `[forbidden-path] entry fix: ...`.

**Two drift-guard unit tests to add alongside** (RESEARCH lines 413 and 616): (a) `@allowed_top_level` minus `hex_metadata.config` equals the set of first path segments of `Scrypath.MixProject.project()[:package][:files]` (today these first segments are `lib .formatter.exs mix.exs README.md CONTRIBUTING.md ARCHITECTURE.md CHANGELOG.md LICENSE SECURITY.md guides docs`; note `docs/...` entries are individual files, so the segment is `docs`); (b) `@public_tasks` equals the task names derived from the repo's own `lib/mix/tasks` tree. Optionally also assert each public task name appears in at least one packaged guide (`guides/operator-mix-tasks.md` documents 7 by heading; `scrypath.settings.read` is documented at `guides/relevance-tuning.md:73`).

---

### `test/release/package_contents_test.exs` (test, batch; new)

**Analog:** `test/release/consumer_smoke_test.exs` (same dir, same job: run a real `mix hex.build --unpack` and inspect the result).

**Imports/setup pattern** (lines 1-4):
```elixir
defmodule Scrypath.Release.ConsumerSmokeTest do
  use ExUnit.Case, async: false

  alias Scrypath.MixProject
```
Use `async: false` (subprocesses and `hex.build`). Module name: `Scrypath.Release.PackageContentsTest`.

**Build the real archive** (lines 140-142) and the subprocess helper (lines 154-174):
```elixir
  defp build_packaged_artifact!(repo_root, artifact_dir) do
    run_mix!(["hex.build", "--unpack", "--output", artifact_dir], cd: repo_root)
  end
...
  defp run_command!(command, args, opts) do
    cmd_opts =
      opts
      |> Keyword.take([:cd, :env])
      |> Keyword.put(:stderr_to_stdout, true)

    {output, exit_status} = System.cmd(command, args, cmd_opts)

    assert exit_status == 0,
           """
           command failed: #{command} #{Enum.join(args, " ")}

           #{output}
           """

    output
  end
```

**Artifact path listing** (lines 187-196) is the model for walking the unpacked dir:
```elixir
  defp artifact_paths!(artifact_dir) do
    artifact_dir
    |> Path.join("**")
    |> Path.wildcard(match_dot: true)
    |> Enum.map(&Path.relative_to(&1, artifact_dir))
    |> Enum.reject(
      &(&1 in [".", ".git"] or String.starts_with?(&1, ".git/") or String.ends_with?(&1, "/"))
    )
    |> Enum.sort()
  end
```

**Isolated-env pattern** (explicit `MIX_ENV` + `MIX_BUILD_PATH`; research F9 says subprocesses do not inherit `:test` from `preferred_envs`). Copy the shape from `lib/mix/tasks/verify.no_optional_deps.ex`:
- `compile_env/1` (lines 78-80 in that file): `[{"MIX_ENV", "prod"}, {"MIX_BUILD_PATH", build_path}]`
- `System.cmd` with `env:` and `stderr_to_stdout: true` (lines 35-40)
- `mix_executable!/0` (lines 126-129): `System.find_executable("mix") || Mix.raise(...)`

Consumer smoke test uses the same idea for Hex/Mix state (lines 13-19):
```elixir
    hex_home = Path.join(tmp_root, "hex_home")
    mix_home = Path.join(tmp_root, "mix_home")
    File.mkdir_p!(hex_home)
    File.mkdir_p!(mix_home)
    isolated_env = [{"HEX_HOME", hex_home}, {"MIX_HOME", mix_home}, {"MIX_ENV", "dev"}]
```
For the mutation test add `{"HEX_OFFLINE", "1"}` and a per-test `MIX_BUILD_PATH` (RESEARCH Pattern 3 sketch, 183-RESEARCH.md lines 419-439).

**Temp dirs:** the repo has no `@tag :tmp_dir` usage yet (grep found none). Existing convention is `unique_tmp_dir!/0` (`consumer_smoke_test.exs` lines 176-185) plus `on_exit(fn -> File.rm_rf(tmp_root) end)` (line 21). CONTEXT D-11 asks for `@tag :tmp_dir`; it is an ExUnit built-in, so it is allowed, but the planner should know it is new to this repo and the existing helper is the fallback.

**Pure-classifier unit tests** (assert exact tag and name, not just `{:error, _}`): model on `test/mix/tasks/verify_release_parity_test.exs` lines 7-24 (`compute/2` with literal fixtures) and `test/mix/tasks/verify_workspace_clean_test.exs` lines 49-70 (`classify/3` branch-per-test).

**Boundary guard (D-17), placed in a `describe "tooling boundary"` here** (research Open Question 3). Analog for the `refute ... in package files` shape: `test/mix/tasks/dependency_audit_test.exs` lines 429-431:
```elixir
  test "the repository-only audit script is outside the Hex package whitelist" do
    refute "scripts" in Scrypath.MixProject.project()[:package][:files]
  end
```
Body to copy: RESEARCH Pattern 6 first test (183-RESEARCH.md lines 489-494).

**Mutation-fixture gotchas to encode** (RESEARCH F6): (a) the "hidden" case must be a top-level `defmodule Mix.Tasks.Verify.Hidden` appended to an ordinary `lib/scrypath/*.ex`, not nested; (b) the `files:` mutation edits `mix.exs` by string replace, so `refute mutated == original`.

---

### D-04 guard test (test, transform)

**Analog:** `test/mix/tasks/verify_capability_test.exs` lines 76-82 (preferred_envs assertion):
```elixir
  test "canonical capabilities select the test environment before dispatch" do
    preferred_envs = Scrypath.MixProject.cli()[:preferred_envs]

    for task <- ["verify.core", "verify.backend", "verify.postgres" | @strict_tasks] do
      assert preferred_envs[String.to_existing_atom(task)] == :test
    end
  end
```
**Body to copy:** RESEARCH Pattern 6 second test (183-RESEARCH.md lines 496-512). Classify by the `Mix.Task` behaviour attribute, not `Mix.Task.task?/1` (research F5: three helper modules, `Verify.Capability`, `Verify.PhoenixExample.LockGraph`, `Verify.PhoenixExample.Package`, are not tasks and `Package` would fool `task?/1`). Assert non-empty and the per-task mapping; do not hard-code 50.

---

### `dev/mix/tasks/**` (53 files, `git mv`) including `verify.namespace_fence.ex`

**Analog:** the existing files at `lib/mix/tasks/verify*.ex`, `lib/mix/tasks/verify/**`, and `lib/mix/tasks/scrypath.namespace_fence.ex` (61 tracked files under `lib/mix/tasks` today = 8 public + 53 to move).

**Keep in `lib/mix/tasks` (8):** `scrypath.status.ex`, `scrypath.failed.ex`, `scrypath.retry.ex`, `scrypath.reconcile.ex`, `scrypath.settings.diff.ex`, `scrypath.settings.read.ex`, `scrypath.settings.hot_apply.ex`, `scrypath/index/contract_drift.ex`.

**Layout to preserve** (relative paths under `dev/mix/tasks/`): top-level `verify*.ex` (40), `verify/{backend,capability,compatibility,core,deep_quality,ecommerce_e2e,ecommerce_mounted,package,phoenix_example,repository_contracts}.ex`, `verify/phoenix_example/{lock_graph,package}.ex`, plus the renamed fence `verify.namespace_fence.ex`.

**Rename edit for the fence** (`lib/mix/tasks/scrypath.namespace_fence.ex` line 1 and line 118):
```elixir
defmodule Mix.Tasks.Scrypath.NamespaceFence do
...
    Mix.raise("scrypath.namespace_fence does not accept arguments, got: #{Enum.join(args, " ")}")
```
becomes `Mix.Tasks.Verify.NamespaceFence` and the string `verify.namespace_fence`. The module's other contents (`@pattern`, `@fence_rules`, `check/1`) are unchanged.

**Call sites that must rename in the same change** (`lib/mix/tasks/verify/capability.ex` lines 104-114):
```elixir
    task_runner.("verify.no_optional_deps", [])
    task_runner.("scrypath.namespace_fence", [])
    if include_audit?, do: command_runner.("hex.audit", [])
    ...
  defp run_deep_quality_task!("scrypath.namespace_fence", []) do
    Mix.Task.run("scrypath.namespace_fence")
    :ok
  end
```
and `test/mix/tasks/verify_capability_test.exs` lines 88 and 97 (`{:task, "scrypath.namespace_fence", []}`). After the rename, `grep -rn "scrypath.namespace_fence"` outside `.planning/` must be empty (research Pitfall 7). The `CHANGELOG`, README and guides do not mention the fence (verified by grep).

**Commit hygiene (D-16 + research F8):** do the fence rename in place first (module, task name, `capability.ex`, test move, `preferred_envs`), then the pure `git mv` of all 53 files so the move commit is 53/53 100% renames. Verify with `git diff -M --stat`.

---

### `test/mix/tasks/verify_namespace_fence_test.exs` (rename of `test/mix/tasks/scrypath/namespace_fence_test.exs`)

**Analog:** the existing file (47 lines of tests plus two helpers). Only the header and alias change:
```elixir
defmodule Mix.Tasks.Scrypath.NamespaceFenceTest do
  use ExUnit.Case, async: true

  alias Mix.Tasks.Scrypath.NamespaceFence
```
becomes `Mix.Tasks.Verify.NamespaceFenceTest` / `alias Mix.Tasks.Verify.NamespaceFence`. Move to `test/mix/tasks/` (flat, alongside `verify_*_test.exs`); the now-empty `test/mix/tasks/scrypath/` dir disappears. The "live repository still passes as a canary" test (line 46-48) keeps working because it uses `File.cwd!()`.

---

### 14 path-coupled test files (conversion to `Scrypath.RepoTooling`)

**Analog:** each file's own call site. Observed shapes (grep this session: **32 lines in 13 files**, not 34/14 as CONTEXT says; accept by grep, see "Notes for the planner"):

| Shape | Sites | Convert to |
|---|---|---|
| `File.read!("lib/mix/tasks/verify.phaseNN.ex")` inside a test | `verify.phase{97,98,99,106,107,108,112}_test.exs` (one each, line 27-28), `verify_adopter_test.exs:79` | `Scrypath.RepoTooling.task_source!("verify.phaseNN.ex")` |
| `File.read!("lib/mix/tasks/verify/phoenix_example/package.ex")` | `verify_phoenix_example_package_test.exs:40` | `Scrypath.RepoTooling.task_source!("verify/phoenix_example/package.ex")` |
| compile-time `@attr File.read!(...)` | `docs_contract_test.exs` lines 17-34 and 67 (19 attrs), `phase99_contract_test.exs:11` | `@verify_phase11 Scrypath.RepoTooling.task_source!("verify.phase11.ex")` etc. |
| path strings for `File.exists?` | `verify_capability_test.exs:46,48` | `Scrypath.RepoTooling.task_path("verify.ops_ui.ex")` / `task_path("verify/#{task}.ex")` |
| module attribute path | `workflow_wiring_test.exs:8` `@verify_task "lib/mix/tasks/verify.ex"` | `@verify_task Scrypath.RepoTooling.task_path("verify.ex")` |

**Excerpt of the compile-time shape to convert** (`test/scrypath/docs_contract_test.exs` lines 17-18):
```elixir
  @verify_phase11 File.read!("lib/mix/tasks/verify.phase11.ex")
  @verify_phase14 File.read!("lib/mix/tasks/verify.phase14.ex")
```
**Excerpt of the in-test shape** (`test/mix/tasks/verify.phase97_test.exs` lines 27-34):
```elixir
    test "source defines focused test and docs command path" do
      source = File.read!("lib/mix/tasks/verify.phase97.ex")

      assert source =~ ~S|"test/mix/tasks/verify.phase97_test.exs"|
```
Everything asserted is content, never location, so only the read path changes. The pinned strings `"test/mix/tasks/verify.phase97_test.exs"` etc. stay (D-15: tests do not move).

**Acceptance (use grep, not the count):** after D-16 step 1, `grep -rn "lib/mix/tasks/verify" test` returns nothing; after step 3 the helper's `@tasks_root` flips and `grep -rn "lib/mix/tasks" test` returns only deliberate references (e.g. boundary guard, public-task tripwire).

---

### `test/mix/tasks/workflow_wiring_test.exs` (HYG-02 scans, test, file-I/O)

**Analog:** itself, lines 8 and 16-35 (two `Path.wildcard("lib/**/*.ex")` scans):
```elixir
    test "no library source changes compiler options at runtime" do
      offenders =
        "lib/**/*.ex"
        |> Path.wildcard()
        |> Enum.filter(&(File.read!(&1) =~ "Code.put_compiler_option"))
```
```elixir
    test "no_warn_undefined is limited to Oban modules" do
      site_count =
        "lib/**/*.ex"
        |> Path.wildcard()
        |> Enum.map(&assert_oban_suppressions!(File.read!(&1), &1))
        |> Enum.sum()
```
Change both to cover `dev/**/*.ex` too, e.g. `["lib/**/*.ex", "dev/**/*.ex"] |> Enum.flat_map(&Path.wildcard/1)`. The Oban site count assertion (`>= 3`) stays valid (all Oban sites are in `lib/scrypath/oban*`; research confirmed no `no_warn_undefined` in `dev/`). `Path.wildcard` on a pattern with no matches returns `[]`, so step 2 of D-16 can land before the move.

---

### `test/release/consumer_smoke_test.exs` (L2 extension, test, batch)

**Analog:** itself. The existing first test builds the archive, tags a git repo, runs `mix new`, `deps.get`, `compile` (lines 6-71), and holds the enumerated denylist this phase supersedes.

**Block that L0 replaces** (lines 33-46):
```elixir
    forbidden_prefixes = [
      "scrypath_ops/",
      "examples/",
      "website/",
      ".planning/",
      "node_modules/",
      "playwright-report/",
      "test-results/"
    ]

    for prefix <- forbidden_prefixes do
      refute Enum.any?(artifact_paths, &String.starts_with?(&1, prefix)),
             "artifact unexpectedly included forbidden path prefix #{prefix}"
    end
```
Replace with a call to `Scrypath.Release.PackageContract.check(artifact_dir)` and keep the positive assertions on lines 26-31 (lib/, mix.exs, README, CHANGELOG, guides/, docs/releasing.md).

**Reuse the compiled consumer, no second `deps.get`** (RESEARCH Pattern 5, 183-RESEARCH.md lines 463-483): hoist the expensive setup (artifact build, git tag, `mix new`, `deps.get`, `compile`) into `setup_all` returning `%{app_dir: ..., artifact_dir: ...}` (an `on_exit` registered in `setup_all` runs after the module), keep the existing "compiles the documented `use Scrypath` path" assertion, and add a second test that reads the compiled consumer:
- `ebin = Path.join(app_dir, "_build/dev/lib/scrypath/ebin")` has no `Elixir.Mix.Tasks.Verify.*.beam`; the `Elixir.Mix.Tasks.*` names from `scrypath.app` `:modules` equal `PackageContract.public_tasks()`.
- `System.cmd("mix", ["verify.package"], cd: app_dir, env: isolated_env, stderr_to_stdout: true)` exits non-zero and matches `The task "verify.package" could not be found`.
- `mix scrypath.status` with no args exits 1 and matches `expected one schema module argument` (research observed this in the bare consumer; the `mix help` fallback is not needed).

**Isolated env to pass every time** (line 19): `[{"HEX_HOME", hex_home}, {"MIX_HOME", mix_home}, {"MIX_ENV", "dev"}]`. The consumer runs in `dev`; the scrypath git dependency compiles in `:prod`, so the Verify beams are absent there by construction.

**Second test, unchanged** (lines 73-83): `the smoke dependency stays release-like and never falls back to path deps`. Leave as is.

---

### `test/release/package_metadata_test.exs` (test)

**Analog:** itself, lines 35-52. Add one line next to the existing refutes:
```elixir
    refute "scrypath_ops" in package_files
    refute "examples" in package_files
    refute "website" in package_files
    refute ".planning" in package_files
    refute "node_modules" in package_files
    refute "playwright-report" in package_files
    refute "test-results" in package_files
```
Add `refute "dev" in package_files`. Keep the same style and position (end of list, lines 45-51).

---

### `dev/mix/tasks/verify.phase11.ex` + `test/scrypath/docs_contract_test.exs` pin (D-12)

**Analog:** the existing list and pin.

**Test list to extend** (`lib/mix/tasks/verify.phase11.ex` lines 28-35, becomes `dev/mix/tasks/...` after the move):
```elixir
    run_test!(
      [
        "test/release/package_metadata_test.exs",
        "test/release/consumer_smoke_test.exs",
        "test/scrypath/docs_contract_test.exs"
      ],
      "Release contract tests"
    )
```
Insert `"test/release/package_contents_test.exs"` after `package_metadata_test.exs` and before `consumer_smoke_test.exs` (hermetic fast failure first; consumer smoke needs network).

**Pin to extend** (`test/scrypath/docs_contract_test.exs` lines 946-950):
```elixir
  test "verify.phase11 keeps the release gate auth-free and complete" do
    assert_contains_all(@verify_phase11, [
      "test/release/package_metadata_test.exs",
      "test/release/consumer_smoke_test.exs",
      "test/scrypath/docs_contract_test.exs",
      "mix verify.release_publish"
    ])
```
Add `"test/release/package_contents_test.exs",`. Do not add a new Mix task or CI job: `verify.package` -> `Capability.run(:package)` (`verify/capability.ex` lines 7-8) -> `Phase11.run_without_docs/0` already runs in the required `package` job (`.github/workflows/ci.yml` lines 137-158, `run: mix verify.package` at line 158), `release-please.yml` and `publish-hex.yml`.

---

### `dev/mix/tasks/verify.workspace_clean.ex` + its test (D-08)

**Analog:** itself, `lib/mix/tasks/verify.workspace_clean.ex` lines 85-97:
```elixir
  def build_pathspecs do
    project = Mix.Project.config()

    package_files =
      project
      |> Keyword.get(:package, [])
      |> Keyword.get(:files, [])

    # test/** included even though not packaged — uncommitted tests
    # mean "the lib/ state being published was not tested as it will ship."
    package_files ++ ["test"]
  end
```
Change to `package_files ++ ["dev", "test"]` and update the comment (dev is unpackaged but must be committed for the gate to mean anything). `git status --porcelain -- ... dev` exits 0 when `dev` is absent, so this edit may land before the move (D-16 step 2).

**Test to extend** (`test/mix/tasks/verify_workspace_clean_test.exs` lines 25-26): existing assertions are membership-only (`assert "test" in pathspecs`); add `assert "dev" in pathspecs` next to it. The existing assertions will not break.

---

### `.formatter.exs`, `.credo.exs` (config)

**Analog:** themselves. Exact edits (RESEARCH "Config edits"):
- `.formatter.exs` line 4: `"{config,lib,test}/**/*.{ex,exs}",` -> `"{config,lib,dev,test}/**/*.{ex,exs}",`
- `.credo.exs` line 6: `included: ["lib/", "test/", "mix.exs"],` -> `included: ["lib/", "dev/", "test/", "mix.exs"],`

Both fail silently if omitted (research proved a malformatted `dev/` file passes `mix format --check-formatted` without the entry; credo drops from 266 to 213 files).

---

### `scripts/ci/beam_cache.cjs` and `scripts/ci/beam_cache.test.cjs` (config + test)

**Analog:** themselves. The four `sourceRoots` (lines 18, 24, 30, 36 of `beam_cache.cjs`), root graph shown:
```js
  root: {
    manifests: ["mix.exs"],
    locks: ["mix.lock"],
    sourceRoots: ["lib", "test", "config", "priv"],
    resolvedPaths: ["deps", "_build/test"]
  },
```
Add `"dev"` right after `"lib"` in all four graphs (`root`, `ops`, `ecommerce`, `phoenix-example`). `collectSourceFiles` (line 185-206) guards with `if (fs.existsSync(absolute)) visit(sourceRoot)`, so adding `"dev"` before the directory exists is safe. The edit rotates all four cache keys once (expected).

**Fixture test pattern to extend** (`beam_cache.test.cjs` lines 180-223): temp tree built from a `files` map, then `fs.appendFileSync` on one file and `assert.notEqual(plan(...).resolved_key, before.resolved_key)`:
```js
  const files = {
    "mix.exs": "root manifest\n",
    "mix.lock": "root lock\n",
    "lib/root.ex": "root source\n",
    ...
  };
  ...
  const plan = (graph) => buildPlan({ graph, root, env, elixirVersionOutput: versions });
  const rootBefore = plan("root");
  ...
  fs.appendFileSync(path.join(root, "scrypath_ops/mix.lock"), "changed\n");
  const opsChanged = plan("ops");
  assert.notEqual(opsChanged.resolved_key, opsBefore.resolved_key);
```
Add `"dev/mix/tasks/verify.ex": "maintainer source\n"` to `files`, then for each of the four graphs record `plan(graph).resolved_key`, `fs.appendFileSync(path.join(root, "dev/mix/tasks/verify.ex"), "changed\n")`, and assert it changed. Because the append touches a shared root file, take all four "before" plans before the append. Prefer a new `test(...)` block for readability. This suite runs inside `workflow_wiring_test.exs` (the `repository-contracts` lane), per research.

---

### `.github/workflows/ci.yml` line 359 (config)

**Analog:** itself:
```bash
          if [[ "$GITHUB_EVENT_NAME" == pull_request ]] && git diff --name-only "origin/$GITHUB_BASE_REF...HEAD" | grep -qE '^(scrypath_ops/|lib/|mix\.exs|mix\.lock)'; then echo run=true >> "$GITHUB_OUTPUT"; else echo run=false >> "$GITHUB_OUTPUT"; fi
```
Change the regex to `'^(scrypath_ops/|lib/|dev/|mix\.exs|mix\.lock)'`. This is the only `lib/` path filter in any workflow (grep of `.github/workflows/*.yml`). Required job names (`package (required)` etc.) do not change. Check `test/mix/tasks/workflow_wiring_test.exs` and `docs_contract_test.exs` for pins on this regex string before editing (not found in this session's greps, but run `grep -rn "scrypath_ops/|lib/" test` once).

---

### `CODEOWNERS` (optional)

**Analog:** itself, a single line (`lib/scrypath/ @szTheory`). If added, mirror the style: `dev/ @szTheory` or `/dev/ @szTheory`. Claude's Discretion per CONTEXT.

---

### Docs: `CONTRIBUTING.md`, `README.md`, `guides/support-and-compatibility.md`, `guides/outside-adopter-intake.md`

**Analog:** the existing wording; these lines are pinned by contract tests (`docs_contract_test.exs:315-343`, `phase99_contract_test.exs`, `readiness_contract_test.exs`, `phase98_contract_test.exs` per research), so keep the exact command strings and only add a qualifier.

| File | Line(s) | Existing text to keep verbatim | Add |
|---|---|---|---|
| `README.md` | 31 | `Run \`mix verify.adopter\` locally or \`mix verify.adopter --live\` with its services` | qualifier "from a source checkout (not part of the Hex package)" |
| `README.md` | 200, 204 | `mix verify.meilisearch_smoke` (code block) and `` `mix verify.meilisearch_smoke --skip-integration` `` | qualifier near the "Locally you can use Docker Compose (from the repo root)" sentence (line ~196), not inside the code block |
| `guides/support-and-compatibility.md` | 77-78 | `` - `mix verify.adopter` is the fast, service-free contract check ... `` / `` - `mix verify.adopter --live` is the prerequisite-bound live check ... `` | qualifier on the lead-in sentence |
| `guides/outside-adopter-intake.md` | 30-31 | `` - `mix verify.adopter`: The fast, auth-free, service-free path ... `` / `` - `mix verify.adopter --live`: The live path ... `` | qualifier on the lead-in ("We use two commands...", line 28) |
| `CONTRIBUTING.md` | before line 28 | line 28: `Use capability-named commands for new work. Historical \`verify.phase*\` commands remain supported...` | one sentence (D-18 wording, RESEARCH 183-RESEARCH.md line 619) as a code span, not a link: "Repository-only `mix verify*` tasks live in `dev/mix/tasks/` and are not part of the Hex package; public operator tasks (`mix scrypath.*`) stay in `lib/mix/tasks/`. Command names and focused test paths are unchanged. Verifier tasks compile only under `MIX_ENV=test`, which `preferred_envs` selects automatically; `MIX_ENV=dev mix verify.x` (or `mix help verify.x` without `MIX_ENV=test`) reports that the task could not be found." |

Do not write `Mix.Tasks.Verify.*` or backtick-linkable module names in packaged docs (ExDoc autolinks). Research verified the D-18 sentence shape produces zero ExDoc warnings in both `MIX_ENV=dev` and `MIX_ENV=test`. Do not hand-edit `CHANGELOG.md` (release-please owns it, D-19).

Optional: one sentence in `docs/releasing.md` describing the new contents gate inside `verify.package` (`docs/releasing.md` lines 26-31 describe `mix verify.package`). No contract test forbids it.

---

## Shared Patterns

### Pure checker plus thin runner (testable exit semantics)
**Source:** `lib/mix/tasks/verify.release_parity.ex` lines 33-36 (rationale), 80-99 (`compute/2`); `lib/mix/tasks/verify.workspace_clean.ex` lines 53-77 (`classify/3`)
**Apply to:** `Scrypath.Release.PackageContract` (`classify/2` pure, `check/1` thin I/O); keep side effects (`File.ls!`, `File.read!`, `System.cmd`) out of the classifier so unit tests need no subprocess.

### Isolated subprocess environment
**Source:** `lib/mix/tasks/verify.no_optional_deps.ex` lines 35-40 and 78-80; `test/release/consumer_smoke_test.exs` lines 13-19
**Apply to:** every `System.cmd("mix", ...)` in `package_contents_test.exs` and the extended `consumer_smoke_test.exs`. Always pass `MIX_ENV`, `MIX_BUILD_PATH`, `HEX_HOME`, `MIX_HOME` explicitly (research F9: `preferred_envs` routing changes `Mix.env()` in-process only, so local runs spawn `:dev` subprocesses while CI spawns `:test`).
```elixir
    {output, status} =
      System.cmd(
        mix_executable!(),
        ["compile", "--force", "--no-optional-deps", "--warnings-as-errors"],
        env: compile_env(build_path),
        stderr_to_stdout: true
      )
```

### Always write `hex.build --unpack` to an explicit `--output`
**Source:** `test/release/consumer_smoke_test.exs` line 141 (`["hex.build", "--unpack", "--output", artifact_dir]`)
**Apply to:** every new gate input. Never use the default output (it writes `scrypath-<version>/` into the repo root and races `Phase11`'s own final unpack, `verify.phase11.ex` line 45).

### "Not in the Hex package" guard
**Source:** `test/mix/tasks/dependency_audit_test.exs` lines 429-431; `test/release/package_metadata_test.exs` lines 45-51
**Apply to:** the `refute "dev" in package_files` assertions (D-12, D-17). Prior art in this repo for a repo-only Elixir module kept outside `lib/` and `files:` is `scripts/ci/dependency_audit.ex`.

### Contract tests pin source text, so edits to pinned sources need matching pin updates
**Source:** `test/scrypath/docs_contract_test.exs` lines 17-34 (`File.read!` attrs) and 946-955 (`assert_contains_all`)
**Apply to:** `verify.phase11.ex` list change, README/guide qualifiers, CONTRIBUTING sentence. Run `mix test test/scrypath/docs_contract_test.exs test/scrypath/phase99_contract_test.exs test/scrypath/readiness_contract_test.exs test/mix/tasks/` after each step.

### Silent-coverage-loss edits (each needs a check that can fail)
**Source:** research Pitfall 2.
**Apply to:** `.formatter.exs`, `.credo.exs`, `beam_cache.cjs` (+ fixture), `ci.yml` regex, `verify.workspace_clean` pathspecs (+ `"dev" in pathspecs` assertion), HYG-02 scans (+ `dev/**` glob). For formatter and credo, record a one-time proof in the plan's acceptance evidence (deliberately malformat a `dev/` file; expect rejection).

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `@tag :tmp_dir` hermetic copy-and-mutate harness in `package_contents_test.exs` | test | batch | No existing test uses `@tag :tmp_dir`; the repo's convention is `unique_tmp_dir!/0` + `on_exit` (`consumer_smoke_test.exs` lines 21, 176-185). Planner should follow RESEARCH Pattern 3 (183-RESEARCH.md lines 415-448) for the copy list and `build_and_check!/2`; either temp-dir mechanism is acceptable. |
| Nested-aware `defmodule` walk in `PackageContract.collect_task_modules/1` | utility | transform | Partial analog only: `test/mix/tasks/workflow_wiring_test.exs` lines 881-905 (`assert_oban_suppressions!/2`) already uses `Code.string_to_quoted!/1` + `Macro.prewalk/3` over `lib/**/*.ex` sources and is tested with positive/negative in-memory fixtures (lines 37-65). It does not resolve nested `defmodule` names, so use the prototype in RESEARCH Pattern 2 (`modules/2` + `resolve/2`, 183-RESEARCH.md lines 390-411) for the walk and copy only the parse-then-walk shape and the in-memory fixture testing style from the analog. |

## Notes for the planner

- **D-07 amendment (research F1):** keep `docs/0` unchanged; `filter_modules` turns `MIX_ENV=test mix docs --warnings-as-errors` red (about 59 warnings). The plan should state this amendment and its evidence up front so the maintainer can veto.
- **D-14 count (research F3):** grep finds 32 sites in 13 files today. Use the grep-based acceptance criterion, not the count.
- **Ordering that keeps every commit green (D-16 + F8):** (1) add `Scrypath.RepoTooling` pointing at `lib/mix/tasks` and convert all call sites; (2) additive configs (`.formatter.exs`, `.credo.exs`, `beam_cache.cjs` + test, `ci.yml`, `workspace_clean` pathspec, `workflow_wiring` scans, `elixirc_paths` + `preferred_envs`); (3) do the fence rename in place, then the pure `git mv` of 53 files, flip `@tasks_root`, add the boundary guard and D-04 guard; (4) add `PackageContract`, `package_contents_test.exs`, extend `consumer_smoke_test.exs`, wire `verify.phase11` + pin + `package_metadata_test`; record the pre-move violation count (research F4: 53 on the current HEAD build, 52 on the published 0.3.17 archive) using `mix hex.build --unpack --output <tmp>` before step 3; (5) docs.
- **Both new support modules are loaded by `test/test_helper.exs` before test files compile**, so no `Code.require_file` is needed in the tests (unlike `dependency_audit_test.exs` line 4, which loads `scripts/ci/dependency_audit.ex` explicitly).
- **Public-task allowlist source of truth:** 8 names, `scrypath.{status,failed,retry,reconcile}`, `scrypath.settings.{diff,read,hot_apply}`, `scrypath.index.contract_drift`. `scrypath.settings.read` is documented outside `guides/operator-mix-tasks.md` (in `guides/relevance-tuning.md` line 73); the D-11 "fix:" hint should therefore say "document it in a packaged guide (for example `guides/operator-mix-tasks.md`)" or keep the planner-approved wording.
- **Runtime state:** no data migration. The published Hex 0.3.17 and its HexDocs stay immutable; only the next release (separate, maintainer-confirmed) fixes adopters.

## Metadata

**Analog search scope:** `/Users/jon/projects/scrypath/{mix.exs,.formatter.exs,.credo.exs,CODEOWNERS,CONTRIBUTING.md,README.md,guides/,docs/releasing.md,lib/mix/tasks/,test/,scripts/ci/,.github/workflows/,scrypath_ops/mix.exs,examples/*/mix.exs}`
**Files scanned:** about 45 (read in full or targeted ranges: `mix.exs`, `verify.release_parity.ex`, `verify.workspace_clean.ex`, `verify.no_optional_deps.ex`, `verify.phase11.ex`, `verify/capability.ex`, `scrypath.namespace_fence.ex` head, `consumer_smoke_test.exs`, `package_metadata_test.exs`, `namespace_fence_test.exs`, `verify_capability_test.exs`, `verify_workspace_clean_test.exs`, `verify_release_parity_test.exs`, `verify_no_optional_deps_test.exs`, `dependency_audit_test.exs`, `workflow_wiring_test.exs`, `docs_contract_test.exs`, `beam_cache.cjs`, `beam_cache.test.cjs`, `ci.yml` ranges, `test_helper.exs`, test-support modules, doc line ranges)
**Pattern extraction date:** 2026-10-27
