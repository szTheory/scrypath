defmodule Mix.Tasks.Verify.Opsui do
  @moduledoc false
  use Mix.Task

  @shortdoc "Runs ScrypathOps (`scrypath_ops`) tests the same way the scrypath-ops CI job does"

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
