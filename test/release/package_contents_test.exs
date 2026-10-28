defmodule Scrypath.Release.PackageContentsTest do
  use ExUnit.Case, async: false

  alias Scrypath.MixProject
  alias Scrypath.Release.PackageContract

  describe "classifier" do
    test "the allowlist and the public task entries classify clean" do
      assert PackageContract.classify(
               PackageContract.allowed_top_level(),
               PackageContract.public_task_entries()
             ) == :ok

      assert length(PackageContract.public_tasks()) == 8
    end

    test "an extra top-level entry is a forbidden path" do
      assert PackageContract.classify(
               PackageContract.allowed_top_level() ++ ["dev"],
               PackageContract.public_task_entries()
             ) ==
               {:error,
                [
                  "[forbidden-path] dev fix: remove it from package files: in mix.exs; maintainer tooling stays outside the Hex archive"
                ]}
    end

    test "an unlisted task is unexpected and the hint names both remedies" do
      entry =
        {"scrypath.repo_only", Mix.Tasks.Scrypath.RepoOnly, "lib/mix/tasks/scrypath.repo_only.ex"}

      assert {:error, [line]} =
               PackageContract.classify(
                 PackageContract.allowed_top_level(),
                 [entry | PackageContract.public_task_entries()]
               )

      assert line ==
               "[unexpected-task] scrypath.repo_only Mix.Tasks.Scrypath.RepoOnly lib/mix/tasks/scrypath.repo_only.ex fix: move the file to dev/mix/tasks/, or add the task to @public_tasks and document it in guides/operator-mix-tasks.md"
    end

    test "a dropped public task is one missing-task line carrying module, path and both remedies" do
      entries =
        Enum.reject(PackageContract.public_task_entries(), &(elem(&1, 0) == "scrypath.status"))

      assert PackageContract.classify(PackageContract.allowed_top_level(), entries) ==
               {:error,
                [
                  "[missing-task] scrypath.status Mix.Tasks.Scrypath.Status lib/mix/tasks/scrypath.status.ex fix: restore lib/mix/tasks/scrypath.status.ex (move it back from dev/mix/tasks/ if it was moved there), or remove the task from @public_tasks and from guides/operator-mix-tasks.md"
                ]}
    end

    test "several violations yield one sorted line each" do
      entries =
        PackageContract.public_task_entries()
        |> Enum.reject(&(elem(&1, 0) == "scrypath.status"))
        |> Kernel.++([
          {"verify.sneaky", Mix.Tasks.Verify.Sneaky, "lib/mix/tasks/verify.sneaky.ex"},
          {"scrypath.repo_only", Mix.Tasks.Scrypath.RepoOnly,
           "lib/mix/tasks/scrypath.repo_only.ex"}
        ])

      assert {:error, lines} =
               PackageContract.classify(
                 PackageContract.allowed_top_level() ++ ["dev", "aaa"],
                 entries
               )

      assert lines == Enum.sort(lines)

      assert Enum.map(lines, &(&1 |> String.split(" ") |> Enum.take(2) |> Enum.join(" "))) == [
               "[forbidden-path] aaa",
               "[forbidden-path] dev",
               "[missing-task] scrypath.status",
               "[unexpected-task] scrypath.repo_only",
               "[unexpected-task] verify.sneaky"
             ]
    end

    test "collect_task_modules finds a top-level task module in any file path" do
      sources = [
        {"lib/scrypath/ordinary.ex",
         """
         defmodule Scrypath.Ordinary do
           def ok, do: :ok
         end

         defmodule Mix.Tasks.Verify.Hidden do
           use Mix.Task
           def run(_), do: :ok
         end
         """}
      ]

      assert PackageContract.collect_task_modules(sources) == [
               {"verify.hidden", Mix.Tasks.Verify.Hidden, "lib/scrypath/ordinary.ex"}
             ]
    end

    test "collect_task_modules maps nested task names through Mix.Task.task_name/1" do
      sources = [
        {"lib/mix/tasks/scrypath.settings.hot_apply.ex",
         """
         defmodule Mix.Tasks.Scrypath.Settings.HotApply do
           use Mix.Task
           def run(_), do: :ok
         end
         """}
      ]

      assert PackageContract.collect_task_modules(sources) == [
               {"scrypath.settings.hot_apply", Mix.Tasks.Scrypath.Settings.HotApply,
                "lib/mix/tasks/scrypath.settings.hot_apply.ex"}
             ]
    end

    test "collect_task_modules ignores a task-looking module nested in a non-task module" do
      sources = [
        {"lib/scrypath/holder.ex",
         """
         defmodule Scrypath.HiddenHolder do
           defmodule Mix.Tasks.Verify.Hidden do
             def run(_), do: :ok
           end
         end
         """}
      ]

      assert PackageContract.collect_task_modules(sources) == []
    end

    test "collect_task_modules resolves relative and __MODULE__ nested names" do
      sources = [
        {"lib/mix/tasks/outer.ex",
         """
         defmodule Mix.Tasks.Scrypath.Outer do
           defmodule Inner do
             def x, do: :x
           end

           defmodule __MODULE__.Other do
             def y, do: :y
           end
         end
         """}
      ]

      assert sources
             |> PackageContract.collect_task_modules()
             |> Enum.map(&elem(&1, 0))
             |> Enum.sort() ==
               ["scrypath.outer", "scrypath.outer.inner", "scrypath.outer.other"]
    end
  end

  describe "drift guards" do
    test "allowed_top_level mirrors the first segments of package files plus hex_metadata.config" do
      first_segments =
        MixProject.project()[:package][:files]
        |> Enum.map(&(&1 |> Path.split() |> hd()))
        |> MapSet.new()

      allowed = MapSet.new(PackageContract.allowed_top_level() -- ["hex_metadata.config"])

      assert allowed == first_segments
      assert "hex_metadata.config" in PackageContract.allowed_top_level()
    end

    test "public_task_entries equals the Mix.Tasks modules statically found in lib" do
      sources =
        "lib/**/*.ex"
        |> Path.wildcard()
        |> Enum.map(&{&1, File.read!(&1)})

      found = sources |> PackageContract.collect_task_modules() |> Enum.sort()

      assert PackageContract.public_task_entries() == found
      assert PackageContract.public_tasks() == Enum.map(found, &elem(&1, 0))
    end

    test "every public task is documented as `mix <name>` in a docs extra" do
      extras =
        MixProject.project()[:docs][:extras]
        |> Enum.map(fn
          {path, _opts} -> path
          path -> path
        end)

      docs = Enum.map_join(extras, "\n", &File.read!/1)

      undocumented =
        Enum.reject(PackageContract.public_tasks(), &String.contains?(docs, "mix #{&1}"))

      assert undocumented == [],
             "public tasks missing from the packaged docs extras: #{inspect(undocumented)}"
    end
  end

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
