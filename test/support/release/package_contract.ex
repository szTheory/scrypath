defmodule Scrypath.Release.PackageContract do
  @moduledoc false

  # Source of truth for what the Hex archive may contain.
  #
  # The checker reads the directory produced by a real `mix hex.build --unpack
  # --output <dir>`, never the source tree or the text of `files:`. It is fail-closed:
  #
  #   * L0 - every top-level entry must be in `@allowed_top_level`.
  #   * L1 - every `Mix.Tasks.*` module found by parsing packaged `lib/**/*.ex` must
  #     be one of `@public_tasks`, and every public task must be present.
  #
  # The module lives under test/support, so it is never packaged. `classify/2` is pure
  # (plain data in, `:ok | {:error, sorted_lines}` out); `check/1` is the thin I/O runner.
  #
  # Limit: the scan reads the AST, so task modules generated dynamically
  # (`Module.create/3`, unquoted names) are outside its view. The compiled-consumer
  # check in test/release/consumer_smoke_test.exs is the backstop for those.

  # Sorted by task name. Each path is where the task's source really lives, relative to
  # the package root; a drift-guard test compares this list to the repo's own lib/.
  @public_tasks [
    {"scrypath.failed", Mix.Tasks.Scrypath.Failed, "lib/mix/tasks/scrypath.failed.ex"},
    {"scrypath.index.contract_drift", Mix.Tasks.Scrypath.Index.ContractDrift,
     "lib/mix/tasks/scrypath/index/contract_drift.ex"},
    {"scrypath.reconcile", Mix.Tasks.Scrypath.Reconcile, "lib/mix/tasks/scrypath.reconcile.ex"},
    {"scrypath.retry", Mix.Tasks.Scrypath.Retry, "lib/mix/tasks/scrypath.retry.ex"},
    {"scrypath.settings.diff", Mix.Tasks.Scrypath.Settings.Diff,
     "lib/mix/tasks/scrypath.settings.diff.ex"},
    {"scrypath.settings.hot_apply", Mix.Tasks.Scrypath.Settings.HotApply,
     "lib/mix/tasks/scrypath.settings.hot_apply.ex"},
    {"scrypath.settings.read", Mix.Tasks.Scrypath.Settings.Read,
     "lib/mix/tasks/scrypath.settings.read.ex"},
    {"scrypath.status", Mix.Tasks.Scrypath.Status, "lib/mix/tasks/scrypath.status.ex"}
  ]

  # Mirrors the first path segments of package files: in mix.exs, plus the
  # hex_metadata.config file that `mix hex.build` writes. A drift-guard test pins it.
  @allowed_top_level ~w(.formatter.exs ARCHITECTURE.md CHANGELOG.md CONTRIBUTING.md LICENSE
                        README.md SECURITY.md docs guides hex_metadata.config lib mix.exs)

  @type task_entry :: {String.t(), module(), String.t()}

  @doc "Sorted names of the public operator tasks."
  @spec public_tasks() :: [String.t()]
  def public_tasks, do: Enum.map(@public_tasks, &elem(&1, 0))

  @doc "Sorted `{task_name, module, expected_path}` triples for the public operator tasks."
  @spec public_task_entries() :: [task_entry()]
  def public_task_entries, do: @public_tasks

  @doc "Top-level entries an unpacked Hex archive may hold."
  @spec allowed_top_level() :: [String.t()]
  def allowed_top_level, do: @allowed_top_level

  @doc """
  Checks an unpacked Hex archive directory against the contract.

  Returns `:ok` or `{:error, sorted_lines}`.
  """
  @spec check(Path.t()) :: :ok | {:error, [String.t()]}
  def check(unpacked_dir) do
    top_level = unpacked_dir |> File.ls!() |> Enum.sort()

    sources =
      unpacked_dir
      |> Path.join("lib/**/*.ex")
      |> Path.wildcard()
      |> Enum.sort()
      |> Enum.map(&{Path.relative_to(&1, unpacked_dir), File.read!(&1)})

    classify(top_level, collect_task_modules(sources))
  end

  @doc """
  Pure classifier over top-level entries and `{task_name, module, path}` triples.

  Each violation is one line: a tag, the subject, and a `fix:` hint. Lines are sorted.
  """
  @spec classify([String.t()], [task_entry()]) :: :ok | {:error, [String.t()]}
  def classify(top_level, task_modules) do
    forbidden =
      for entry <- top_level, entry not in @allowed_top_level do
        "[forbidden-path] #{entry} fix: remove it from package files: in mix.exs; " <>
          "maintainer tooling stays outside the Hex archive"
      end

    public_names = public_tasks()

    unexpected =
      for {name, module, path} <- task_modules, name not in public_names do
        "[unexpected-task] #{name} #{inspect(module)} #{path} fix: move the file to " <>
          "dev/mix/tasks/, or add the task to @public_tasks and document it in " <>
          "guides/operator-mix-tasks.md"
      end

    seen = MapSet.new(task_modules, &elem(&1, 0))

    missing =
      for {name, module, path} <- @public_tasks, not MapSet.member?(seen, name) do
        "[missing-task] #{name} #{inspect(module)} #{path} fix: restore #{path} " <>
          "(move it back from dev/mix/tasks/ if it was moved there), or remove the task " <>
          "from @public_tasks and from guides/operator-mix-tasks.md"
      end

    case Enum.sort(forbidden ++ unexpected ++ missing) do
      [] -> :ok
      violations -> {:error, violations}
    end
  end

  @doc """
  Finds `Mix.Tasks.*` modules defined in `{relative_path, source}` pairs.

  Sources are parsed with `Code.string_to_quoted!/1` and walked with a nested-aware
  `defmodule` resolver, so the result does not depend on the file path. Returns sorted
  `{task_name, module, path}` triples.
  """
  @spec collect_task_modules([{String.t(), String.t()}]) :: [task_entry()]
  def collect_task_modules(sources) do
    for {path, source} <- sources,
        module <- source |> Code.string_to_quoted!() |> defined_modules([]),
        String.starts_with?(Atom.to_string(module), "Elixir.Mix.Tasks.") do
      {Mix.Task.task_name(module), module, path}
    end
    |> Enum.sort()
  end

  # Walk the AST. A nested defmodule is prefixed by its enclosing module, exactly as the
  # compiler does, so `defmodule Mix.Tasks.X` inside `defmodule Foo` is Foo.Mix.Tasks.X.
  defp defined_modules({:defmodule, _, [name, [do: body]]}, parents) do
    case resolve_module(name, parents) do
      nil -> defined_modules(body, parents)
      full -> [full | defined_modules(body, [full | parents])]
    end
  end

  defp defined_modules({_, _, args}, parents) when is_list(args),
    do: Enum.flat_map(args, &defined_modules(&1, parents))

  defp defined_modules(list, parents) when is_list(list),
    do: Enum.flat_map(list, &defined_modules(&1, parents))

  defp defined_modules({left, right}, parents),
    do: defined_modules(left, parents) ++ defined_modules(right, parents)

  defp defined_modules(_other, _parents), do: []

  defp resolve_module({:__aliases__, _, [{:__MODULE__, _, _} | rest]}, [parent | _]),
    do: Module.concat([parent | rest])

  defp resolve_module({:__aliases__, _, parts}, []) do
    if Enum.all?(parts, &is_atom/1), do: Module.concat(parts)
  end

  defp resolve_module({:__aliases__, _, parts}, [parent | _]) do
    if Enum.all?(parts, &is_atom/1), do: Module.concat([parent | parts])
  end

  defp resolve_module(_other, _parents), do: nil
end
