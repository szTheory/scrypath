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

    on_exit(fn -> File.rm_rf(tmp_root) end)

    build_packaged_artifact!(repo_root, artifact_dir)

    # Ordering is load-bearing: the allowlist check must see the directory exactly as
    # `hex.build --unpack` produced it. Once this test initializes the artifact as a
    # repository, a top-level `.git` exists, which the check would report as a false
    # violation created by this test.
    # The result is captured, not asserted here, so a failure is reported against a test.
    package_contract_result = PackageContract.check(artifact_dir)
    package_metadata = read_package_metadata!(artifact_dir)

    artifact_paths = artifact_paths!(artifact_dir)

    artifact_git_url =
      artifact_dir
      |> init_artifact_git_repo!(tag)
      |> then(&"file://#{&1}")

    artifact_git_sha =
      artifact_dir
      |> then(&run_command!("git", ["rev-parse", "HEAD"], cd: &1))
      |> String.trim()

    consumers =
      [req_0_6: "~> 0.6.1", req_0_7: "~> 0.7.0"]
      |> Enum.map(fn {name, requirement} ->
        setup_consumer!(
          Path.join(tmp_root, Atom.to_string(name)),
          artifact_git_url,
          artifact_git_sha,
          tag,
          name,
          requirement
        )
      end)

    req_0_6 = Enum.find(consumers, &(&1.name == :req_0_6)) || raise("Req 0.6 witness missing")

    %{
      tag: tag,
      tmp_root: tmp_root,
      artifact_dir: artifact_dir,
      artifact_git_url: artifact_git_url,
      artifact_git_sha: artifact_git_sha,
      artifact_paths: artifact_paths,
      consumers: consumers,
      app_dir: req_0_6.app_dir,
      isolated_env: req_0_6.isolated_env,
      package_metadata: package_metadata,
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
               "_build/lib/consumer_usage/ebin/Elixir.ConsumerUsage.Post.beam"
             )
           )
  end

  test "the same archive has independent Req 0.6 and Req 0.7 consumer workspaces", ctx do
    assert Enum.map(ctx.consumers, & &1.name) == [:req_0_6, :req_0_7]

    [req_0_6, req_0_7] = ctx.consumers
    refute req_0_6.root_dir == req_0_7.root_dir
    refute req_0_6.app_dir == req_0_7.app_dir
    refute req_0_6.hex_home == req_0_7.hex_home
    refute req_0_6.mix_home == req_0_7.mix_home
    refute req_0_6.build_path == req_0_7.build_path
    refute req_0_6.deps_path == req_0_7.deps_path
    assert req_0_6.requirement == "~> 0.6.1"
    assert req_0_7.requirement == "~> 0.7.0"
    assert req_0_6.artifact_git_url == req_0_7.artifact_git_url
    assert req_0_6.artifact_git_sha == ctx.artifact_git_sha
    assert req_0_7.artifact_git_sha == ctx.artifact_git_sha
  end

  test "the real Hex archive declares mandatory direct dependencies and keeps Telemetry directly owned",
       ctx do
    metadata = ctx.package_metadata
    requirements = Map.fetch!(metadata, <<"requirements">>)
    oban_requirement = Enum.find(requirements, &(Map.new(&1)[<<"app">>] == <<"oban">>))

    assert Enum.any?(requirements, &(Map.new(&1)[<<"app">>] == <<"ecto">>))
    assert Map.new(oban_requirement)[<<"optional">>] == true
    assert archive_dependency_violations(metadata) == []

    without_telemetry =
      Map.update!(metadata, <<"requirements">>, fn requirements ->
        Enum.reject(requirements, &(Map.new(&1)[<<"app">>] == <<"telemetry">>))
      end)

    assert Enum.any?(
             without_telemetry[<<"requirements">>],
             &(Map.new(&1)[<<"app">>] == <<"ecto">>)
           )

    assert archive_dependency_violations(without_telemetry) == [
             "missing mandatory direct dependency telemetry ~> 1.0"
           ]
  end

  test "both installed Req consumers exercise search success, errors and Telemetry spans",
       ctx do
    %{package_metadata: package_metadata, tmp_root: tmp_root} = ctx
    assert archive_dependency_violations(package_metadata) == []

    for consumer <- ctx.consumers do
      probe_path = Path.join(tmp_root, "#{consumer.name}_search_probe.exs")

      File.write!(
        probe_path,
        consumer_search_probe(consumer.requirement, consumer.name, ctx.artifact_git_sha)
      )

      {probe_output, probe_status} = run_consumer("mix", ["run", probe_path], consumer)

      assert probe_status == 0,
             "installed #{consumer.name} search probe failed:\n#{probe_output}"

      assert probe_output =~ "consumer-search-ok witness=#{consumer.name}"
      IO.puts(probe_output)
    end
  end

  test "the installed package exposes only the public operator tasks", ctx do
    public_tasks = PackageContract.public_tasks()
    assert length(public_tasks) == 8

    for consumer <- ctx.consumers do
      %{app_dir: app_dir, isolated_env: isolated_env} = consumer
      ebin = Path.join(app_dir, "_build/lib/scrypath/ebin")

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

      {consumer_lock, _binding} = Code.eval_file(Path.join(app_dir, "mix.lock"))

      refute Map.has_key?(consumer_lock, :oban),
             "#{consumer.name} lock unexpectedly resolved Oban"

      # A maintainer task name does not resolve in the adopter's project.
      {package_output, package_status} = run_consumer("mix", ["verify.package"], consumer)

      assert package_status != 0,
             "verify.package unexpectedly ran in #{consumer.name}:\n#{package_output}"

      assert package_output =~ ~s|The task "verify.package" could not be found|,
             "unexpected verify.package output:\n#{package_output}"

      # A public operator task resolves and reaches its own usage path without a backend.
      {status_output, status_status} = run_consumer("mix", ["scrypath.status"], consumer)

      assert status_status == 1,
             "mix scrypath.status exited #{status_status} in #{consumer.name}:\n#{status_output}"

      assert status_output =~ "expected one schema module argument",
             "unexpected scrypath.status output:\n#{status_output}"

      # Every public task documents itself through the consumer's own `mix help`.
      for task <- public_tasks do
        {help_output, help_status} = run_consumer("mix", ["help", task], consumer)

        assert help_status == 0,
               "mix help #{task} exited #{help_status} in #{consumer.name}:\n#{help_output}"

        assert String.trim(help_output) != "", "mix help #{task} printed nothing"

        assert help_output =~ task,
               "mix help #{task} output in #{consumer.name} does not mention the task:\n#{help_output}"
      end

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
        consumer
        | isolated_env: [{"SCRYPATH_PUBLIC_TASKS", Enum.join(public_tasks, ",")} | isolated_env]
      }

      {probe_output, probe_status} =
        run_consumer("mix", ["run", "--no-start", "-e", probe], probe_ctx)

      assert probe_status == 0, "#{consumer.name} VM probe failed:\n#{probe_output}"

      assert probe_output =~ "public-tasks-ok",
             "#{consumer.name} VM probe output:\n#{probe_output}"
    end
  end

  test "the smoke dependency stays release-like and never falls back to path deps" do
    version = MixProject.project()[:version]
    tag = "v#{version}"

    mix_exs = consumer_mix_exs("file:///tmp/scrypath-artifact", tag, "~> 0.6.1")
    schema = consumer_schema()

    assert mix_exs =~ ~s|{:scrypath, git: "file:///tmp/scrypath-artifact", tag: "#{tag}"}|
    refute Regex.match?(~r/path\s*:/, mix_exs)
    assert schema =~ "use Scrypath"
  end

  defp setup_consumer!(consumer_root, artifact_git_url, artifact_git_sha, tag, name, requirement) do
    app_dir = Path.join(consumer_root, "consumer_usage")
    hex_home = Path.join(consumer_root, "hex_home")
    mix_home = Path.join(consumer_root, "mix_home")
    build_path = Path.join(app_dir, "_build")
    deps_path = Path.join(app_dir, "deps")
    File.mkdir_p!(consumer_root)
    File.mkdir_p!(hex_home)
    File.mkdir_p!(mix_home)

    # Each witness resolves independently with an anonymous, private Mix/Hex state.
    isolated_env = [
      {"HEX_HOME", hex_home},
      {"MIX_HOME", mix_home},
      {"MIX_BUILD_PATH", build_path},
      {"MIX_DEPS_PATH", deps_path},
      {"MIX_ENV", "test"}
    ]

    run_mix!(["new", "consumer_usage", "--module", "ConsumerUsage"], cd: consumer_root)

    File.write!(
      Path.join(app_dir, "mix.exs"),
      consumer_mix_exs(artifact_git_url, tag, requirement)
    )

    write_consumer_schema!(app_dir)
    run_mix!(["deps.get"], cd: app_dir, env: isolated_env)
    run_mix!(["compile"], cd: app_dir, env: isolated_env)

    %{
      name: name,
      requirement: requirement,
      root_dir: consumer_root,
      app_dir: app_dir,
      isolated_env: isolated_env,
      hex_home: hex_home,
      mix_home: mix_home,
      build_path: build_path,
      deps_path: deps_path,
      artifact_git_url: artifact_git_url,
      artifact_git_sha: artifact_git_sha
    }
  end

  defp consumer_mix_exs(artifact_git_url, tag, req_requirement) do
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
          {:req, "#{req_requirement}"},
          {:plug, "~> 1.19.5", only: :test},
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

  defp consumer_search_probe(req_requirement, witness_name, artifact_git_sha) do
    """
    {:ok, _apps} = Application.ensure_all_started(:req)
    {:ok, _apps} = Application.ensure_all_started(:telemetry)

    req_version = Application.spec(:req, :vsn) |> to_string()
    {consumer_lock, _binding} = Code.eval_file("mix.lock")
    locked_req_version = consumer_lock |> Map.fetch!(:req) |> elem(2)
    locked_artifact_sha = consumer_lock |> Map.fetch!(:scrypath) |> elem(2)
    requirement = #{inspect(req_requirement)}
    witness = #{inspect(witness_name)}
    artifact_sha = #{inspect(artifact_git_sha)}

    expect = fn condition, message ->
      unless condition, do: raise(message)
    end

    expect.(Version.match?(req_version, requirement), "Req version did not match #{req_requirement}: \#{req_version}")
    expect.(locked_req_version == req_version, "Req application and lock versions differ: \#{req_version} / \#{locked_req_version}")
    expect.(locked_artifact_sha == artifact_sha, "consumer did not install the shared archive commit: \#{locked_artifact_sha} / \#{artifact_sha}")

    collect_requests = fn collect_requests, requests ->
      receive do
        {:consumer_search_request, method, path, query} ->
          collect_requests.(collect_requests, [{method, path, query} | requests])
      after
        100 -> Enum.reverse(requests)
      end
    end

    collect_events = fn collect_events, events ->
      receive do
        {:consumer_search_span, event, measurements, metadata} ->
          collect_events.(collect_events, [{event, measurements, metadata} | events])
      after
        100 -> Enum.reverse(events)
      end
    end

    parent = self()
    stub = ConsumerUsage.SearchResponseStub

    Req.Test.stub(stub, fn conn ->
      query = conn.body_params["q"]
      send(parent, {:consumer_search_request, conn.method, conn.request_path, query})

      case query do
        "needle" ->
          Req.Test.json(conn, %{
            "hits" => [%{"id" => 99}],
            "page" => 2,
            "hitsPerPage" => 20,
            "totalHits" => 1
          })

        "failure" ->
          conn
          |> Plug.Conn.put_resp_content_type("application/json")
          |> Plug.Conn.resp(503, Jason.encode!(%{"message" => "unavailable"}))
      end
    end)

    index = Scrypath.Meilisearch.index_name(ConsumerUsage.Post, [])
    handler_id = "consumer-search-#{System.unique_integer([:positive])}"
    search_events = [[:scrypath, :search, :start], [:scrypath, :search, :stop]]

    :ok =
      :telemetry.attach_many(
        handler_id,
        search_events,
        fn event, measurements, metadata, owner ->
          send(owner, {:consumer_search_span, event, measurements, metadata})
        end,
        parent
      )

    search_opts = [
      backend: Scrypath.Meilisearch,
      meilisearch_url: "http://localhost:7700",
      req_options: [plug: {Req.Test, stub}]
    ]

    result = Scrypath.search(ConsumerUsage.Post, "needle", search_opts)
    error_result = Scrypath.search(ConsumerUsage.Post, "failure", search_opts)

    :ok = :telemetry.detach(handler_id)

    expect.(
      match?({:ok, %Scrypath.SearchResult{}}, result),
      "Scrypath.search/3 did not return a normalized SearchResult: \#{inspect(result)}"
    )

    {:ok, search_result} = result

    expect.(
      search_result.hits == [%{"id" => 99}] and
        search_result.page == %{number: 2, size: 20, total_hits: 1} and
        search_result.records == [] and search_result.missing_ids == [],
      "unexpected normalized SearchResult: \#{inspect(search_result)}"
    )

    expect.(
      match?({:error, {:http_error, 503, %{"message" => "unavailable"}}}, error_result),
      "Scrypath.search/3 did not normalize the HTTP error: \#{inspect(error_result)}"
    )

    requests = collect_requests.(collect_requests, [])
    expected_path = "/indexes/\#{index}/search"

    expect.(
      requests == [
        {"POST", expected_path, "needle"},
        {"POST", expected_path, "failure"}
      ],
      "unexpected consumer search requests: \#{inspect(requests)}"
    )

    events = collect_events.(collect_events, [])
    expected_events = [
      [:scrypath, :search, :start],
      [:scrypath, :search, :stop],
      [:scrypath, :search, :start],
      [:scrypath, :search, :stop]
    ]

    expect.(
      Enum.map(events, &elem(&1, 0)) == expected_events,
      "missing success/error search start/stop events: \#{inspect(events)}"
    )

    Enum.each(events, fn {_event, _measurements, metadata} ->
      expect.(metadata.schema == ConsumerUsage.Post, "search span has wrong schema metadata")
      expect.(metadata.backend == :meilisearch, "search span has wrong backend metadata")
      expect.(metadata.index == index, "search span has wrong index metadata")
    end)

    [_start_success, {_stop_event, _measurements, success_metadata}, _start_error,
     {_error_stop_event, _error_measurements, error_metadata}] = events

    expect.(success_metadata.hit_count == 1, "search stop span has wrong hit_count")
    expect.(error_metadata.error_kind == :http, "error stop span has wrong error_kind")

    IO.puts(
      "consumer-search-ok witness=\#{witness} req=\#{req_version} lock=\#{locked_req_version} artifact=\#{artifact_sha} telemetry=success,error"
    )
    """
  end

  defp archive_dependency_violations(metadata) do
    requirements =
      metadata
      |> Map.get(<<"requirements">>, [])
      |> Enum.map(&Map.new/1)

    required_dependencies = [
      {<<"telemetry">>, <<"~> 1.0">>},
      {<<"req">>, <<"~> 0.6.1 or ~> 0.7">>}
    ]

    Enum.flat_map(required_dependencies, fn {app, requirement} ->
      case Enum.find(requirements, &(Map.get(&1, <<"app">>) == app)) do
        nil ->
          ["missing mandatory direct dependency #{app} #{requirement}"]

        entry ->
          []
          |> maybe_add_metadata_violation(
            Map.get(entry, <<"requirement">>) != requirement,
            "direct dependency #{app} has wrong requirement #{inspect(Map.get(entry, <<"requirement">>))}"
          )
          |> maybe_add_metadata_violation(
            Map.get(entry, <<"optional">>) != false,
            "direct dependency #{app} is not mandatory"
          )
      end
    end)
  end

  defp maybe_add_metadata_violation(violations, true, message), do: violations ++ [message]
  defp maybe_add_metadata_violation(violations, false, _message), do: violations

  defp read_package_metadata!(artifact_dir) do
    metadata_path = Path.join(artifact_dir, "hex_metadata.config")
    {:ok, terms} = :file.consult(String.to_charlist(metadata_path))
    Map.new(terms)
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
