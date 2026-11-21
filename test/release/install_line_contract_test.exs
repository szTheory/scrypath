defmodule Scrypath.Release.InstallLineContractTest do
  # Deliberately untagged: a version bump that leaves an install line on another series fails the
  # default `mix test` and the `core` lane. It reads files only (no network, no docs build).
  #
  # This file proves the guard can fail and can pass. The planted cases are in-memory strings
  # only; no shipped file is edited to prove a check. It also holds the real-file zero assertion
  # and the floors that keep the scan from going vacuous.
  use ExUnit.Case, async: true

  alias Scrypath.Release.InstallLine

  @guide "guides/planted.md"

  defp line(requirement), do: ~s({:scrypath, "#{requirement}"})

  describe "the real files" do
    test "every install line in the shipped files and the website matches the mix.exs version series" do
      problems = InstallLine.violations()

      assert problems == [],
             "#{length(problems)} install line(s) are not on the series of mix.exs " <>
               "#{InstallLine.version()}:\n" <>
               Enum.map_join(problems, "\n", fn {path, line, requirement, kind} ->
                 "  #{path}:#{line} #{requirement} (#{kind})"
               end)
    end

    test "the scan reads the shipped install lines and the website build script" do
      files = for path <- InstallLine.sources(), do: {path, File.read!(path)}
      found = InstallLine.occurrences(files)
      numeric = for {path, _line, requirement} <- found, requirement =~ ~r/\d/, do: path

      assert length(numeric) >= 4,
             "the install-line scan went vacuous: #{length(numeric)} numeric occurrences"

      assert "README.md" in numeric
      assert "guides/golden-path.md" in numeric

      if File.dir?("website") do
        website =
          for {path, _line, _requirement} <- found,
              String.starts_with?(path, "website/"),
              do: path

        assert "website/scripts/build.mjs" in website,
               "the website build script no longer yields an install line"
      end
    end

    test "each placeholder records a reason and a revisit trigger and still occurs" do
      files = for path <- InstallLine.sources(), do: {path, File.read!(path)}

      keys =
        for {path, _line, requirement} <- InstallLine.occurrences(files), do: {path, requirement}

      assert map_size(InstallLine.placeholders()) == 1,
             "the placeholder set changed; add a reason and a revisit trigger for each entry"

      for {{path, requirement} = key, entry} <- InstallLine.placeholders() do
        assert key in keys,
               "the placeholder #{requirement} no longer occurs in #{path}; remove it"

        assert String.trim(entry.reason) != "", "the placeholder #{requirement} has no reason"
        assert String.trim(entry.revisit) != "", "the placeholder #{requirement} has no revisit"
      end
    end
  end

  describe "planted cases (in-memory strings only)" do
    test "an install line from an older series fails" do
      assert InstallLine.check("~> 0.2", "0.3.20") == {:error, :series_mismatch}
      assert InstallLine.check("~> 0.3.19", "0.3.20") == {:error, :series_mismatch}

      assert [{@guide, 1, "~> 0.2", :series_mismatch}] =
               InstallLine.problems([{@guide, line("~> 0.2") <> "\n"}], "0.3.20", %{})
    end

    test "the current series fails after a minor bump" do
      assert InstallLine.check("~> 0.3", "0.4.0") == {:error, :series_mismatch}

      assert [{@guide, 1, "~> 0.3", :series_mismatch}] =
               InstallLine.problems([{@guide, line("~> 0.3") <> "\n"}], "0.4.0", %{})
    end

    test "the series and the exact patch requirement pass" do
      assert InstallLine.check("~> 0.3", "0.3.20") == :ok
      assert InstallLine.check("~> 0.3.20", "0.3.20") == :ok
      assert InstallLine.problems([{@guide, line("~> 0.3") <> "\n"}], "0.3.20", %{}) == []
    end

    # WR-03 (Phase 193 review): the same-length-prefix rule is the 0.x convention, where the minor is
    # the breaking axis. From 1.0.0 on the breaking axis is the major, `~> 1.0` is the right line at
    # every 1.x release, and the guard must not send the maintainer to edit it.
    test "from 1.0.0 on a requirement names the major and Version.match?/2 decides the rest" do
      # The right line at every 1.x release.
      assert InstallLine.check("~> 1.0", "1.2.3") == :ok
      assert InstallLine.check("~> 1.0", "1.0.5") == :ok
      assert InstallLine.check("~> 1.2", "1.2.3") == :ok
      assert InstallLine.check("~> 1.2.3", "1.2.3") == :ok

      assert InstallLine.problems([{@guide, line("~> 1.0") <> "\n"}], "1.2.3", %{}) == []

      # An older major, or the 0.x line, is stale at 1.x.
      assert InstallLine.check("~> 0.2", "1.2.3") == {:error, :series_mismatch}
      assert InstallLine.check("~> 0.3", "1.0.0") == {:error, :series_mismatch}

      assert [{@guide, 1, "~> 0.3", :series_mismatch}] =
               InstallLine.problems([{@guide, line("~> 0.3") <> "\n"}], "1.0.0", %{})

      # The current series is stale after a major bump.
      assert InstallLine.check("~> 1.0", "2.0.0") == {:error, :series_mismatch}

      # Same major, but the version cannot satisfy the requirement.
      assert InstallLine.check("~> 1.3", "1.2.3") == {:error, :unsatisfied}
      assert InstallLine.check("~> 1.0.0", "1.2.3") == {:error, :unsatisfied}

      # The 0.x rule is unchanged.
      assert InstallLine.check("~> 0.3", "0.3.20") == :ok
      assert InstallLine.check("~> 0.2", "0.3.20") == {:error, :series_mismatch}
      assert InstallLine.check("~> 0.3", "0.4.0") == {:error, :series_mismatch}
    end

    test "a pre-release version does not satisfy its own series requirement" do
      assert InstallLine.check("~> 0.4", "0.4.0-rc.1") == {:error, :unsatisfied}
    end

    test "a placeholder passes only at its named path" do
      placeholders = InstallLine.placeholders()
      template = line("~> X.Y.Z") <> "\n"

      assert InstallLine.problems([{"docs/releasing.md", template}], "0.3.20", placeholders) == []

      assert [{@guide, 1, "~> X.Y.Z", :unsupported}] =
               InstallLine.problems([{@guide, template}], "0.3.20", placeholders)

      assert [{"docs/releasing.md", 1, "~> X.Y.Z", :unsupported}] =
               InstallLine.problems([{"docs/releasing.md", template}], "0.3.20", %{})
    end

    test "an unsupported requirement form fails" do
      assert InstallLine.check(">= 0.3.0", "0.3.20") == {:error, :unsupported}
      assert InstallLine.check("0.3.20", "0.3.20") == {:error, :unsupported}
      assert InstallLine.check("~> 0", "0.3.20") == {:error, :unsupported}
      assert InstallLine.check("~> 0.3.20.1", "0.3.20") == {:error, :unsupported}

      text = line(">= 0.3.0") <> "\n" <> line("0.3.20") <> "\n"

      assert [
               {@guide, 1, ">= 0.3.0", :unsupported},
               {@guide, 2, "0.3.20", :unsupported}
             ] = InstallLine.problems([{@guide, text}], "0.3.20", %{})
    end

    test "an install line with options and any spacing is still read" do
      text = ~s({:scrypath,"~> 0.2", only: :dev}\n{:scrypath,   "~> 0.3"   }\n)

      assert InstallLine.occurrences([{@guide, text}]) ==
               [{@guide, 1, "~> 0.2"}, {@guide, 2, "~> 0.3"}]
    end

    test "the scan reports the line of each install line" do
      text = "# Planted\n\nAdd #{line("~> 0.2")} to deps.\n"

      assert InstallLine.occurrences([{@guide, text}]) == [{@guide, 3, "~> 0.2"}]

      assert [{@guide, 3, "~> 0.2", :series_mismatch}] =
               InstallLine.problems([{@guide, text}], "0.3.20", %{})
    end
  end
end
