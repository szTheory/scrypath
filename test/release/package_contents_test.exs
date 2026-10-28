defmodule Scrypath.Release.PackageContentsTest do
  use ExUnit.Case, async: false

  alias Scrypath.MixProject

  describe "tooling boundary" do
    test "maintainer verifiers live outside lib and outside the Hex package" do
      project = MixProject.project()

      # Files only: git leaves empty directories behind after the move, and an
      # empty directory is not a verifier.
      verify_files =
        ["lib/mix/tasks/verify*", "lib/mix/tasks/verify*/**"]
        |> Enum.flat_map(&Path.wildcard/1)
        |> Enum.reject(&File.dir?/1)

      assert verify_files == [],
             "a verify* file is back under lib/mix/tasks; maintainer verifiers belong in dev/mix/tasks: #{inspect(verify_files)}"

      assert File.dir?("dev/mix/tasks"),
             "dev/mix/tasks is missing; the maintainer task tree must live there"

      assert "dev/mix/tasks" in project[:elixirc_paths],
             "dev/mix/tasks is not in the :test elixirc_paths; verifiers would not compile for maintainers"

      refute "dev" in project[:package][:files],
             "dev is listed in package files:; maintainer verifiers would ship in the Hex tarball"
    end
  end
end
