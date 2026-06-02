defmodule Mix.Tasks.Verify.Phase11 do
  use Mix.Task

  @shortdoc "Runs the release-alignment gate (package, consumer, docs, Release Please wiring)"

  @moduledoc """
  Runs the automated release-alignment verification flow.

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
      "Release contract tests"
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

    release_sources = release_sources!()

    case validate_release_agreement(release_sources) do
      :ok ->
        :ok

      {:error, messages} ->
        Mix.raise("release agreement check failed:\n- " <> Enum.join(messages, "\n- "))
    end
  end

  def validate_release_agreement(%{
        mix_version: mix_version,
        source_ref: source_ref,
        manifest_version: manifest_version,
        release_type: release_type,
        include_v_in_tag: include_v_in_tag,
        top_changelog_version: top_changelog_version
      }) do
    []
    |> maybe_add_mismatch(
      mix_version != manifest_version,
      "mix.exs version=#{mix_version} does not match .release-please-manifest.json version=#{manifest_version}"
    )
    |> maybe_add_mismatch(
      source_ref != "v#{mix_version}",
      "mix.exs source_ref=#{source_ref} does not match expected v#{mix_version}"
    )
    |> maybe_add_mismatch(
      release_type != "elixir",
      "release-please-config.json release-type=#{inspect(release_type)} is not \"elixir\""
    )
    |> maybe_add_mismatch(
      include_v_in_tag != true,
      "release-please-config.json packages[\".\"].include-v-in-tag=#{inspect(include_v_in_tag)} is not true"
    )
    |> maybe_add_mismatch(
      top_changelog_version != mix_version,
      "CHANGELOG.md top release heading version=#{inspect(top_changelog_version)} does not match mix.exs version=#{mix_version}"
    )
    |> case do
      [] -> :ok
      messages -> {:error, messages}
    end
  end

  defp maybe_add_mismatch(messages, true, message), do: [message | messages]
  defp maybe_add_mismatch(messages, false, _message), do: messages

  defp release_sources! do
    # Mix.Project.config/0 (not Scrypath.MixProject.project/0) so Dialyzer can resolve the
    # call — mix.exs is not part of Dialyzer's analyzed beam set.
    project = Mix.Project.config()
    manifest = File.read!(".release-please-manifest.json") |> Jason.decode!()
    release_config = File.read!("release-please-config.json") |> Jason.decode!()

    %{
      mix_version: project[:version],
      source_ref: project[:source_ref],
      manifest_version: manifest["."],
      release_type: release_config["release-type"],
      include_v_in_tag: get_in(release_config, ["packages", ".", "include-v-in-tag"]),
      top_changelog_version: top_changelog_version!()
    }
  end

  defp top_changelog_version! do
    changelog = File.read!("CHANGELOG.md")

    case Regex.run(~r/^## \[(\d+\.\d+\.\d+)\]/m, changelog, capture: :all_but_first) do
      [version] -> version
      _ -> nil
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
