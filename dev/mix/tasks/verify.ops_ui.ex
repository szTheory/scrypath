defmodule Mix.Tasks.Verify.OpsUi do
  use Mix.Task

  @shortdoc "Runs canonical ScrypathOps verification"

  @boundary_test "test/release/ops_dependency_boundary_test.exs"

  @moduledoc """
  Runs the `scrypath_ops` application tests the same way the path-scoped
  **`ops-ui`** GitHub Actions job does.

  Use this from the **repository root** when you change the optional operator Phoenix app under
  **`scrypath_ops/`**, the core library under **`lib/`**, root **`mix.exs`**, **`mix.lock`**, or
  **`scrypath_ops/mix.lock`** (mirroring the path gate described for that CI job in
  [CONTRIBUTING.md](CONTRIBUTING.md)).

  The task runs **`cd scrypath_ops`**, then **`mix deps.get`**, then **`mix test`** with **`CI=true`**.
  The shell script pipes **`printf 'n\\n'`** into **`mix deps.get`** so a workstation TTY cannot block on
  Hex re-auth prompts—the same non-interactive shape as CI.

  Expect Postgres-backed Ecto tests for **`scrypath_ops`**; there is **no** Meilisearch service on this path.

  This task does not accept arguments. For the full CI ↔ **`mix verify.*`**
  matrix and job names, see [CONTRIBUTING.md](CONTRIBUTING.md).
  """

  @impl true
  def run(args) do
    Mix.Task.run("app.start")
    ensure_no_args!(args)

    root = File.cwd!()

    scratch =
      Path.join(physical_tmp_dir!(), "scrypath-ops-ui-#{System.unique_integer([:positive])}")

    File.mkdir_p!(scratch)

    try do
      execute_verification!(verification_commands(root), root, scratch)
    after
      File.rm_rf(scratch)
    end
  end

  @doc false
  def verification_commands(root) do
    mix = System.find_executable("mix") || "mix"
    ops_dir = Path.expand("scrypath_ops", root)

    [
      {mix, ["test", @boundary_test, "--warnings-as-errors"], root, [{"MIX_ENV", "test"}]},
      {mix, ["local.hex", "--force"], ops_dir, [{"CI", "true"}, {"MIX_ENV", "dev"}]},
      {mix, ["deps.get"], ops_dir, [{"CI", "true"}, {"MIX_ENV", "dev"}]},
      {mix, ["test"], ops_dir, [{"CI", "true"}, {"MIX_ENV", "test"}]}
    ]
  end

  defp execute_verification!(commands, root, scratch) do
    ops_dir = Path.expand("scrypath_ops", root)

    commands
    |> Enum.with_index()
    |> Enum.each(fn {{executable, args, cd, env}, index} ->
      env = if cd == ops_dir, do: ops_environment(env, scratch), else: env
      command = Enum.join([executable | args], " ")

      Mix.shell().info("==> verify.ops_ui: #{command} (in #{cd})")

      {output, status} = System.cmd(executable, args, cd: cd, env: env, stderr_to_stdout: true)
      Mix.shell().info(output)

      if status != 0 do
        Mix.raise(
          "verify.ops_ui step #{index + 1} failed: `#{command}` (in #{cd}) exited #{status}"
        )
      end
    end)
  end

  defp ops_environment(env, scratch) do
    env ++
      [
        {"MIX_BUILD_PATH", Path.join(scratch, "build")},
        {"MIX_DEPS_PATH", Path.join(scratch, "deps")},
        {"MIX_HOME", Path.join(scratch, "mix")},
        {"HEX_HOME", Path.join(scratch, "hex")}
      ]
  end

  defp physical_tmp_dir! do
    {path, 0} = System.cmd("pwd", ["-P"], cd: System.tmp_dir!())
    String.trim(path)
  end

  defp ensure_no_args!([]), do: :ok

  defp ensure_no_args!(args) do
    Mix.raise("verify.ops_ui does not accept arguments, got: #{Enum.join(args, " ")}")
  end
end
