defmodule Mix.Tasks.Verify.Phase11 do
  use Mix.Task

  @shortdoc "Runs the automated Phase 11 release-alignment flow"

  @moduledoc """
  Runs the automated release-alignment verification flow for Phase 11.

  This task keeps the existing auth-free release gate shape and extends it with
  checks that the package version, packaged consumer path, Release Please
  manifest, and publish workflow still describe the same tagged release path.
  """

  @impl true
  def run(args) do
    Mix.Task.run("app.start")
    ensure_no_args!(args)

    run_test!(
      [
        "test/release/package_metadata_test.exs",
        "test/release/consumer_smoke_test.exs",
        "test/scrypath/docs_contract_test.exs"
      ],
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
      ["-nF", "config-file: release-please-config.json", ".github/workflows/release-please.yml"],
      "release workflow config-file validation"
    )

    run_system_command!(
      "grep",
      [
        "-nF",
        "manifest-file: .release-please-manifest.json",
        ".github/workflows/release-please.yml"
      ],
      "release workflow manifest-file validation"
    )

    run_system_command!(
      "grep",
      [
        "-nF",
        "if: ${{ needs.release-please.outputs.release_created == 'true' }}",
        ".github/workflows/release-please.yml"
      ],
      "publish job release_created guard validation"
    )

    run_system_command!(
      "grep",
      [
        "-nF",
        "ref: ${{ needs.release-please.outputs.tag_name }}",
        ".github/workflows/release-please.yml"
      ],
      "publish job tag checkout validation"
    )

    run_system_command!(
      "grep",
      [
        "-nF",
        "run: grep -n \"@version \\\"${{ needs.release-please.outputs.version }}\\\"\" mix.exs",
        ".github/workflows/release-please.yml"
      ],
      "publish job version validation"
    )

    run_system_command!(
      "grep",
      ["-nF", "run: mix verify.phase11", ".github/workflows/release-please.yml"],
      "publish job release gate validation"
    )

    run_system_command!(
      "grep",
      ["-nF", "run: mix hex.publish --dry-run --yes", ".github/workflows/release-please.yml"],
      "publish job dry-run validation"
    )

    run_system_command!(
      "grep",
      ["-nF", "run: mix hex.publish --yes", ".github/workflows/release-please.yml"],
      "publish job hex publish validation"
    )

    run_system_command!(
      "grep",
      [
        "-nF",
        "run: mix verify.release_publish \"${{ needs.release-please.outputs.version }}\"",
        ".github/workflows/release-please.yml"
      ],
      "publish job post-publish verification validation"
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
