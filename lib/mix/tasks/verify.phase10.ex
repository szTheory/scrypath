defmodule Mix.Tasks.Verify.Phase10 do
  use Mix.Task

  @shortdoc "Runs release-confidence checks (metadata, docs, workflows, hex build unpack)"

  @moduledoc """
  Runs the auth-free release-confidence verification flow.

  This task mirrors the current auth-free release gate:

  - focused package metadata and release-doc contract tests
  - `mix docs --warnings-as-errors`
  - release workflow/config validation
  - `mix hex.build --unpack`

  It intentionally excludes publish credentials, tagging, and release creation.
  """

  @release_config_pattern "release-please|manifest-file|config-file|release-type"
  @release_config_paths [
    ".github/workflows/release-please.yml",
    "release-please-config.json",
    ".release-please-manifest.json"
  ]

  @impl true
  def run(args) do
    Mix.Task.run("app.start")
    ensure_no_args!(args)

    run_test!(
      ["test/release/package_metadata_test.exs"],
      "Release-confidence tests"
    )

    Mix.shell().info("==> Building docs with warnings as errors")
    Mix.Task.reenable("docs")
    Mix.Task.run("docs", ["--warnings-as-errors"])

    validate_release_config!()

    run_command!(["hex.build", "--unpack"], "Building and unpacking Hex package")
  end

  defp run_test!(args, label) do
    Mix.shell().info("==> Running #{label}")
    Mix.Task.reenable("test")
    Mix.Task.run("test", args)
  end

  defp validate_release_config! do
    Mix.shell().info("==> Validating release workflow config")

    {output, exit_status} =
      System.cmd("grep", ["-nE", @release_config_pattern | @release_config_paths],
        stderr_to_stdout: true
      )

    Mix.shell().info(output)

    if exit_status != 0 do
      Mix.raise("release workflow config validation failed")
    end
  end

  defp run_command!(args, label) do
    Mix.shell().info("==> #{label}")

    {output, exit_status} =
      System.cmd("mix", args, stderr_to_stdout: true)

    Mix.shell().info(output)

    if exit_status != 0 do
      Mix.raise("#{label} failed")
    end
  end

  defp ensure_no_args!([]), do: :ok

  defp ensure_no_args!(args) do
    Mix.raise("verify.phase10 does not accept arguments, got: #{Enum.join(args, " ")}")
  end
end
