# test_helper.exs requires test/support files in path order, and this one sorts before
# package_contract.ex and shipped_docs.ex; requiring them here (a no-op once loaded) keeps the
# compile warning-free under --warnings-as-errors.
Code.require_file("package_contract.ex", __DIR__)
Code.require_file("shipped_docs.ex", __DIR__)

defmodule Scrypath.Release.InstallLine do
  @moduledoc false

  # GUARD-02 (Phase 193): every install line the shipped docs and the website build script print
  # for Scrypath names the same release series as the `mix.exs` version. It is a test-only helper
  # under test/support, so it is never packaged.
  #
  #   * The version is read from `Scrypath.MixProject.project()[:version]` on every run, so a
  #     Release Please bump cannot leave a stale line behind: the contract test goes red instead.
  #   * Satisfying the requirement is not enough on its own (`~> 0.2` is satisfied by 0.3.20, and
  #     `~> 0.3` by 0.4.0), so before 1.0.0 a requirement must also equal the same-length prefix of
  #     the version's `[major, minor, patch]`, and `Version.match?/2` must hold. From 1.0.0 on the
  #     breaking axis is the major, so only the major must match (`~> 1.0` is right at every 1.x
  #     release) and `Version.match?/2` decides the rest.
  #   * The scanned files are the files of the mix.exs package `files:` (through
  #     `ShippedDocs.shipped_files/0`), minus the release history (`ShippedDocs.history_files/0`:
  #     CHANGELOG.md, which records what a release said at the time and so may quote an old
  #     tuple), plus the website sources. The website page source holds only the
  #     `{{CANONICAL_INSTALL}}` slot; the literal lives in `website/scripts/build.mjs`, so that
  #     file is read too.
  #   * The only non-numeric requirement allowed is a named placeholder: an exact `{path,
  #     requirement}` key with a reason and a revisit trigger. Any other unparseable requirement
  #     fails. Nothing is skipped silently.
  #   * `occurrences/1`, `check/2` and `problems/3` are pure (in-memory strings in, tuples out), so
  #     the planted cases in test/release/install_line_contract_test.exs never edit a shipped file.
  #
  # Not covered: prose that names a series without an install tuple (the golden path says which
  # minor series its range matches), and the website's rendered install block.

  alias Scrypath.Release.ShippedDocs

  # `{:scrypath, "<requirement>"}` with any whitespace, also with trailing options
  # (`{:scrypath, "~> 0.3", only: :dev}`), which would otherwise slip past the guard.
  @install_pattern ~r/\{:scrypath,\s*"([^"]*)"\s*[,}]/

  # A requirement this guard can judge: `~>` and dot-separated integers.
  @requirement ~r/\A~>\s*(\d+(?:\.\d+)*)\z/

  # The website source holds only a slot; the install literal is in the build script.
  @website_sources ["website/scripts/build.mjs", "website/src/**/*.html"]

  # Exactly one named placeholder. Each records a reason and a revisit trigger; the contract test
  # fails if a field is empty or the key stops occurring.
  @placeholders %{
    {"docs/releasing.md", "~> X.Y.Z"} => %{
      reason:
        "A template line in the post-publish verification description, filled in per release by " <>
          "the publish task. It is not an adopter install line.",
      revisit:
        "Revisit when the line is removed, or when the publish verification stops naming a " <>
          "template requirement."
    }
  }

  @type occurrence :: {Path.t(), pos_integer(), String.t()}
  @type kind :: :unsupported | :series_mismatch | :unsatisfied
  @type problem :: {Path.t(), pos_integer(), String.t(), kind()}

  @doc "The `mix.exs` version the install lines are checked against."
  @spec version() :: String.t()
  def version, do: Scrypath.MixProject.project()[:version]

  @doc "The named placeholder entries, keyed by `{path, requirement}`."
  @spec placeholders() :: %{{Path.t(), String.t()} => %{reason: String.t(), revisit: String.t()}}
  def placeholders, do: @placeholders

  @doc """
  Sorted paths scanned: the shipped files, minus the release history, plus the website sources
  that exist.
  """
  @spec sources() :: [Path.t()]
  def sources do
    website =
      for glob <- @website_sources, path <- Path.wildcard(glob), File.regular?(path), do: path

    (ShippedDocs.without_history(ShippedDocs.shipped_files()) ++ website)
    |> Enum.uniq()
    |> Enum.sort()
  end

  @doc """
  `{path, line, requirement}` for each install tuple in the `{path, text}` pairs. `line` is the
  1-based line the tuple starts on.
  """
  @spec occurrences([{Path.t(), String.t()}]) :: [occurrence()]
  def occurrences(files) do
    for {path, text} <- files,
        [{start, _length}, {from, size}] <- Regex.scan(@install_pattern, text, return: :index),
        do: {path, newlines(binary_part(text, 0, start)) + 1, binary_part(text, from, size)}
  end

  @doc """
  `:ok`, or `{:error, kind}` for one requirement against a version.

    * `:unsupported`: not `~>` plus dot-separated integers, or not a requirement Elixir accepts;
    * `:series_mismatch`: before 1.0.0, the requirement's numbers differ from the same-length
      prefix of the version's `[major, minor, patch]`; from 1.0.0 on, its first number differs
      from the version's major;
    * `:unsatisfied`: the version does not satisfy the requirement.
  """
  @spec check(String.t(), String.t()) :: :ok | {:error, kind()}
  def check(requirement, version) do
    case Regex.run(@requirement, requirement, capture: :all_but_first) do
      [numbers] -> check_numbers(requirement, numbers, version)
      nil -> {:error, :unsupported}
    end
  end

  defp check_numbers(requirement, numbers, version) do
    parsed = Version.parse!(version)
    wanted = numbers |> String.split(".") |> Enum.map(&String.to_integer/1)

    cond do
      Version.parse_requirement(requirement) == :error -> {:error, :unsupported}
      not same_series?(wanted, parsed) -> {:error, :series_mismatch}
      not Version.match?(version, requirement) -> {:error, :unsatisfied}
      true -> :ok
    end
  end

  # Before 1.0.0 the minor is the breaking axis, so `~> 0.3` is the right line and must equal the
  # same-length prefix of `[major, minor, patch]`. From 1.0.0 on the breaking axis is the major:
  # `~> 1.0` is the right line at every 1.x release, so only the major is compared and
  # `Version.match?/2` decides the rest.
  defp same_series?([major | _], %Version{major: major}) when major >= 1, do: true
  defp same_series?(_wanted, %Version{major: major}) when major >= 1, do: false

  defp same_series?(wanted, parsed) do
    wanted == Enum.take([parsed.major, parsed.minor, parsed.patch], length(wanted))
  end

  @doc """
  Sorted `{path, line, requirement, kind}` for every occurrence that fails `check/2` and is not
  an exact `{path, requirement}` key of `placeholders`. A placeholder requirement at any other
  path fails as `:unsupported`.
  """
  @spec problems([{Path.t(), String.t()}], String.t(), map()) :: [problem()]
  def problems(files, version, placeholders) do
    problems =
      for {path, line, requirement} <- occurrences(files),
          not Map.has_key?(placeholders, {path, requirement}),
          {:error, kind} <- [check(requirement, version)],
          do: {path, line, requirement, kind}

    Enum.sort(problems)
  end

  @doc "Scan of the real shipped files and website sources against the `mix.exs` version."
  @spec violations() :: [problem()]
  def violations do
    files = for path <- sources(), do: {path, File.read!(path)}
    problems(files, version(), @placeholders)
  end

  defp newlines(text), do: text |> :binary.matches("\n") |> length()
end
