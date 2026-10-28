defmodule Scrypath.Release.ConsumerSmokeTest do
  use ExUnit.Case, async: false

  alias Scrypath.MixProject
  alias Scrypath.Release.PackageContract

  setup_all do
    version = MixProject.project()[:version]
    tag = "v#{version}"
    repo_root = File.cwd!()
    tmp_root = unique_tmp_dir!()
    artifact_dir = Path.join(tmp_root, "scrypath-artifact")
    app_dir = Path.join(tmp_root, "consumer_usage")
    # Anonymous Hex/Mix state so a stale developer HEX_TOKEN never blocks `mix deps.get`
    # on stdin ("authenticate now?") — CI is unaffected; local runs stay deterministic.
    hex_home = Path.join(tmp_root, "hex_home")
    mix_home = Path.join(tmp_root, "mix_home")
    File.mkdir_p!(hex_home)
    File.mkdir_p!(mix_home)
    isolated_env = [{"HEX_HOME", hex_home}, {"MIX_HOME", mix_home}, {"MIX_ENV", "dev"}]

    on_exit(fn -> File.rm_rf(tmp_root) end)

    build_packaged_artifact!(repo_root, artifact_dir)

    # Ordering is load-bearing: the allowlist check must see the directory exactly as
    # `hex.build --unpack` produced it. Once this test initializes the artifact as a
    # repository, a top-level `.git` exists, which the check would report as a false
    # violation created by this test.
    # The result is captured, not asserted here, so a failure is reported against a test.
    package_contract_result = PackageContract.check(artifact_dir)

    artifact_paths = artifact_paths!(artifact_dir)

    artifact_git_url =
      artifact_dir
      |> init_artifact_git_repo!(tag)
      |> then(&"file://#{&1}")

    run_mix!(["new", "consumer_usage", "--module", "ConsumerUsage"], cd: tmp_root)
    File.write!(Path.join(app_dir, "mix.exs"), consumer_mix_exs(artifact_git_url, tag))
    write_consumer_schema!(app_dir)

    run_mix!(["deps.get"], cd: app_dir, env: isolated_env)
    run_mix!(["compile"], cd: app_dir, env: isolated_env)

    %{
      tag: tag,
      tmp_root: tmp_root,
      artifact_dir: artifact_dir,
      artifact_git_url: artifact_git_url,
      artifact_paths: artifact_paths,
      app_dir: app_dir,
      isolated_env: isolated_env,
      package_contract_result: package_contract_result
    }
  end

  test "a clean consumer app compiles the documented use Scrypath path", ctx do
    %{
      tag: tag,
      artifact_paths: artifact_paths,
      artifact_git_url: artifact_git_url,
      app_dir: app_dir,
      package_contract_result: package_contract_result
    } = ctx

    assert Enum.any?(artifact_paths, &String.starts_with?(&1, "lib/"))
    assert "mix.exs" in artifact_paths
    assert "README.md" in artifact_paths
    assert "CHANGELOG.md" in artifact_paths
    assert Enum.any?(artifact_paths, &String.starts_with?(&1, "guides/"))
    assert "docs/releasing.md" in artifact_paths

    assert package_contract_result == :ok,
           """
           the real hex.build archive violates the package contract (allowlist, L0):

           #{format_violations(package_contract_result)}
           """

    consumer_mix = File.read!(Path.join(app_dir, "mix.exs"))

    assert consumer_mix =~ ~s|{:scrypath, git: "#{artifact_git_url}", tag: "#{tag}"}|
    refute Regex.match?(~r/path\s*:/, consumer_mix)

    assert File.exists?(
             Path.join(
               app_dir,
               "_build/dev/lib/consumer_usage/ebin/Elixir.ConsumerUsage.Post.beam"
             )
           )
  end

  test "the installed package exposes only the public operator tasks", ctx do
    %{app_dir: app_dir, isolated_env: isolated_env} = ctx

    public_tasks = PackageContract.public_tasks()
    ebin = Path.join(app_dir, "_build/dev/lib/scrypath/ebin")

    # The compiled dependency holds Mix.Tasks beams, and none of them is a maintainer task.
    task_beams = ebin |> Path.join("Elixir.Mix.Tasks.*.beam") |> Path.wildcard()
    assert task_beams != [], "no Mix.Tasks beams found in #{ebin}"

    verify_beams =
      task_beams
      |> Enum.map(&Path.basename/1)
      |> Enum.filter(&String.starts_with?(&1, "Elixir.Mix.Tasks.Verify"))

    refute verify_beams != [],
           "the consumer compiled maintainer task beams: #{Enum.join(verify_beams, ", ")}"

    # The module list recorded in scrypath.app is the ground truth for the task surface,
    # however a task module was defined (this backstops the AST scan in PackageContract).
    {:ok, [{:application, :scrypath, app_spec}]} =
      :file.consult(String.to_charlist(Path.join(ebin, "scrypath.app")))

    app_task_names =
      app_spec
      |> Keyword.fetch!(:modules)
      |> Enum.filter(&String.starts_with?(Atom.to_string(&1), "Elixir.Mix.Tasks."))
      |> Enum.map(&Mix.Task.task_name/1)
      |> Enum.sort()

    assert app_task_names == public_tasks

    # A maintainer task name does not resolve in the adopter's project.
    {package_output, package_status} = run_consumer("mix", ["verify.package"], ctx)

    assert package_status != 0,
           "verify.package unexpectedly ran in the consumer:\n#{package_output}"

    assert package_output =~ ~s|The task "verify.package" could not be found|,
           "unexpected verify.package output:\n#{package_output}"

    # A public operator task resolves and reaches its own usage path without a backend.
    {status_output, status_status} = run_consumer("mix", ["scrypath.status"], ctx)

    assert status_status == 1, "mix scrypath.status exited #{status_status}:\n#{status_output}"

    assert status_output =~ "expected one schema module argument",
           "unexpected scrypath.status output:\n#{status_output}"

    # Every public task documents itself through the consumer's own `mix help`.
    for task <- public_tasks do
      {help_output, help_status} = run_consumer("mix", ["help", task], ctx)

      assert help_status == 0, "mix help #{task} exited #{help_status}:\n#{help_output}"
      assert String.trim(help_output) != "", "mix help #{task} printed nothing"

      assert help_output =~ task,
             "mix help #{task} output does not mention the task:\n#{help_output}"
    end

    assert length(public_tasks) == 8

    # Inside the consumer VM every public task resolves, has a shortdoc and exports run/1.
    probe = """
    names = "SCRYPATH_PUBLIC_TASKS" |> System.fetch_env!() |> String.split(",")

    failures =
      for name <- names,
          reason = (
            case Mix.Task.get(name) do
              nil ->
                :not_found

              mod ->
                Code.ensure_loaded(mod)

                cond do
                  Mix.Task.shortdoc(mod) in [nil, ""] -> :no_shortdoc
                  not function_exported?(mod, :run, 1) -> :no_run_1
                  true -> nil
                end
            end
          ),
          do: {name, reason}

    if failures == [] do
      IO.puts("public-tasks-ok")
    else
      IO.inspect(failures, label: "public-task-failures")
      System.halt(1)
    end
    """

    probe_ctx = %{
      ctx
      | isolated_env: [{"SCRYPATH_PUBLIC_TASKS", Enum.join(public_tasks, ",")} | isolated_env]
    }

    {probe_output, probe_status} =
      run_consumer("mix", ["run", "--no-start", "-e", probe], probe_ctx)

    assert probe_status == 0, "consumer VM probe failed:\n#{probe_output}"
    assert probe_output =~ "public-tasks-ok", "consumer VM probe output:\n#{probe_output}"
  end

  test "the smoke dependency stays release-like and never falls back to path deps" do
    version = MixProject.project()[:version]
    tag = "v#{version}"

    mix_exs = consumer_mix_exs("file:///tmp/scrypath-artifact", tag)
    schema = consumer_schema()

    assert mix_exs =~ ~s|{:scrypath, git: "file:///tmp/scrypath-artifact", tag: "#{tag}"}|
    refute Regex.match?(~r/path\s*:/, mix_exs)
    assert schema =~ "use Scrypath"
  end

  defp consumer_mix_exs(artifact_git_url, tag) do
    """
    defmodule ConsumerUsage.MixProject do
      use Mix.Project

      def project do
        [
          app: :consumer_usage,
          version: "0.1.0",
          elixir: "~> 1.17",
          start_permanent: Mix.env() == :prod,
          deps: deps()
        ]
      end

      def application do
        [extra_applications: [:logger]]
      end

      defp deps do
        [
          {:ecto, "~> 3.13"},
          {:scrypath, git: "#{artifact_git_url}", tag: "#{tag}"}
        ]
      end
    end
    """
  end

  defp consumer_schema do
    """
    defmodule ConsumerUsage.Post do
      use Ecto.Schema

      use Scrypath,
        fields: [:title, :body],
        filterable: [:status],
        sortable: [:inserted_at]

      schema "posts" do
        field :title, :string
        field :body, :string
        field :status, Ecto.Enum, values: [:draft, :published]
        timestamps()
      end
    end
    """
  end

  defp write_consumer_schema!(app_dir) do
    schema_dir = Path.join(app_dir, "lib/consumer_usage")
    File.mkdir_p!(schema_dir)
    File.write!(Path.join(schema_dir, "post.ex"), consumer_schema())
  end

  defp build_packaged_artifact!(repo_root, artifact_dir) do
    run_mix!(["hex.build", "--unpack", "--output", artifact_dir], cd: repo_root)
  end

  defp init_artifact_git_repo!(artifact_dir, tag) do
    run_command!("git", ["init", "-q"], cd: artifact_dir)
    run_command!("git", ["config", "user.email", "codex@example.com"], cd: artifact_dir)
    run_command!("git", ["config", "user.name", "Codex"], cd: artifact_dir)
    run_command!("git", ["add", "."], cd: artifact_dir)
    run_command!("git", ["commit", "-qm", "artifact"], cd: artifact_dir)
    run_command!("git", ["tag", tag], cd: artifact_dir)
    artifact_dir
  end

  # Runs a subprocess inside the consumer with the isolated Hex/Mix env and returns
  # `{output, exit_status}` without asserting success.
  defp run_consumer(command, args, %{app_dir: app_dir, isolated_env: isolated_env}) do
    System.cmd(command, args, cd: app_dir, env: isolated_env, stderr_to_stdout: true)
  end

  defp format_violations(:ok), do: "(none)"
  defp format_violations({:error, lines}), do: Enum.join(lines, "\n")

  defp run_mix!(args, opts) do
    run_command!("mix", args, opts)
  end

  defp run_command!(command, args, opts) do
    cmd_opts =
      opts
      |> Keyword.take([:cd, :env])
      |> Keyword.put(:stderr_to_stdout, true)

    {output, exit_status} = System.cmd(command, args, cmd_opts)

    assert exit_status == 0,
           """
           command failed: #{command} #{Enum.join(args, " ")}

           #{output}
           """

    output
  end

  defp unique_tmp_dir! do
    path =
      Path.join(
        System.tmp_dir!(),
        "scrypath-consumer-smoke-#{System.unique_integer([:positive])}"
      )

    File.mkdir_p!(path)
    path
  end

  defp artifact_paths!(artifact_dir) do
    artifact_dir
    |> Path.join("**")
    |> Path.wildcard(match_dot: true)
    |> Enum.map(&Path.relative_to(&1, artifact_dir))
    |> Enum.reject(
      &(&1 in [".", ".git"] or String.starts_with?(&1, ".git/") or String.ends_with?(&1, "/"))
    )
    |> Enum.sort()
  end
end
