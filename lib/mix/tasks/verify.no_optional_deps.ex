defmodule Mix.Tasks.Verify.NoOptionalDeps do
  @moduledoc """
  Compiles the root library without optional dependencies and treats warnings as errors.
  """
  use Mix.Task

  @shortdoc "Compiles the root library without optional dependencies"

  @impl true
  def run(args) do
    ensure_no_args!(args)

    Mix.shell().info("==> Compiling Scrypath without optional dependencies (warnings are errors)")

    # A custom Mix task is loaded after Mix has already considered compilation.
    # Run an isolated compiler command so --no-optional-deps is always applied
    # to a fresh root-library compile rather than becoming a no-op.
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

  defp ensure_no_args!([]), do: :ok

  defp ensure_no_args!(args) do
    Mix.raise("verify.no_optional_deps does not accept arguments, got: #{Enum.join(args, " ")}")
  end

  defp mix_executable! do
    System.find_executable("mix") ||
      Mix.raise("verify.no_optional_deps could not find the mix executable")
  end
end
