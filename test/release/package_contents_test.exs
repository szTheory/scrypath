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

  describe "packaged docs" do
    test "no ExDoc extra and no packaged lib file names a Mix.Tasks.Verify module" do
      # CHANGELOG.md is not an extra and is excluded on purpose: it is release-please-owned
      # history (D-19).
      extras =
        MixProject.project()[:docs][:extras]
        |> Enum.map(fn
          {path, _opts} -> path
          path -> path
        end)

      files = extras ++ Path.wildcard("lib/**/*.ex")

      assert files != [], "the packaged-docs scan found no files; the guard went vacuous"

      offenders =
        Enum.filter(files, fn path -> String.contains?(File.read!(path), "Mix.Tasks.Verify") end)

      assert offenders == [],
             "Mix.Tasks.Verify is named in packaged docs or lib (verifiers compile only under :test, so the :dev docs build and HexDocs would carry dangling references): #{inspect(offenders)}"
    end
  end

  # Both describes below run a real `mix hex.build --unpack` on a tmp copy of the packaged
  # files. Every subprocess gets an explicit MIX_ENV and an isolated MIX_BUILD_PATH, because
  # preferred_envs routing sets Mix.env() in this VM only and never exports MIX_ENV.
  # HEX_OFFLINE keeps the suite network-free and credential-free. The tmp dir comes from
  # System.tmp_dir!/0 (not the :tmp_dir tag, which would leave tmp/ behind in the checkout).
  describe "real archive" do
    setup :tmp_workspace

    test "control: the unmutated package returns :ok", %{tmp: tmp} do
      src = copy_packaged_files!(tmp)

      assert build_and_check!(src, tmp) == :ok
    end

    test "a repository-only scrypath.* task in lib is unexpected", %{tmp: tmp} do
      src = copy_packaged_files!(tmp)

      File.write!(
        Path.join(src, "lib/mix/tasks/scrypath.repo_only.ex"),
        task_source("Scrypath.RepoOnly")
      )

      assert build_and_check!(src, tmp) ==
               {:error,
                [
                  "[unexpected-task] scrypath.repo_only Mix.Tasks.Scrypath.RepoOnly lib/mix/tasks/scrypath.repo_only.ex fix: move the file to dev/mix/tasks/, or add the task to @public_tasks and document it in guides/operator-mix-tasks.md"
                ]}
    end

    test "a verify.* task in lib is unexpected", %{tmp: tmp} do
      src = copy_packaged_files!(tmp)
      File.write!(Path.join(src, "lib/mix/tasks/verify.sneaky.ex"), task_source("Verify.Sneaky"))

      assert build_and_check!(src, tmp) ==
               {:error,
                [
                  "[unexpected-task] verify.sneaky Mix.Tasks.Verify.Sneaky lib/mix/tasks/verify.sneaky.ex fix: move the file to dev/mix/tasks/, or add the task to @public_tasks and document it in guides/operator-mix-tasks.md"
                ]}
    end

    test "a task module hidden in an ordinary lib file is unexpected", %{tmp: tmp} do
      src = copy_packaged_files!(tmp)
      [first | _] = "lib/scrypath/*.ex" |> Path.wildcard() |> Enum.sort()
      File.write!(Path.join(src, first), "\n" <> task_source("Verify.Hidden"), [:append])

      assert build_and_check!(src, tmp) ==
               {:error,
                [
                  "[unexpected-task] verify.hidden Mix.Tasks.Verify.Hidden #{first} fix: move the file to dev/mix/tasks/, or add the task to @public_tasks and document it in guides/operator-mix-tasks.md"
                ]}
    end

    test "dev listed in package files is a forbidden path", %{tmp: tmp} do
      src = copy_packaged_files!(tmp)
      mix_exs = Path.join(src, "mix.exs")
      original = File.read!(mix_exs)
      mutated = String.replace(original, "~w(lib ", "~w(dev lib ", global: false)

      # A no-op replacement would make this test pass without proving anything.
      refute mutated == original
      File.write!(mix_exs, mutated)
      File.mkdir_p!(Path.join(src, "dev/mix/tasks"))
      File.write!(Path.join(src, "dev/mix/tasks/verify.probe.ex"), task_source("Verify.Probe"))

      assert build_and_check!(src, tmp) ==
               {:error,
                [
                  "[forbidden-path] dev fix: remove it from package files: in mix.exs; maintainer tooling stays outside the Hex archive"
                ]}
    end

    test "a deleted public task is one missing-task line", %{tmp: tmp} do
      src = copy_packaged_files!(tmp)
      File.rm!(Path.join(src, "lib/mix/tasks/scrypath.status.ex"))

      assert {:error, [line]} = build_and_check!(src, tmp)

      assert line ==
               "[missing-task] scrypath.status Mix.Tasks.Scrypath.Status lib/mix/tasks/scrypath.status.ex fix: restore lib/mix/tasks/scrypath.status.ex (move it back from dev/mix/tasks/ if it was moved there), or remove the task from @public_tasks and from guides/operator-mix-tasks.md"

      assert line =~ "dev/mix/tasks/"
      assert line =~ "guides/operator-mix-tasks.md"
    end
  end

  describe "unpacked archive compiles without the dev tree" do
    setup :tmp_workspace

    test "MIX_ENV=prod compiles warning-free with exactly the public task beams", %{tmp: tmp} do
      archive = build_control_archive!(tmp)
      build = Path.join(tmp, "build_prod")

      compile_archive!(archive, "prod", build)

      assert_public_task_beams!(build)
    end

    test "MIX_ENV=test compiles warning-free with exactly the public task beams", %{tmp: tmp} do
      archive = build_control_archive!(tmp)
      build = Path.join(tmp, "build_test")

      # Reuse the already-compiled dependencies of this checkout so the test build stays
      # offline; only scrypath itself is compiled from the unpacked archive.
      deps_lib = Path.join(Mix.Project.build_path(), "lib")
      File.mkdir_p!(Path.join(build, "lib"))

      for dep <- File.ls!(deps_lib), dep != "scrypath" do
        File.cp_r!(Path.join(deps_lib, dep), Path.join([build, "lib", dep]))
      end

      compile_archive!(archive, "test", build)

      assert_public_task_beams!(build)
    end
  end

  defp tmp_workspace(_context) do
    tmp =
      Path.join(
        System.tmp_dir!(),
        "scrypath-package-contents-#{System.unique_integer([:positive])}"
      )

    File.mkdir_p!(tmp)
    on_exit(fn -> File.rm_rf!(tmp) end)

    %{tmp: tmp}
  end

  # Copies exactly the entries mix.exs lists in package files:, so the copy cannot drift.
  defp copy_packaged_files!(tmp) do
    src = Path.join(tmp, "src")
    File.mkdir_p!(src)

    for entry <- MixProject.project()[:package][:files] do
      dest = Path.join(src, entry)
      File.mkdir_p!(Path.dirname(dest))
      File.cp_r!(Path.join(File.cwd!(), entry), dest)
    end

    src
  end

  defp build_archive!(src, tmp) do
    out = Path.join(tmp, "out")

    {output, status} =
      System.cmd("mix", ["hex.build", "--unpack", "--output", out],
        cd: src,
        stderr_to_stdout: true,
        env: [
          {"MIX_ENV", "test"},
          {"MIX_BUILD_PATH", Path.join(tmp, "build_hex")},
          {"HEX_OFFLINE", "1"}
        ]
      )

    assert status == 0, "mix hex.build failed:\n" <> output

    out
  end

  defp build_and_check!(src, tmp) do
    src |> build_archive!(tmp) |> PackageContract.check()
  end

  defp build_control_archive!(tmp) do
    archive = tmp |> copy_packaged_files!() |> build_archive!(tmp)

    refute File.exists?(Path.join(archive, "dev")),
           "the unpacked archive must not contain a dev/ tree"

    File.cp!("mix.lock", Path.join(archive, "mix.lock"))

    archive
  end

  # Dependencies compile in a separate step so third-party compiler warnings (for example
  # from Oban in :prod) cannot be mistaken for warnings in the packaged scrypath sources.
  defp compile_archive!(archive, mix_env, build) do
    env = [
      {"MIX_ENV", mix_env},
      {"MIX_BUILD_PATH", build},
      {"MIX_DEPS_PATH", Path.expand(Mix.Project.deps_path())},
      {"HEX_OFFLINE", "1"}
    ]

    # The :test build reuses this checkout's compiled dependencies; :prod has none yet.
    if mix_env == "prod" do
      {deps_output, deps_status} =
        System.cmd("mix", ["deps.compile"], cd: archive, stderr_to_stdout: true, env: env)

      assert deps_status == 0, "MIX_ENV=#{mix_env} deps.compile failed:\n" <> deps_output
    end

    {output, status} =
      System.cmd("mix", ["compile", "--warnings-as-errors"],
        cd: archive,
        stderr_to_stdout: true,
        env: env
      )

    assert status == 0, "MIX_ENV=#{mix_env} compile of the unpacked archive failed:\n" <> output

    assert output =~ "Generated scrypath app",
           "scrypath was not compiled from the archive:\n" <> output

    refute output =~ "warning:", "MIX_ENV=#{mix_env} compile printed a warning:\n" <> output
  end

  defp assert_public_task_beams!(build) do
    ebin = Path.join(build, "lib/scrypath/ebin")

    beams =
      ebin
      |> File.ls!()
      |> Enum.filter(
        &(String.starts_with?(&1, "Elixir.Mix.Tasks.") and String.ends_with?(&1, ".beam"))
      )
      |> Enum.sort()

    expected =
      PackageContract.public_task_entries()
      |> Enum.map(fn {_name, module, _path} -> "#{module}.beam" end)
      |> Enum.sort()

    assert beams == expected
    assert length(beams) == 8
    refute Enum.any?(beams, &String.starts_with?(&1, "Elixir.Mix.Tasks.Verify"))
  end

  defp task_source(suffix) do
    """
    defmodule Mix.Tasks.#{suffix} do
      use Mix.Task

      @shortdoc "Fixture task injected by the package contents gate test"

      @impl true
      def run(_args), do: :ok
    end
    """
  end
end
