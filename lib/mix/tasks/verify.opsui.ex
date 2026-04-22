defmodule Mix.Tasks.Verify.Opsui do
  use Mix.Task

  @shortdoc "Runs ScrypathOps (`scrypath_ops`) tests the same way the scrypath-ops CI job does"

  @moduledoc """
  Runs the `scrypath_ops` application tests the same way the **`scrypath-ops`** GitHub Actions job does.

  Use this from the **repository root** when you change the optional operator Phoenix app under
  **`scrypath_ops/`**, the core library under **`lib/`**, root **`mix.exs`**, **`mix.lock`**, or
  **`scrypath_ops/mix.lock`** (mirroring the path gate described for that CI job in
  [CONTRIBUTING.md](CONTRIBUTING.md)).

  The task runs **`cd scrypath_ops`**, then **`mix deps.get`**, then **`mix test`** with **`CI=true`**.
  The shell script pipes **`printf 'n\\n'`** into **`mix deps.get`** so a workstation TTY cannot block on
  Hex re-auth prompts—the same non-interactive shape as CI.

  Expect Postgres-backed Ecto tests for **`scrypath_ops`**; there is **no** Meilisearch service on this path.

  This task does not accept arguments. For the full CI ↔ **`mix verify.*`** matrix and job names, see
  [CONTRIBUTING.md](CONTRIBUTING.md).
  """

  @impl true
  def run(args) do
    Mix.Task.run("app.start")
    ensure_no_args!(args)

    ops_dir = Path.expand("scrypath_ops", File.cwd!())

    unless File.dir?(ops_dir) do
      Mix.raise("verify.opsui: expected #{ops_dir} to exist")
    end

    # CI mirrors GitHub Actions (non-interactive). `printf` answers "n" if Hex ever
    # prompts for re-auth on a workstation TTY — same commands as `.github/workflows/ci.yml`.
    Mix.shell().info("==> verify.opsui: cd scrypath_ops && mix deps.get && mix test")

    script = "export CI=true; printf 'n\\n' | mix deps.get && mix test"

    {out, status} =
      System.cmd("bash", ["-lc", script], cd: ops_dir, stderr_to_stdout: true)

    Mix.shell().info(out)

    if status != 0 do
      Mix.raise("verify.opsui failed: `#{script}` (in #{ops_dir}) exited #{status}")
    end
  end

  defp ensure_no_args!([]), do: :ok

  defp ensure_no_args!(args) do
    Mix.raise("verify.opsui does not accept arguments, got: #{Enum.join(args, " ")}")
  end
end
