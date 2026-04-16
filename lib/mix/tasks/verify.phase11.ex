defmodule Mix.Tasks.Verify.Phase11 do
  use Mix.Task

  @shortdoc "Runs the automated Phase 11 release-alignment flow"

  @moduledoc """
  Runs the automated release-alignment verification flow for Phase 11.

  This task keeps the existing auth-free release gate shape and extends it with
  checks that the package version, Release Please manifest, and publish workflow
  still describe the same tagged release path.
  """

  @release_contract_pattern "release_created|tag_name|mix hex.publish --yes|manifest-file|config-file|release-type"
  @release_contract_paths [
    ".github/workflows/release-please.yml",
    "release-please-config.json",
    ".release-please-manifest.json"
  ]

  @impl true
  def run(args) do
    Mix.Task.run("app.start")
    ensure_no_args!(args)

    run_test!(
      ["test/release/package_metadata_test.exs", "test/scrypath/docs_contract_test.exs"],
      "Phase 11 release contract tests"
    )

    Mix.shell().info("==> Building docs with warnings as errors")
    Mix.Task.reenable("docs")
    Mix.Task.run("docs", ["--warnings-as-errors"])

    validate_release_contract!()

    run_command!(["hex.build", "--unpack"], "Building and unpacking Hex package")
  end

  defp run_test!(args, label) do
    Mix.shell().info("==> Running #{label}")
    Mix.Task.reenable("test")
    Mix.Task.run("test", args)
  end

  defp validate_release_contract! do
    Mix.shell().info("==> Validating release workflow contract")

    run_system_command!(
      "grep",
      ["-nE", @release_contract_pattern | @release_contract_paths],
      "release workflow contract validation"
    )

    run_system_command!(
      "sh",
      [
        "-c",
        ~S"""
        VERSION=$(grep -m1 '@version "' mix.exs | sed -E 's/.*"([^"]+)".*/\1/')
        MANIFEST_VERSION=$(grep -m1 '"\."' .release-please-manifest.json | sed -E 's/.*"([^"]+)".*/\1/')
        test "$VERSION" = "$MANIFEST_VERSION"
        """
      ],
      "release-please-manifest version alignment"
    )

    run_system_command!(
      "grep",
      ["-n", ~S(@source_ref "v#{@version}"), "mix.exs"],
      "source_ref version anchor validation"
    )
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

  defp run_system_command!(command, args, label) do
    {output, exit_status} =
      System.cmd(command, args, stderr_to_stdout: true)

    Mix.shell().info(output)

    if exit_status != 0 do
      Mix.raise("#{label} failed")
    end
  end

  defp ensure_no_args!([]), do: :ok

  defp ensure_no_args!(args) do
    Mix.raise("verify.phase11 does not accept arguments, got: #{Enum.join(args, " ")}")
  end
end
