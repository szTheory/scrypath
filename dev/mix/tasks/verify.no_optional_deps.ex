defmodule Mix.Tasks.Verify.NoOptionalDeps do
  @moduledoc """
  Compiles the root library without optional dependencies and treats warnings as errors.

  The compile runs in an isolated build directory (`MIX_BUILD_PATH`) under
  `MIX_ENV=prod`, and the task checks afterwards that no optional dependency
  reached that build, so a green run proves the library compiled without them.
  """
  use Mix.Task

  @shortdoc "Compiles the root library without optional dependencies"

  # Defined only when Oban.Worker is loadable at compile time.
  @oban_only_beam "lib/scrypath/ebin/Elixir.Scrypath.Oban.UpsertWorker.beam"

  @impl true
  def run(args) do
    ensure_no_args!(args)

    Mix.shell().info("==> Compiling Scrypath without optional dependencies (warnings are errors)")

    build_path = isolated_build_path()
    optional_deps = optional_deps()

    # Defensive: never let a cached optional dep build survive into this check.
    Enum.each(optional_deps, fn dep ->
      File.rm_rf!(Path.join([build_path, "lib", to_string(dep)]))
    end)

    # A custom Mix task is loaded after Mix has already considered compilation,
    # so run a separate compiler command. It uses its own MIX_BUILD_PATH: a
    # prebuilt _build/<env>/lib/oban would otherwise stay on the code path and
    # --no-optional-deps would compile against Oban anyway.
    {output, status} =
      System.cmd(
        mix_executable!(),
        ["compile", "--force", "--no-optional-deps", "--warnings-as-errors"],
        env: compile_env(build_path),
        stderr_to_stdout: true
      )

    Mix.shell().info(output)

    if status != 0 do
      Mix.raise("root compile without optional dependencies failed")
    end

    assert_optional_deps_absent!(build_path, optional_deps)

    Mix.shell().info(
      "==> Verified optional dependencies absent from isolated build: " <>
        Enum.map_join(optional_deps, ", ", &to_string/1)
    )
  end

  @doc """
  Returns the isolated build directory used for the no-optional-deps compile.

  Exposed publicly for testability.
  """
  @spec isolated_build_path() :: String.t()
  def isolated_build_path do
    Path.join(Path.dirname(Mix.Project.build_path()), "no_optional_deps")
  end

  @doc """
  Returns the environment for the isolated compile. `prod` matches what an
  adopter's dependency compile sees and leaves out test-only deps.

  Exposed publicly for testability.
  """
  @spec compile_env(String.t()) :: [{String.t(), String.t()}]
  def compile_env(build_path) do
    [{"MIX_ENV", "prod"}, {"MIX_BUILD_PATH", build_path}]
  end

  @doc """
  Returns the names of the optional dependencies declared in `mix.exs`.

  Exposed publicly for testability.
  """
  @spec optional_deps() :: [atom()]
  def optional_deps do
    Mix.Project.config()
    |> Keyword.get(:deps, [])
    |> Enum.flat_map(fn
      {name, opts} when is_list(opts) -> optional_name(name, opts)
      {name, _requirement, opts} when is_list(opts) -> optional_name(name, opts)
      _other -> []
    end)
  end

  @doc """
  Raises `Mix.Error` if any optional dependency, or code that is compiled only
  when Oban is loadable, is present in `build_path`.

  Exposed publicly for testability.
  """
  @spec assert_optional_deps_absent!(String.t(), [atom()]) :: :ok
  def assert_optional_deps_absent!(build_path, optional_deps) do
    dep_paths = Enum.map(optional_deps, &Path.join([build_path, "lib", to_string(&1)]))
    candidates = dep_paths ++ [Path.join(build_path, @oban_only_beam)]

    case Enum.find(candidates, &File.exists?/1) do
      nil ->
        :ok

      path ->
        Mix.raise(
          "verify.no_optional_deps found #{path} in the isolated build: Oban was on the " <>
            "code path, so the compile proved nothing about builds without optional dependencies"
        )
    end
  end

  defp optional_name(name, opts) do
    if Keyword.get(opts, :optional, false), do: [name], else: []
  end

  defp ensure_no_args!([]), do: :ok

  defp ensure_no_args!(args) do
    Mix.raise("verify.no_optional_deps does not accept arguments, got: #{Enum.join(args, " ")}")
  end

  defp mix_executable! do
    System.find_executable("mix") ||
      Mix.raise("verify.no_optional_deps could not find the mix executable")
  end
end
