defmodule Scrypath.Release.ConsumerSmokeTest do
  use ExUnit.Case, async: false

  alias Scrypath.MixProject

  test "a clean consumer app compiles the documented use Scrypath path" do
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
    isolated_env = [{"HEX_HOME", hex_home}, {"MIX_HOME", mix_home}]

    on_exit(fn -> File.rm_rf(tmp_root) end)

    build_packaged_artifact!(repo_root, artifact_dir)
    artifact_paths = artifact_paths!(artifact_dir)

    assert Enum.any?(artifact_paths, &String.starts_with?(&1, "lib/"))
    assert "mix.exs" in artifact_paths
    assert "README.md" in artifact_paths
    assert "CHANGELOG.md" in artifact_paths
    assert Enum.any?(artifact_paths, &String.starts_with?(&1, "guides/"))
    assert "docs/releasing.md" in artifact_paths

    forbidden_prefixes = [
      "scrypath_ops/",
      "examples/",
      "website/",
      ".planning/",
      "node_modules/",
      "playwright-report/",
      "test-results/"
    ]

    for prefix <- forbidden_prefixes do
      refute Enum.any?(artifact_paths, &String.starts_with?(&1, prefix)),
             "artifact unexpectedly included forbidden path prefix #{prefix}"
    end

    artifact_git_url =
      artifact_dir
      |> init_artifact_git_repo!(tag)
      |> then(&"file://#{&1}")

    run_mix!(["new", "consumer_usage", "--module", "ConsumerUsage"], cd: tmp_root)
    File.write!(Path.join(app_dir, "mix.exs"), consumer_mix_exs(artifact_git_url, tag))
    write_consumer_schema!(app_dir)

    consumer_mix = File.read!(Path.join(app_dir, "mix.exs"))

    assert consumer_mix =~ ~s|{:scrypath, git: "#{artifact_git_url}", tag: "#{tag}"}|
    refute Regex.match?(~r/path\s*:/, consumer_mix)

    run_mix!(["deps.get"], cd: app_dir, env: isolated_env)
    run_mix!(["compile"], cd: app_dir, env: isolated_env)

    assert File.exists?(
             Path.join(
               app_dir,
               "_build/dev/lib/consumer_usage/ebin/Elixir.ConsumerUsage.Post.beam"
             )
           )
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
