# Phase 18: Release-Parity Gate + Node 20 CI Cleanup - Pattern Map

**Mapped:** 2026-04-17
**Files analyzed:** 13 (6 new, 7 modified)
**Analogs found:** 13 / 13

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/mix/tasks/verify.workspace_clean.ex` (NEW) | Mix verify task (CLI) | request-response (shell-out) | `lib/mix/tasks/verify.phase11.ex` | exact (same role + flow) |
| `lib/mix/tasks/verify.release_parity.ex` (NEW) | Mix verify task (CLI) | request-response + retry loop + tmp-dir | `lib/mix/tasks/verify.release_publish.ex` (retry/tmp-dir) + `lib/mix/tasks/verify.phase13.ex` (OptionParser) | exact (retry+tmp) / role-match (flags) |
| `test/mix/tasks/verify_workspace_clean_test.exs` (NEW) | ExUnit unit test | CaptureIO + Mix.Task.reenable | `test/scrypath/mix_tasks/operator_tasks_test.exs` | exact (same role + flow) |
| `test/mix/tasks/verify_release_parity_test.exs` (NEW) | ExUnit unit + integration test | CaptureIO + subprocess via `System.cmd` | `test/scrypath/mix_tasks/operator_tasks_test.exs` (unit) + `test/release/consumer_smoke_test.exs` (subprocess + tmp-dir) | exact (both branches) |
| `test/mix/tasks/workflow_wiring_test.exs` (NEW) | ExUnit contract test (YAML grep) | read-file + regex assertion | `lib/mix/tasks/verify.phase11.ex` §`validate_release_contract!/0` (shape) + `test/scrypath/mix_tasks/operator_tasks_test.exs` (ExUnit form) | role-match (shape inverted: runs as test, not task) |
| `.github/ISSUE_TEMPLATE/release-parity-drift.md` (NEW) | GitHub issue template | static markdown + frontmatter interpolation | No existing analog in repo — use RESEARCH.md Pattern 6 verbatim | no-analog |
| `mix.exs` (MODIFIED) | Project config (Mix) | config data | `mix.exs` L38-48 existing `cli.preferred_envs` list | exact (same block) |
| `.github/workflows/ci.yml` (MODIFIED) | GitHub Actions workflow YAML | pin swaps + new step | `.github/workflows/release-please.yml` (already `@v6`) for pin target; self for step-insertion structure | exact (sibling workflow) |
| `.github/workflows/release-please.yml` (MODIFIED) | GitHub Actions workflow YAML | new step inside `publish-hex` job | `.github/workflows/release-please.yml` §`publish-hex` existing steps (L48-83) | exact (same job) |
| `.github/workflows/publish-hex.yml` (MODIFIED) | GitHub Actions workflow YAML | new step | `.github/workflows/publish-hex.yml` existing steps (L22-57) | exact (same file) |
| `.github/workflows/verify-published-release.yml` (MODIFIED) | GitHub Actions workflow YAML | new step + guarded new step | `.github/workflows/verify-published-release.yml` existing `verify.release_publish` step (L75-80) for shape; RESEARCH.md Pattern 5 for `create-an-issue` | exact (same file) |
| `docs/releasing.md` (MODIFIED) | Maintainer docs (HexDocs-visible) | prose additions | existing `docs/releasing.md` sections | exact (same file) |
| `CHANGELOG.md` (MODIFIED) | Keep-a-Changelog entry | unreleased entry addition | existing `## Unreleased` section | exact (same file) |

---

## Pattern Assignments

### `lib/mix/tasks/verify.workspace_clean.ex` (Mix verify task, request-response)

**Analog:** `lib/mix/tasks/verify.phase11.ex`
**Why this analog:** Same module namespace (`Mix.Tasks.Verify.*`), same `System.cmd(..., stderr_to_stdout: true)` shell-out idiom, same `ensure_no_args!/1` argument-guard helper, same `Mix.raise/1` error surfacing. No retry loop (network-free check), no OptionParser (no flags) — minimal shape.

**Module header + `use Mix.Task` pattern** (copy from `verify.phase11.ex:1-12`):
```elixir
defmodule Mix.Tasks.Verify.WorkspaceClean do
  use Mix.Task

  @shortdoc "Fails if the working tree has uncommitted changes in packaged paths"

  @moduledoc """
  Verifies that `git status` is clean for all pathspecs that ship in the Hex
  tarball plus `test/**`.

  Runs as the first step of every publish path (canonical release-please flow,
  manual-recovery workflow, and per-push CI) so a release cannot ship files
  that were not reviewed and merged.
  """
```

**`run/1` entry shape** (copy from `verify.phase11.ex:14-17`):
```elixir
  @impl true
  def run(args) do
    Mix.Task.run("app.start")
    ensure_no_args!(args)
    # ... task body ...
  end
```

**`ensure_no_args!/1` helper** (copy verbatim from `verify.phase11.ex:164-168`, rename task label):
```elixir
  defp ensure_no_args!([]), do: :ok

  defp ensure_no_args!(args) do
    Mix.raise("verify.workspace_clean does not accept arguments, got: #{Enum.join(args, " ")}")
  end
```

**Shell-out + exit-status branching** (derived from `verify.phase11.ex:153-162` `run_system_command!/3`; adapted to return stdout instead of raising on non-empty clean-output):
```elixir
    {output, exit_status} =
      System.cmd("git", ["status", "--porcelain", "--" | pathspecs],
        stderr_to_stdout: true
      )

    case {output, exit_status} do
      {"", 0} -> :ok
      {dirty_output, 0} -> raise_dirty!(dirty_output)
      {err, _nonzero} -> Mix.raise("git status failed:\n\n#{err}")
    end
```

**Pathspec derivation from `mix.exs package.files`** (new logic, follows D-01; reads from `Mix.Project.config/0`):
```elixir
  defp build_pathspecs do
    # Source of truth: mix.exs package.files (D-01)
    project = Mix.Project.config()

    package_files =
      project
      |> Keyword.get(:package, [])
      |> Keyword.get(:files, [])

    package_files ++ ["test"]  # D-05
  end
```

**`Mix.raise/1` dirty-tree message** (D-02 next-step copy; match tone from `verify.release_publish.ex:53-55` which is already the house style):
```elixir
  defp raise_dirty!(output) do
    Mix.raise("""
    Workspace is not clean. Uncommitted or untracked files exist in packaged paths:

    #{output}
    Resolve with:
      git add <path>           # stage
      git stash -u             # shelve
      git checkout -- <path>   # discard

    This gate exists because v1.2 shipped a partial tarball when uncommitted
    files did not travel to the release tag. See
    .planning/milestones/v1.2-MILESTONE-AUDIT.md for background.
    """)
  end
```

---

### `lib/mix/tasks/verify.release_parity.ex` (Mix verify task, request-response + retry + tmp-dir)

**Analog (primary):** `lib/mix/tasks/verify.release_publish.ex` — for retry loop, tmp-dir, env-integer parsing
**Analog (secondary):** `lib/mix/tasks/verify.phase13.ex` — for `OptionParser.parse/2` `--json` flag handling

**Module header + module attributes** (copy shape from `verify.release_publish.ex:1-15`):
```elixir
defmodule Mix.Tasks.Verify.ReleaseParity do
  use Mix.Task

  @shortdoc "Compares the Hex tarball against the git tag for a released version"

  @moduledoc """
  Verifies that the file list inside the published Hex tarball for `X.Y.Z`
  matches the file list inside `lib/ + guides/ + docs/` at git tag
  `scrypath-vX.Y.Z`.

  Exit codes:
    - 0 = parity (no drift)
    - 2 = drift detected (POSIX "intentional failure")
    - 1 = runtime error (network failure, missing tag, tarball fetch failure)

  Inherits `SCRYPATH_RELEASE_VERIFY_ATTEMPTS` / `SCRYPATH_RELEASE_VERIFY_SLEEP_MS`
  retry behavior from `verify.release_publish` so daily runs do not false-fail
  during CDN propagation of a freshly-cut release.
  """

  @default_attempts 10
  @default_sleep_ms 15_000
```

**`OptionParser.parse/2` for `--json` flag** (copy shape from `verify.phase13.ex:35-38`):
```elixir
  @impl true
  def run(args) do
    Mix.Task.run("app.start")

    {opts, argv, _invalid} =
      OptionParser.parse(args, strict: [json: :boolean])

    version = parse_version!(argv)
    attempts = env_integer("SCRYPATH_RELEASE_VERIFY_ATTEMPTS", @default_attempts)
    sleep_ms = env_integer("SCRYPATH_RELEASE_VERIFY_SLEEP_MS", @default_sleep_ms)
    # ...
  end
```

**`parse_version!/1` helper** (copy from `verify.release_publish.ex:50-56`; validate semver per Security §V5 — Pitfall 7):
```elixir
  defp parse_version!([version]) when version != "" do
    unless Regex.match?(~r/^\d+\.\d+\.\d+([.\-][A-Za-z0-9.\-]+)?$/, version) do
      Mix.raise("verify.release_parity expects a semver version, got: #{inspect(version)}")
    end

    version
  end

  defp parse_version!(_args) do
    Mix.raise(
      "verify.release_parity expects exactly one version argument, e.g. mix verify.release_parity 0.3.0"
    )
  end
```

**Retry loop** (copy verbatim from `verify.release_publish.ex:58-75`):
```elixir
  defp retry_until!(label, attempts, sleep_ms, fun) do
    Enum.reduce_while(1..attempts, nil, fn attempt, _acc ->
      Mix.shell().info("==> #{label} (attempt #{attempt}/#{attempts})")

      case fun.() do
        :ok ->
          {:halt, :ok}

        {:error, reason} when attempt < attempts ->
          Mix.shell().info(reason)
          Process.sleep(sleep_ms)
          {:cont, nil}

        {:error, reason} ->
          Mix.raise("#{label} failed after #{attempts} attempts\n\n#{reason}")
      end
    end)
  end
```

**`env_integer/2` helper** (copy verbatim from `verify.release_publish.ex:213-224`):
```elixir
  defp env_integer(name, default) do
    case System.get_env(name) do
      nil ->
        default

      value ->
        case Integer.parse(value) do
          {parsed, ""} when parsed > 0 -> parsed
          _ -> Mix.raise("#{name} must be a positive integer, got: #{inspect(value)}")
        end
    end
  end
```

**`unique_tmp_dir!/0` helper** (copy from `verify.release_publish.ex:202-211`, rename suffix per Pitfall 3):
```elixir
  defp unique_tmp_dir! do
    path =
      Path.join(
        System.tmp_dir!(),
        "scrypath-release-parity-#{System.unique_integer([:positive])}"
      )

    File.mkdir_p!(path)
    path
  end
```

**`try/after File.rm_rf/1` cleanup wrapper** (copy shape from `verify.release_publish.ex:92-119`; note non-bang variant per Pitfall 4):
```elixir
    tmp_root = unique_tmp_dir!()

    try do
      # fetch (with retry), enumerate hex paths, enumerate git paths, diff...
    after
      File.rm_rf(tmp_root)
    end
```

**Hex fetch invocation** (from RESEARCH.md `Code Examples` / D-06; shell-out shape follows `verify.release_publish.ex:78-88`):
```elixir
    {output, exit_status} =
      System.cmd("mix",
        ["hex.package", "fetch", "scrypath", version, "--unpack", "-o", tmp_dir],
        stderr_to_stdout: true
      )

    case exit_status do
      0 ->
        # Pitfall 5 sanity-check: empty unpack means network hiccup, retry
        if File.exists?(Path.join(tmp_dir, "mix.exs")) do
          :ok
        else
          {:error, "hex.package fetch succeeded but tmp_dir lacks mix.exs — empty tarball"}
        end

      _ ->
        {:error, "mix hex.package fetch failed:\n\n#{output}"}
    end
```

**Git ls-tree invocation + exit-128 guard** (from RESEARCH.md `Code Examples` / D-07; Pitfall 7 guard on non-zero):
```elixir
    {output, exit_status} =
      System.cmd("git",
        ["ls-tree", "-r", "--name-only", "scrypath-v#{version}", "--", "lib/", "guides/", "docs/"],
        stderr_to_stdout: true
      )

    case exit_status do
      0 ->
        git_paths = output |> String.split("\n", trim: true) |> MapSet.new()
        {:ok, git_paths}

      _ ->
        Mix.raise("git ls-tree failed for tag scrypath-v#{version}:\n\n#{output}")
    end
```

**Hex path enumeration with prefix trim** (Pitfall 6 fix verbatim):
```elixir
    hex_paths =
      Path.wildcard(Path.join(tmp_dir, "{lib,guides,docs}/**/*"))
      |> Enum.filter(&File.regular?/1)
      |> Enum.map(&Path.relative_to(&1, tmp_dir))
      |> MapSet.new()
```

**Path-set diff** (from RESEARCH.md `Code Examples`; D-08):
```elixir
    only_in_git = MapSet.difference(git_paths, hex_paths) |> MapSet.to_list() |> Enum.sort()
    only_in_hex = MapSet.difference(hex_paths, git_paths) |> MapSet.to_list() |> Enum.sort()

    case {only_in_git, only_in_hex} do
      {[], []} -> :parity
      {og, oh} -> {:drift, og, oh}
    end
```

**Exit-code-2 drift emission** (from RESEARCH.md Pattern 4; D-10/D-11):
```elixir
  defp emit_drift_and_halt!(only_in_git, only_in_hex, version, opts) do
    output =
      if opts[:json] do
        Jason.encode!(%{
          "version" => version,
          "status" => "drift",
          "only_in_git" => Enum.sort(only_in_git),
          "only_in_hex" => Enum.sort(only_in_hex)
        })
      else
        human_diff(only_in_git, only_in_hex, version)
      end

    Mix.shell().info(output)
    System.halt(2)   # explicit exit 2 per D-10 (POSIX "intentional failure")
  end
```

**Human-readable diff** (Pitfall 8 — summary-first):
```elixir
  defp human_diff(only_in_git, only_in_hex, version) do
    """
    Release parity drift detected for scrypath #{version}:
      #{length(only_in_git)} files only in git tag (missing from Hex tarball)
      #{length(only_in_hex)} files only in Hex tarball (not in git tag)

    Only in git tag (missing from Hex tarball):
    #{format_paths(only_in_git)}

    Only in Hex tarball (not in git tag):
    #{format_paths(only_in_hex)}
    """
  end

  defp format_paths([]), do: "  (none)"
  defp format_paths(paths), do: paths |> Enum.map(&"  #{&1}") |> Enum.join("\n")
```

**Testable-structure note for the planner:** To unit-test exit-2 drift semantics without `System.halt/1` killing the ExUnit runner (Pitfall 11), split the task into:

- `run/1` — top-level entry; calls `System.halt(2)` only in the drift case
- `compute/2` — pure function returning `{:parity} | {:drift, only_in_git, only_in_hex} | {:error, reason}`; unit-tested directly

---

### `test/mix/tasks/verify_workspace_clean_test.exs` (ExUnit unit test)

**Analog:** `test/scrypath/mix_tasks/operator_tasks_test.exs`
**Why this analog:** Existing ExUnit Mix-task test precedent — uses `ExUnit.CaptureIO`, `Mix.Task.reenable/1`, `Mix.Task.run/2`, `assert_raise Mix.Error`. Same shape needed here.

**File header + `CaptureIO` import** (copy verbatim from `operator_tasks_test.exs:1-4`):
```elixir
defmodule Mix.Tasks.Verify.WorkspaceCleanTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO
```

**`capture_io(fn -> Mix.Task.reenable + Mix.Task.run end)` idiom** (copy shape from `operator_tasks_test.exs:104-108`):
```elixir
  test "passes silently on clean workspace" do
    output =
      capture_io(fn ->
        Mix.Task.reenable("verify.workspace_clean")
        Mix.Task.run("verify.workspace_clean", [])
      end)

    assert output =~ "Checking workspace cleanliness"
  end
```

**`assert_raise Mix.Error, ~r/.../` pattern** (copy from `operator_tasks_test.exs:185-189`):
```elixir
  test "raises Mix.Error when argument is passed" do
    assert_raise Mix.Error, ~r/verify\.workspace_clean does not accept arguments/, fn ->
      Mix.Task.reenable("verify.workspace_clean")
      Mix.Task.run("verify.workspace_clean", ["stray-arg"])
    end
  end
```

**Pathspec derivation unit test** (leverages public `Mix.Project.config/0`, no fixture setup needed):
```elixir
  test "derives pathspecs from mix.exs package.files + test" do
    # Extract the helper as a public-ish function OR call a module attribute.
    # Simplest: expose `build_pathspecs/0` as a public function for testability.
    pathspecs = Mix.Tasks.Verify.WorkspaceClean.build_pathspecs()

    assert "lib" in pathspecs
    assert ".formatter.exs" in pathspecs
    assert "mix.exs" in pathspecs
    assert "README.md" in pathspecs
    assert "ARCHITECTURE.md" in pathspecs
    assert "CHANGELOG.md" in pathspecs
    assert "guides" in pathspecs
    assert "docs" in pathspecs
    assert "test" in pathspecs  # D-05
  end
```

---

### `test/mix/tasks/verify_release_parity_test.exs` (ExUnit unit + integration test)

**Analog (unit):** `test/scrypath/mix_tasks/operator_tasks_test.exs`
**Analog (subprocess integration):** `test/release/consumer_smoke_test.exs`

**Injection-friendly pure-function test** (unit-tests `compute/2`, avoids `System.halt/1` — Pitfall 11 Option A):
```elixir
  describe "compute/2 (pure path-diff)" do
    test "returns :parity when git paths and hex paths match" do
      git = MapSet.new(["lib/a.ex", "guides/x.md"])
      hex = MapSet.new(["lib/a.ex", "guides/x.md"])
      assert Mix.Tasks.Verify.ReleaseParity.compute(git, hex) == :parity
    end

    test "returns drift tuple when hex tarball is missing a file" do
      git = MapSet.new(["lib/a.ex", "lib/b.ex"])
      hex = MapSet.new(["lib/a.ex"])
      assert Mix.Tasks.Verify.ReleaseParity.compute(git, hex) ==
               {:drift, ["lib/b.ex"], []}
    end
  end
```

**JSON output shape assertion** (D-11):
```elixir
  test "emits --json output with stable field ordering" do
    json =
      Mix.Tasks.Verify.ReleaseParity.render_json(
        "0.3.0",
        :drift,
        ["lib/b.ex"],
        []
      )

    decoded = Jason.decode!(json)

    assert decoded == %{
             "version" => "0.3.0",
             "status" => "drift",
             "only_in_git" => ["lib/b.ex"],
             "only_in_hex" => []
           }
  end
```

**Retry-loop stub test** (RESEARCH.md Pitfall 1 `Specific guidance for testing`):
```elixir
  test "retry loop halts on first :ok after transient :error" do
    # The planner may make the fetch function injectable, or use :meck / :mox.
    # Simplest: expose retry_until!/4 (or equivalent) and pass a stub:
    {:ok, counter} = Agent.start_link(fn -> 0 end)

    result =
      Mix.Tasks.Verify.ReleaseParity.retry_until!(
        "stub fetch",
        3,
        1,  # sleep_ms = 1 to keep the test fast
        fn ->
          n = Agent.get_and_update(counter, &{&1 + 1, &1 + 1})
          if n == 1, do: {:error, "transient"}, else: :ok
        end
      )

    assert result == :ok
    assert Agent.get(counter, & &1) == 2  # failed once, succeeded on 2nd attempt
  end
```

**Subprocess-based exit-code integration test** (copy `System.cmd` + `assert exit_status == N` idiom from `consumer_smoke_test.exs:128-140`; Pitfall 11 Option B):
```elixir
  @tag :integration
  test "exits 0 against known-good 0.3.0 tag + hex tarball" do
    {_output, exit_status} =
      System.cmd("mix", ["verify.release_parity", "0.3.0"], stderr_to_stdout: true)

    assert exit_status == 0
  end
```

**`unique_tmp_dir!/0` test idiom** (copy verbatim from `consumer_smoke_test.exs:142-151` if the test ever needs its own tmp-dir):
```elixir
  defp unique_tmp_dir! do
    path =
      Path.join(
        System.tmp_dir!(),
        "scrypath-parity-test-#{System.unique_integer([:positive])}"
      )

    File.mkdir_p!(path)
    path
  end
```

---

### `test/mix/tasks/workflow_wiring_test.exs` (ExUnit YAML-grep contract test)

**Analog:** `lib/mix/tasks/verify.phase11.ex` §`validate_release_contract!/0` (L43-138) — same "grep a literal string inside a workflow file and fail if missing" shape, but runs inside ExUnit (fast, no `mix verify.phase11` ceremony).

**Why factor out a shared wiring test:** RESEARCH.md §`Wave 0 Gaps` centralizes all YAML-grep assertions (INFRA-01 cross-workflow + INFRA-03 pin grep + INFRA-04 scheduled wiring) into one test file, mirroring the `validate_release_contract!/0` structure but adapted to ExUnit instead of a Mix task.

**Shape pattern** (copy the `assert` loop structure; use `File.read!/1` + `String.contains?/2` instead of shelling out to grep — faster, no subprocess):
```elixir
defmodule Mix.Tasks.Verify.WorkflowWiringTest do
  use ExUnit.Case, async: true

  @ci_yml ".github/workflows/ci.yml"
  @publish_hex_yml ".github/workflows/publish-hex.yml"
  @release_please_yml ".github/workflows/release-please.yml"
  @verify_published_yml ".github/workflows/verify-published-release.yml"

  describe "INFRA-01: workspace_clean gate on all publish paths" do
    test "ci.yml quality job runs mix verify.workspace_clean" do
      assert File.read!(@ci_yml) =~ "mix verify.workspace_clean"
    end

    test "publish-hex.yml runs mix verify.workspace_clean" do
      assert File.read!(@publish_hex_yml) =~ "mix verify.workspace_clean"
    end

    test "release-please.yml publish-hex job runs mix verify.workspace_clean" do
      assert File.read!(@release_please_yml) =~ "mix verify.workspace_clean"
    end
  end

  describe "INFRA-02: release_parity step on scheduled monitor" do
    test "verify-published-release.yml runs mix verify.release_parity" do
      assert File.read!(@verify_published_yml) =~ "mix verify.release_parity"
    end
  end

  describe "INFRA-03: ci.yml action pins on Node 24 runtime" do
    test "ci.yml uses actions/checkout@v6 everywhere" do
      refute File.read!(@ci_yml) =~ "actions/checkout@v4"
      assert File.read!(@ci_yml) =~ "actions/checkout@v6"
    end

    test "ci.yml uses actions/cache@v5 everywhere" do
      refute File.read!(@ci_yml) =~ "actions/cache@v4"
      assert File.read!(@ci_yml) =~ "actions/cache@v5"
    end
  end

  describe "INFRA-04: scheduled drift-issue wiring" do
    test "create-an-issue step is guarded on failure() + schedule event" do
      yml = File.read!(@verify_published_yml)
      assert yml =~ "failure() && github.event_name == 'schedule'"
      assert yml =~ "JasonEtco/create-an-issue@v2"
      assert yml =~ "update_existing: true"
    end
  end

  describe "mix.exs cli.preferred_envs entries" do
    test "verify.workspace_clean is registered" do
      envs = Scrypath.MixProject.cli()[:preferred_envs]
      assert envs[:"verify.workspace_clean"] == :test
    end

    test "verify.release_parity is registered" do
      envs = Scrypath.MixProject.cli()[:preferred_envs]
      assert envs[:"verify.release_parity"] == :test
    end
  end
end
```

---

### `.github/ISSUE_TEMPLATE/release-parity-drift.md` (GitHub issue template)

**Analog:** No existing issue template in this repo (`.github/ISSUE_TEMPLATE/` directory does not exist yet — Bash verified).
**Source:** RESEARCH.md §`Pattern 6: Issue Template File` + CONTEXT.md §"Claude's Discretion" (labels: `area:release`, `severity:drift`; assignee: `szTheory`).

**Full template** (use verbatim from RESEARCH.md Pattern 6, with labels + assignee from CONTEXT.md):
```markdown
---
title: "Release parity drift detected: scrypath {{ env.VERSION }}"
labels: ["area:release", "severity:drift"]
assignees: szTheory
---

`mix verify.release_parity {{ env.VERSION }}` detected a divergence between
the published Hex tarball and the git tag of the same version.

- Workflow run: {{ env.GITHUB_SERVER_URL }}/{{ env.GITHUB_REPOSITORY }}/actions/runs/{{ env.GITHUB_RUN_ID }}
- Version: {{ env.VERSION }}

Expand the workflow logs for the exact `only_in_git` and `only_in_hex` file lists.

See `.planning/milestones/v1.2-MILESTONE-AUDIT.md` for background on why this gate exists.
```

---

### `mix.exs` (MODIFIED — add `cli.preferred_envs` entries)

**Analog:** existing block at `mix.exs:36-50` — self-referencing, same list, just two new atoms appended.

**Existing `cli/0` block** (for reference; planner must INSERT into this exact list):
```elixir
  def cli do
    [
      preferred_envs: [
        "verify.phase5": :test,
        "verify.phase8": :test,
        "verify.phase10": :test,
        "verify.phase11": :test,
        "verify.phase13": :test,
        "verify.phase14": :test,
        "verify.release_publish": :test,
        credo: :test,
        dialyzer: :test
      ]
    ]
  end
```

**Target (after edit):** insert two new entries after `"verify.release_publish": :test,` keeping the existing ordering convention (phase → release_publish → new parity tasks):
```elixir
        "verify.release_publish": :test,
        "verify.workspace_clean": :test,
        "verify.release_parity": :test,
```

---

### `.github/workflows/ci.yml` (MODIFIED — 5 pin swaps + 1 new step)

**Analog (pins):** `.github/workflows/release-please.yml:27` (`actions/checkout@v6`), `.github/workflows/verify-published-release.yml:23` (`actions/checkout@v6`) — already at target version, confirms the target pin literals.

**Analog (step insertion):** self — `.github/workflows/ci.yml:77-78` (existing `mix credo` step) for positional context.

**Pin-swap target lines** (exhaustive, by line number in current file):
- L29 `- uses: actions/checkout@v4` → `actions/checkout@v6`
- L36 `- uses: actions/cache@v4` → `actions/cache@v5`
- L56 `- uses: actions/checkout@v4` → `actions/checkout@v6`
- L63 `- uses: actions/cache@v4` → `actions/cache@v5`
- L114 `- uses: actions/checkout@v4` → `actions/checkout@v6`
- L121 `- uses: actions/cache@v4` → `actions/cache@v5`
- L161 `- uses: actions/checkout@v4` → `actions/checkout@v6`
- L168 `- uses: actions/cache@v4` → `actions/cache@v5`

Note: count is 8 total (4 checkout + 4 cache), not 5 as stated in some references; planner should sweep all `@v4` → target.

**New `workspace_clean` step** (D-15 position: after `mix format --check-formatted` at L74-75, before `mix credo` at L77-78):
```yaml
      - name: Check formatting
        run: mix format --check-formatted

      - name: Verify workspace is clean
        run: mix verify.workspace_clean

      - name: Run Credo
        run: mix credo
```

---

### `.github/workflows/release-please.yml` (MODIFIED — 1 new step in `publish-hex` job)

**Analog:** self — `.github/workflows/release-please.yml:48-71` (existing `publish-hex` job steps). Step insertion position: D-16 "immediately after tag checkout and before `mix verify.phase11`".

**Existing block for reference** (L48-71):
```yaml
    steps:
      - uses: actions/checkout@v6
        with:
          ref: ${{ needs.release-please.outputs.tag_name }}

      - uses: erlef/setup-beam@v1
        with:
          elixir-version: "1.19.0"
          otp-version: "28.1"

      - name: Install Hex
        run: mix local.hex --force

      - name: Install Rebar
        run: mix local.rebar --force

      - name: Install dependencies
        run: mix deps.get

      - name: Verify release version
        run: grep -n "@version \"${{ needs.release-please.outputs.version }}\"" mix.exs

      - name: Run release contract gate
        run: mix verify.phase11
```

**Target insertion** (D-16 puts it "immediately after tag checkout" — meaning after the initial `checkout` step. The task needs `mix` to be available, so in practice it must go after `erlef/setup-beam` + `Install Hex` + `Install dependencies`. Planner should position the new step RIGHT BEFORE the existing `Run release contract gate` step — same logical position as ci.yml's new step: lint-tier check before heavyweight verification):
```yaml
      - name: Install dependencies
        run: mix deps.get

      - name: Verify workspace is clean
        run: mix verify.workspace_clean

      - name: Verify release version
        run: grep -n "@version \"${{ needs.release-please.outputs.version }}\"" mix.exs

      - name: Run release contract gate
        run: mix verify.phase11
```

---

### `.github/workflows/publish-hex.yml` (MODIFIED — 1 new step, mirrors canonical path)

**Analog:** self — `.github/workflows/publish-hex.yml:22-45` (existing steps). D-17 mandates position parity with `release-please.yml`.

**Target insertion** (after `Install dependencies` at L41-42, before `Run release contract gate` at L44-45):
```yaml
      - name: Install dependencies
        run: mix deps.get

      - name: Verify workspace is clean
        run: mix verify.workspace_clean

      - name: Run release contract gate
        run: mix verify.phase11
```

---

### `.github/workflows/verify-published-release.yml` (MODIFIED — 1 new step + 1 guarded step)

**Analog:** self — L75-80 (existing `verify.release_publish` step) for shape; RESEARCH.md Pattern 5 for `create-an-issue` step.

**Existing `verify.release_publish` step for reference** (L75-80):
```yaml
      - name: Verify the latest published Scrypath release
        if: ${{ steps.resolve-version.outputs.published == 'true' }}
        env:
          SCRYPATH_RELEASE_VERIFY_ATTEMPTS: "10"
          SCRYPATH_RELEASE_VERIFY_SLEEP_MS: "15000"
        run: mix verify.release_publish "${{ steps.resolve-version.outputs.version }}"
```

**New `release_parity` step** (D-18; copy the exact `if:` guard and `env:` block from the analog above — inherits retry env vars per D-12):
```yaml
      - name: Verify release-parity against latest published version
        if: ${{ steps.resolve-version.outputs.published == 'true' }}
        env:
          SCRYPATH_RELEASE_VERIFY_ATTEMPTS: "10"
          SCRYPATH_RELEASE_VERIFY_SLEEP_MS: "15000"
        run: mix verify.release_parity "${{ steps.resolve-version.outputs.version }}"
```

**New `create-an-issue` step** (D-19; guarded on `failure() && github.event_name == 'schedule'` per Pattern 5 + anti-pattern "Don't file a new issue every daily run" mitigation `update_existing: true`):
```yaml
      - name: Open drift issue (scheduled runs only)
        if: ${{ failure() && github.event_name == 'schedule' && steps.resolve-version.outputs.published == 'true' }}
        uses: JasonEtco/create-an-issue@v2
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          VERSION: ${{ steps.resolve-version.outputs.version }}
        with:
          update_existing: true
          search_existing: open
          filename: .github/ISSUE_TEMPLATE/release-parity-drift.md
```

**Permissions addition** (RESEARCH.md Security §V4): the workflow's top-level `permissions:` block currently reads `contents: read`. For `create-an-issue@v2` to file/update issues, add `issues: write`:
```yaml
permissions:
  contents: read
  issues: write
```

---

### `docs/releasing.md` (MODIFIED — new "Release parity gate" section)

**Analog:** existing `docs/releasing.md` sections (content already ships via `mix.exs:82` `extras:` → HexDocs under "Maintainers" group).

**Content shape** (D-23 explains the two tasks + v1.2 backstory as historical note):
- New `## Release parity gate` section
- Subsection: what `mix verify.workspace_clean` catches (tag-vs-source drift at publish time)
- Subsection: what `mix verify.release_parity` catches (tarball-vs-tag drift after publish)
- Subsection: "Historical context" pointing to `.planning/milestones/v1.2-MILESTONE-AUDIT.md`

No concrete code to copy — prose content. Planner should match the tone and structure of existing sections in the same file.

---

### `CHANGELOG.md` (MODIFIED — unreleased entry)

**Analog:** existing `## Unreleased` section (RESEARCH.md L988 notes line 65).

**Content shape** (D-24):
- `### Added` bullet naming `mix verify.workspace_clean`
- `### Added` bullet naming `mix verify.release_parity`
- `### Changed` bullet noting Node 24 runtime (`actions/checkout@v6`, `actions/cache@v5`)
- `### Notes` bullet pointing at `.planning/milestones/v1.2-MILESTONE-AUDIT.md`

No concrete code to copy — markdown list format. Follow Keep-a-Changelog convention already in the file.

---

## Shared Patterns

### Shell-out idiom: `System.cmd/3` with `stderr_to_stdout: true`
**Source:** `lib/mix/tasks/verify.phase11.ex:153-162` + `lib/mix/tasks/verify.release_publish.ex:78-88, 124-128`
**Apply to:** Both new Mix tasks (workspace_clean, release_parity)

```elixir
    {output, exit_status} =
      System.cmd(command, args, stderr_to_stdout: true)

    Mix.shell().info(output)

    if exit_status != 0 do
      Mix.raise("#{label} failed")
    end
```

**Key rules (Pitfall 2):** `System.cmd/3` does NOT spawn a shell — pass args as list, no globs, no quoting. For git pathspecs, pass the literal strings from `mix.exs package.files` (bare names like `"lib"`, not `"lib/**"`).

---

### Argument guard: `ensure_no_args!/1`
**Source:** `lib/mix/tasks/verify.phase11.ex:164-168` + `lib/mix/tasks/verify.phase14.ex:30-34`
**Apply to:** `verify.workspace_clean` (takes no args); `verify.release_parity` takes exactly one version arg and one optional `--json` flag, so uses a different guard shape (see `parse_version!/1` in `verify.release_publish.ex:50-56`).

```elixir
  defp ensure_no_args!([]), do: :ok

  defp ensure_no_args!(args) do
    Mix.raise("verify.<task_name> does not accept arguments, got: #{Enum.join(args, " ")}")
  end
```

---

### Tmp-dir safety (unique naming + non-bang cleanup)
**Source:** `lib/mix/tasks/verify.release_publish.ex:92-119, 202-211` + `test/release/consumer_smoke_test.exs:142-151`
**Apply to:** `verify.release_parity` (file enumeration after tarball unpack) + any test that creates tmp state

- Create with `System.unique_integer([:positive])` suffix to avoid Pitfall 3 collision
- Cleanup via `after: File.rm_rf(tmp_root)` (NO bang — Pitfall 4)

---

### ExUnit Mix-task test idiom
**Source:** `test/scrypath/mix_tasks/operator_tasks_test.exs:1-4, 104-108, 185-189`
**Apply to:** Both new test files (workspace_clean + release_parity)

```elixir
use ExUnit.Case, async: false
import ExUnit.CaptureIO

capture_io(fn ->
  Mix.Task.reenable("verify.<task>")
  Mix.Task.run("verify.<task>", argv)
end)

assert_raise Mix.Error, ~r/.../, fn ->
  Mix.Task.reenable("verify.<task>")
  Mix.Task.run("verify.<task>", argv)
end
```

Note: `async: false` is mandatory because `Mix.Task.reenable/1` mutates global Mix task state.

---

### Subprocess integration-test idiom (for exit-code assertion without halting VM)
**Source:** `test/release/consumer_smoke_test.exs:124-140`
**Apply to:** `verify_release_parity_test.exs` exit-code branch (Pitfall 11 Option B)

```elixir
{output, exit_status} =
  System.cmd("mix", ["verify.<task>", arg],
    Keyword.merge([stderr_to_stdout: true], opts))

assert exit_status == expected,
       "command failed: mix verify.<task> #{arg}\n\n#{output}"
```

Tag with `@tag :integration` so it's excluded from the default suite (RESEARCH.md §`Test Framework`: `test/test_helper.exs:1` already excludes `:integration` unless `SCRYPATH_INTEGRATION` is set).

---

### Workflow step-insertion positioning
**Source:** `.github/workflows/ci.yml:74-78` + `.github/workflows/release-please.yml:48-71`
**Apply to:** All four workflow edits

- `workspace_clean` runs AFTER `mix deps.get` + setup-beam (needs `mix` available) but BEFORE heavier verification steps (`verify.phase11`, `credo`, etc.)
- `release_parity` runs AFTER `verify.release_publish` (sibling step, reuses same setup + env vars)

---

### Retry env-var inheritance
**Source:** `lib/mix/tasks/verify.release_publish.ex:14-23, 213-224`
**Apply to:** `verify.release_parity` (D-12)

Inherit verbatim — same variable names, same defaults, same `env_integer/2` parser:
- `SCRYPATH_RELEASE_VERIFY_ATTEMPTS` (default 10; workflows set to 10 or 20)
- `SCRYPATH_RELEASE_VERIFY_SLEEP_MS` (default 15_000)

---

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `.github/ISSUE_TEMPLATE/release-parity-drift.md` | GitHub issue template | static markdown + frontmatter | No issue-template infrastructure exists in the repo today (verified: `.github/ISSUE_TEMPLATE/` directory does not exist). Use RESEARCH.md Pattern 6 content verbatim, plus CONTEXT.md "Claude's Discretion" labels/assignee. |

---

## Metadata

**Analog search scope:** `lib/mix/tasks/**/*.ex`, `test/**/*.exs`, `.github/workflows/*.yml`, `.github/ISSUE_TEMPLATE/`, `mix.exs`, `docs/`, `CHANGELOG.md`
**Files scanned (read in full):** `verify.phase11.ex`, `verify.phase13.ex`, `verify.phase14.ex`, `verify.release_publish.ex`, `operator_tasks_test.exs`, `consumer_smoke_test.exs`, `mix.exs`, `ci.yml`, `release-please.yml`, `publish-hex.yml`, `verify-published-release.yml`, `18-CONTEXT.md`, `18-RESEARCH.md`
**Pattern extraction date:** 2026-04-17

---

*Phase: 18-release-parity-gate-node-20-ci-cleanup*
*Pattern map generated by gsd-pattern-mapper*
