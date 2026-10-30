defmodule Scrypath.Release.OpsDependencyBoundaryTest do
  use ExUnit.Case, async: false

  @moduletag timeout: :infinity

  @diagnostic_apps [:phoenix_live_dashboard, :telemetry_metrics, :telemetry_poller]
  @asset_apps [:esbuild, :tailwind]
  @absent_modules [
    Module.concat(["Sigra", "Audit"]),
    Module.concat(["Phoenix", "LiveDashboard"]),
    Module.concat(["Phoenix", "LiveDashboard", "RequestLogger"]),
    Module.concat(["Telemetry", "Metrics"]),
    :telemetry_poller,
    Module.concat(["Esbuild"]),
    Module.concat(["Tailwind"]),
    Module.concat(["ScrypathOpsWeb", "Telemetry"])
  ]

  setup_all do
    repo = File.cwd!()

    run_id =
      "#{System.unique_integer([:positive, :monotonic])}#{System.system_time(:microsecond)}"

    scratch = Path.join(physical_tmp_dir!(), "scrypath-ops-boundary-#{run_id}")
    File.mkdir_p!(scratch)
    on_exit(fn -> File.rm_rf(scratch) end)

    {source_sha, 0} = System.cmd("git", ["rev-parse", "HEAD"], cd: repo)

    %{repo: repo, scratch: scratch, source_sha: String.trim(source_sha), run_id: run_id}
  end

  test "mounted test and production consumers compile and start without optional Ops dependencies",
       ctx do
    ops_source = Path.join(ctx.repo, "scrypath_ops")

    for mix_env <- ["test", "prod"] do
      consumer_root = Path.join(ctx.scratch, "mounted-#{mix_env}")
      File.mkdir_p!(consumer_root)
      create_consumer!(consumer_root, ops_source)

      env = isolated_env(ctx.scratch, "mounted-#{mix_env}", mix_env, ctx.source_sha)
      run_mix!("local.hex", ["--force"], consumer_root, env)
      run_mix!("deps.get", [], consumer_root, env)
      run_mix!("compile", ["--no-optional-deps", "--warnings-as-errors"], consumer_root, env)

      probe = Path.join(consumer_root, "ops_dependency_probe.exs")
      File.write!(probe, mounted_probe())
      output = run_mix!("run", ["--no-start", probe], consumer_root, env)

      assert output =~ "OPS_DEPENDENCY_BOUNDARY case=mounted env=#{mix_env} result=passed"
    end
  end

  test "direct Ops dev, test, and production graphs preserve their distinct runtime contracts",
       ctx do
    source_root = Path.join(ctx.scratch, "tracked-source")
    archive_tracked_source!(ctx.repo, source_root, ctx.scratch)
    ops_dir = Path.join(source_root, "scrypath_ops")

    for mix_env <- ["dev", "test", "prod"] do
      case_root = Path.join(ctx.scratch, "direct-#{mix_env}")
      File.mkdir_p!(case_root)
      database = "scrypath_ops_boundary_#{mix_env}_#{ctx.run_id}"
      env = direct_env(ctx.scratch, case_root, mix_env, database, ctx.source_sha)
      lock_path = Path.join(ops_dir, "mix.lock")
      lock_before = sha256(File.read!(lock_path))

      run_mix!("local.hex", ["--force"], ops_dir, env)
      run_mix!("deps.get", ["--check-locked"], ops_dir, env)

      if mix_env == "dev" do
        # Loading the existing esbuild task compiles the clean dependency graph
        # in its normal application context before inspecting the direct dev graph.
        run_mix!("esbuild.install", [], ops_dir, env)
      end

      run_mix!("compile", ["--warnings-as-errors"], ops_dir, env)

      if mix_env in ["test", "prod"] do
        run_mix!("phx.digest", [], ops_dir, env)
        run_mix!("ecto.create", ["--quiet"], ops_dir, env)
        run_mix!("ecto.migrate", ["--quiet"], ops_dir, env)
      end

      probe = Path.join(case_root, "ops_dependency_probe.exs")
      File.write!(probe, direct_probe())

      try do
        output = run_mix!("run", ["--no-start", probe], ops_dir, env)
        assert output =~ "OPS_DEPENDENCY_BOUNDARY case=direct env=#{mix_env} result=passed"

        assert sha256(File.read!(lock_path)) == lock_before,
               "#{mix_env} Ops dependency resolution changed the tracked lockfile"
      after
        if mix_env in ["test", "prod"] do
          drop_database!(database, env)
        end
      end
    end
  end

  defp create_consumer!(root, ops_source) do
    bridge = Path.join(root, "ops_bridge")
    File.mkdir_p!(Path.join(bridge, "lib"))
    File.mkdir_p!(Path.join(root, "config"))
    File.mkdir_p!(Path.join(root, "lib"))

    File.write!(
      Path.join(bridge, "mix.exs"),
      """
      defmodule OpsBoundaryBridge.MixProject do
        use Mix.Project

        def project do
          [app: :ops_boundary_bridge, version: "0.1.0", elixir: "~> 1.17", deps: deps()]
        end

        def application, do: [extra_applications: [:logger]]

        defp deps, do: [{:scrypath_ops, path: #{inspect(ops_source)}}]
      end
      """
    )

    File.write!(
      Path.join(bridge, "lib/ops_boundary_bridge.ex"),
      "defmodule OpsBoundaryBridge, do: :ok\n"
    )

    File.write!(
      Path.join(root, "mix.exs"),
      """
      defmodule OpsBoundaryConsumer.MixProject do
        use Mix.Project

        def project do
          [app: :ops_boundary_consumer, version: "0.1.0", elixir: "~> 1.17", deps: deps()]
        end

        def application, do: [extra_applications: [:logger]]

        defp deps, do: [{:ops_boundary_bridge, path: "ops_bridge"}]
      end
      """
    )

    File.write!(
      Path.join(root, "config/config.exs"),
      """
      import Config
      config :ops_boundary_consumer, ecto_repos: [OpsBoundaryRepo]
      config :scrypath_ops, standalone: false
      config :scrypath_ops, :sigra, sudo_confirm_path: "/sudo/confirm"
      config :phoenix, :json_library, Jason
      """
    )

    File.write!(
      Path.join(root, "lib/ops_boundary_repo.ex"),
      """
      defmodule OpsBoundaryRepo do
        use Ecto.Repo, otp_app: :ops_boundary_consumer, adapter: Ecto.Adapters.Postgres
      end
      """
    )

    File.write!(
      Path.join(root, "lib/ops_boundary_router.ex"),
      """
      defmodule OpsBoundaryWeb.Router do
        use Phoenix.Router, helpers: false
        import ScrypathOpsWeb.Router

        scrypath_ops_routes("/ops", repo: OpsBoundaryRepo)
      end
      """
    )

    File.write!(
      Path.join(root, "lib/ops_boundary_post.ex"),
      """
      defmodule OpsBoundaryPost do
        use Ecto.Schema
        use Scrypath, fields: [:title, :body], filterable: [:status], sortable: [:inserted_at]

        schema "posts" do
          field :title, :string
          field :body, :string
          field :status, Ecto.Enum, values: [:draft, :published]
          timestamps()
        end
      end
      """
    )
  end

  defp isolated_env(scratch, name, mix_env, source_sha) do
    target = Path.join(scratch, name)

    [
      {"MIX_ENV", mix_env},
      {"MIX_BUILD_PATH", Path.join(target, "build")},
      {"MIX_DEPS_PATH", Path.join(target, "deps")},
      {"MIX_HOME", Path.join(target, "mix")},
      {"HEX_HOME", Path.join(target, "hex")},
      {"MIX_QUIET", "1"},
      {"OPSUI_AUTH_MODE", "basic"},
      {"SECRET_KEY_BASE", String.duplicate("a", 64)},
      {"DATABASE_URL", consumer_database_url(name)},
      {"PORT", "0"},
      {"SCRYPATH_SOURCE_SHA", source_sha},
      {"SCRYPATH_BOUNDARY_CASE", "mounted"}
    ]
  end

  defp direct_env(scratch, _target, mix_env, database, source_sha) do
    host = System.get_env("PGHOST", "127.0.0.1")
    port = System.get_env("PGPORT", "5432")
    user = System.get_env("PGUSER", "postgres")
    password = System.get_env("PGPASSWORD", "postgres")
    directory = Path.join(scratch, "direct-env-#{mix_env}")

    database_env =
      if mix_env == "prod" do
        [{"DATABASE_URL", "ecto://#{user}:#{password}@#{host}:#{port}/#{database}"}]
      else
        [{"SCRYPATH_OPS_TEST_DATABASE", database}, {"SCRYPATH_OPS_DATABASE_NAME", database}]
      end

    [
      {"MIX_ENV", mix_env},
      {"MIX_BUILD_PATH", Path.join(directory, "build")},
      {"MIX_DEPS_PATH", Path.join(directory, "deps")},
      {"MIX_HOME", Path.join(directory, "mix")},
      {"HEX_HOME", Path.join(directory, "hex")},
      {"MIX_QUIET", "1"},
      {"PGHOST", host},
      {"PGPORT", port},
      {"PGUSER", user},
      {"PGPASSWORD", password},
      {"SECRET_KEY_BASE", String.duplicate("b", 64)},
      {"OPSUI_AUTH_MODE", "sigra"},
      {"SCRYPATH_SOURCE_SHA", source_sha},
      {"SCRYPATH_BOUNDARY_CASE", "direct"},
      {"SCRYPATH_BOUNDARY_PROGRESS", Path.join(scratch, "progress-direct-env-#{mix_env}.log")},
      {"SCRYPATH_OPS_PORT", "0"},
      {"PORT", "0"},
      {"PHX_SERVER", "false"},
      {"DNS_CLUSTER_QUERY", ""}
    ] ++ database_env
  end

  defp archive_tracked_source!(repo, destination, scratch) do
    archive = Path.join(scratch, "tracked-source.tar")

    paths =
      ["mix.exs", "mix.lock", "lib", "priv", "scrypath_ops"]
      |> Enum.filter(fn path ->
        {_output, status} =
          System.cmd("git", ["ls-tree", "--name-only", "HEAD", "--", path], cd: repo)

        status == 0 and File.exists?(Path.join(repo, path))
      end)

    {output, status} =
      System.cmd("git", ["archive", "--format=tar", "--output", archive, "HEAD" | paths],
        cd: repo
      )

    assert status == 0, "could not archive tracked source: #{output}"
    File.mkdir_p!(destination)
    {extract_output, extract_status} = System.cmd("tar", ["-xf", archive, "-C", destination])
    assert extract_status == 0, "could not extract tracked source: #{extract_output}"
  end

  defp run_mix!(task, args, cwd, env) do
    {output, status} = run_mix(task, args, cwd, env)
    assert status == 0, "mix #{task} #{Enum.join(args, " ")} failed in #{cwd}:\n#{output}"
    output
  end

  defp drop_database!(database, env) do
    env = Map.new(env)

    args = [
      "--if-exists",
      "--force",
      "--host",
      Map.fetch!(env, "PGHOST"),
      "--port",
      Map.fetch!(env, "PGPORT"),
      "--username",
      Map.fetch!(env, "PGUSER"),
      database
    ]

    {output, status} =
      System.cmd("dropdb", args,
        env: [{"PGPASSWORD", Map.fetch!(env, "PGPASSWORD")}],
        stderr_to_stdout: true
      )

    assert status == 0, "could not clean disposable database #{database}: #{output}"
  end

  defp run_mix(task, args, cwd, env) do
    mix =
      System.find_executable("mix") || raise "the selected Elixir toolchain has no mix executable"

    System.cmd(mix, [task | args], cd: cwd, env: env, stderr_to_stdout: true)
  end

  defp consumer_database_url(name) do
    host = System.get_env("PGHOST", "127.0.0.1")
    port = System.get_env("PGPORT", "5432")
    "ecto://postgres:postgres@#{host}:#{port}/#{name}"
  end

  defp sha256(contents), do: :crypto.hash(:sha256, contents) |> Base.encode16(case: :lower)

  defp physical_tmp_dir! do
    {path, 0} = System.cmd("pwd", ["-P"], cd: System.tmp_dir!())
    String.trim(path)
  end

  defp mounted_probe do
    ~S"""
    defmodule OpsBoundaryMountedProbe do
      @forbidden_apps [:sigra, :phoenix_live_dashboard, :telemetry_metrics, :telemetry_poller, :esbuild, :tailwind]
      @forbidden_modules __ABSENT_MODULES__
      @actions [:saved_search_delete, :failed_work_retry, :swap_live, :reindex, :delete_documents, :hot_apply]

      defmodule Backend do
        def name, do: :ops_boundary
        def index_name(_schema, _config), do: "ops_boundary"

        def search(_schema, _query, _config),
          do: {:ok, %{"hits" => [], "page" => 1, "hitsPerPage" => 20, "totalHits" => 0}}
      end

      def run do
        load_application!(:scrypath_ops)
        {:ok, [{:application, :scrypath_ops, spec}]} = :file.consult(String.to_charlist(Path.join(:code.lib_dir(:scrypath_ops, :ebin), "scrypath_ops.app")))
        applications = Keyword.get(spec, :applications, [])
        optional_applications = Keyword.get(spec, :optional_applications, [])
        modules = Keyword.get(spec, :modules, [])
        assert!(:telemetry in applications, "Ops .app omitted mandatory Telemetry")
        assert!(
          :sigra not in applications or :sigra in optional_applications,
          "optional Sigra became a mandatory Ops application"
        )
        assert!(ScrypathOpsWeb.Telemetry not in modules, "dev telemetry module compiled into a mounted consumer")

        lock = Mix.Dep.Lock.read("mix.lock")
        for app <- @forbidden_apps, do: assert!(not Map.has_key?(lock, app), "#{app} resolved in mounted #{Mix.env()} graph")
        for module <- @forbidden_modules, do: assert!(:code.which(module) == :non_existing, "#{inspect(module)} has a code path in mounted graph")

        {:ok, _} = Application.ensure_all_started(:scrypath_ops)
        assert_absent_runtime_apps!(@forbidden_apps)
        children = Supervisor.which_children(ScrypathOps.Supervisor) |> Enum.map(fn {_, _, _, modules} -> List.first(modules) end)
        for module <- [ScrypathOps.RecoveryObservation, Phoenix.PubSub.Supervisor, Task.Supervisor], do: assert!(module in children, "missing core child #{inspect(module)}")
        for module <- [ScrypathOpsWeb.Endpoint, ScrypathOps.Repo, DNSCluster, ScrypathOpsWeb.Telemetry], do: assert!(module not in children, "mounted Ops started #{inspect(module)}")

        conn = Plug.Test.conn(:get, "/ops/favicon.svg") |> OpsBoundaryWeb.Router.call(OpsBoundaryWeb.Router.init([]))
        assert!(conn.status == 200 and conn.resp_body != "", "mounted favicon route failed: #{conn.status}")
        assert_search_telemetry!()

        for mode <- ["basic", "proxy_headers"] do
          Application.stop(:scrypath_ops)
          System.put_env("OPSUI_AUTH_MODE", mode)
          Application.put_env(:scrypath_ops, :standalone, false)
          {:ok, _} = Application.ensure_all_started(:scrypath_ops)
          assert!(Process.whereis(ScrypathOps.Supervisor) != nil, "#{mode} startup failed without Sigra")
          Application.stop(:scrypath_ops)
        end

        Application.stop(:scrypath_ops)
        System.put_env("OPSUI_AUTH_MODE", "sigra")
        Application.put_env(:scrypath_ops, :sigra, sudo_confirm_path: "/sudo/confirm")
        validation_env = %{
          auth_mode: "sigra",
          sigra: [sudo_confirm_path: "/sudo/confirm"]
        }

        {:error, message} = ScrypathOps.Security.validate(validation_env)
        assert!(message =~ "Sigra", "unavailable-Sigra validation was unclear: #{message}")
        assert_raise_message!(
          fn -> ScrypathOps.Security.validate!(validation_env) end,
          "Sigra"
        )

        gating = Module.concat(["ScrypathOps", "Integrations", "Sigra", "Gating"])
        socket = struct(Phoenix.LiveView.Socket, assigns: %{__changed__: %{}, flash: %{}})
        for action <- @actions, do: reject_gating_callback!(gating, socket, action)

        case Application.ensure_all_started(:scrypath_ops) do
          {:error, {:scrypath_ops, _reason}} -> :ok
          other -> raise "Sigra startup without its dependency should fail, got #{inspect(other)}"
        end
        assert!(Process.whereis(ScrypathOps.Supervisor) == nil, "supervisor started with unavailable Sigra")

        IO.puts("OPS_DEPENDENCY_BOUNDARY case=mounted env=#{Mix.env()} result=passed source=#{System.fetch_env!("SCRYPATH_SOURCE_SHA")} lock=#{sha256(File.read!("mix.lock"))} apps=#{inspect(applications)} optional_apps=#{inspect(optional_applications)}")
      end

      defp assert_search_telemetry! do
        parent = self()
        events = [[:scrypath, :search, :start], [:scrypath, :search, :stop]]
        id = {__MODULE__, make_ref()}
        :ok = :telemetry.attach_many(id, events, fn event, measurements, metadata, owner -> send(owner, {:ops_boundary_telemetry, event, measurements, metadata}) end, parent)
        result = Scrypath.search(OpsBoundaryPost, "probe", backend: Backend)
        :ok = :telemetry.detach(id)
        assert!(match?({:ok, %Scrypath.SearchResult{}}, result), "core search probe failed: #{inspect(result)}")
        observed = for _ <- 1..2 do
          receive do {:ops_boundary_telemetry, event, _, _} -> event after 5_000 -> raise "core search telemetry did not complete" end
        end
        assert!(Enum.sort(observed) == Enum.sort(events), "unexpected core telemetry events: #{inspect(observed)}")
      end

      defp reject_gating_callback!(gating, socket, action) do
        ref = make_ref()

        result =
          try do
            apply(gating, :gate_sensitive_action, [
              socket,
              action,
              fn ->
                send(self(), {:forbidden_callback, ref})
                :called
              end
            ])
          rescue
            UndefinedFunctionError -> :unavailable
          end

        if result != :unavailable do
          flash = result.assigns.flash
          error = Map.get(flash, "error") || Map.get(flash, :error)

          assert!(
            is_binary(error) and error =~ "Sigra" and error =~ "blocked",
            "missing Sigra did not block #{action}: #{inspect(result)}"
          )
        end

        receive do {:forbidden_callback, ^ref} -> raise "#{action} callback ran without Sigra" after 0 -> :ok end
      end

      defp assert_absent_runtime_apps!(apps) do
        loaded = Application.loaded_applications() |> Enum.map(&elem(&1, 0))
        started = Application.started_applications() |> Enum.map(&elem(&1, 0))
        for app <- apps do
          assert!(app not in loaded, "#{app} loaded in mounted consumer")
          assert!(app not in started, "#{app} started in mounted consumer")
        end
      end

      defp assert_raise_message!(fun, text) do
        error = try do fun.(); nil rescue exception -> exception end
        assert!(is_exception(error) and Exception.message(error) =~ text, "expected raised error containing #{text}, got #{inspect(error)}")
      end

      defp load_application!(app) do
        case Application.load(app) do
          :ok -> :ok
          {:error, {:already_loaded, ^app}} -> :ok
          other -> raise "could not load #{app}: #{inspect(other)}"
        end
      end

      defp assert!(condition, message) do
        unless condition, do: raise(message)
      end

      defp sha256(contents), do: :crypto.hash(:sha256, contents) |> Base.encode16(case: :lower)
    end

    OpsBoundaryMountedProbe.run()
    """
    |> String.replace("__ABSENT_MODULES__", inspect(@absent_modules))
  end

  defp direct_probe do
    ~S"""
    defmodule OpsBoundaryDirectProbe do
      @diagnostic_apps __DIAGNOSTIC_APPS__
      @asset_apps __ASSET_APPS__
      @diagnostic_modules [Module.concat(["Phoenix", "LiveDashboard"]), Module.concat(["Phoenix", "LiveDashboard", "RequestLogger"]), Module.concat(["Telemetry", "Metrics"]), :telemetry_poller, Module.concat(["ScrypathOpsWeb", "Telemetry"])]
      @asset_modules [Module.concat(["Esbuild"]), Module.concat(["Tailwind"])]

      defmodule Post do
        use Ecto.Schema
        use Scrypath, fields: [:title], filterable: [:status], sortable: [:inserted_at]

        embedded_schema do
          field :title, :string
          field :status, :string
          field :inserted_at, :utc_datetime
        end
      end

      defmodule Backend do
        def name, do: :ops_boundary
        def index_name(_schema, _config), do: "ops_boundary"

        def search(_schema, _query, _config),
          do: {:ok, %{"hits" => [], "page" => 1, "hitsPerPage" => 20, "totalHits" => 0}}
      end

      def run do
        mark!("run:entry")
        env = Atom.to_string(Mix.env())
        load_application!(:scrypath_ops)
        {:ok, [{:application, :scrypath_ops, spec}]} = :file.consult(String.to_charlist(Path.join(:code.lib_dir(:scrypath_ops, :ebin), "scrypath_ops.app")))
        applications = Keyword.get(spec, :applications, [])
        optional_applications = Keyword.get(spec, :optional_applications, [])
        modules = Keyword.get(spec, :modules, [])
        assert!(:telemetry in applications, "direct Ops must keep mandatory Telemetry")
        assert!(Code.ensure_loaded?(Sigra.Audit), "direct Ops must retain optional Sigra")
        assert!(:sigra in optional_applications, "Sigra must remain optional in Ops .app requirements")
        {:ok, _} = Application.ensure_all_started(:sigra)

        dev? = env == "dev"
        for module <- @diagnostic_modules ++ @asset_modules do
          expected? = dev? or module in [Module.concat(["Esbuild"]), Module.concat(["Tailwind"])] and false
          assert!(module_available?(module) == expected?, "#{inspect(module)} availability did not match #{env}")
        end
        for app <- @diagnostic_apps ++ @asset_apps do
          expected? = dev?
          listed? = app in applications or app in optional_applications
          assert!(listed? == expected?, "#{app} .app requirement mismatch in #{env}: #{inspect({applications, optional_applications})}")
        end
        assert!((ScrypathOpsWeb.Telemetry in modules) == dev?, "diagnostics module compilation mismatch in #{env}")

        standalone? = env in ["test", "prod"]
        Application.put_env(:scrypath_ops, :standalone, standalone?)
        Application.put_env(:scrypath_ops, :sigra, sudo_confirm_path: "/sudo/confirm")
        System.put_env("OPSUI_AUTH_MODE", "sigra")
        {:ok, _} = Application.ensure_all_started(:scrypath_ops)
        mark!("run:started")
        children = Supervisor.which_children(ScrypathOps.Supervisor) |> Enum.map(fn {_, _, _, child_modules} -> List.first(child_modules) end)
        assert!(ScrypathOps.RecoveryObservation in children and Phoenix.PubSub.Supervisor in children and Task.Supervisor in children, "direct core children missing in #{env}")
        assert!((ScrypathOpsWeb.Telemetry in children) == dev?, "diagnostic child mismatch in #{env}")
        assert!((ScrypathOpsWeb.Endpoint in children) == standalone?, "endpoint ownership mismatch in #{env}")
        assert!((ScrypathOps.Repo in children) == standalone?, "repo ownership mismatch in #{env}")
        assert_absent_or_started_apps!(env)

        if standalone? do
          conn =
            Plug.Test.conn(:get, "https://example.com/favicon.svg")
            |> ScrypathOpsWeb.Endpoint.call(ScrypathOpsWeb.Endpoint.init([]))
          assert!(conn.status == 200 and conn.resp_body != "", "direct static route failed in #{env}: #{conn.status}")
        end

        mark!("run:before-search")
        assert_search_telemetry!()
        mark!("run:after-search")
        exercise_auth_callbacks!()
        mark!("run:after-callbacks")

        IO.puts("OPS_DEPENDENCY_BOUNDARY case=direct env=#{env} result=passed source=#{System.fetch_env!("SCRYPATH_SOURCE_SHA")} lock=#{sha256(File.read!("mix.lock"))} apps=#{inspect(applications)} optional_apps=#{inspect(optional_applications)}")
      end

      defp assert_absent_or_started_apps!("dev") do
        loaded = Application.loaded_applications() |> Enum.map(&elem(&1, 0))
        started = Application.started_applications() |> Enum.map(&elem(&1, 0))
        for app <- @diagnostic_apps do
          assert!(app in loaded or app in started, "dev diagnostics app #{app} was neither loaded nor started")
        end
      end

      defp assert_absent_or_started_apps!(env) when env in ["test", "prod"] do
        loaded = Application.loaded_applications() |> Enum.map(&elem(&1, 0))
        started = Application.started_applications() |> Enum.map(&elem(&1, 0))
        for app <- @diagnostic_apps ++ @asset_apps do
          assert!(app not in loaded and app not in started, "#{app} loaded or started in direct #{env}")
        end
      end

      defp exercise_auth_callbacks! do
        gating = ScrypathOps.Integrations.Sigra.Gating
        actions = Map.keys(gating.__action_config__())
        socket = struct(Phoenix.LiveView.Socket, assigns: %{__changed__: %{}, flash: %{}})

        for mode <- ["basic", "proxy_headers"] do
          System.put_env("OPSUI_AUTH_MODE", mode)
          for action <- actions do
            ref = make_ref()
            result = gating.gate_sensitive_action(socket, action, fn -> send(self(), {:ops_boundary_callback, ref}); :called end)
            assert!(result == :called, "#{mode} changed host callback behavior for #{action}")
            receive do {:ops_boundary_callback, ^ref} -> :ok after 0 -> raise "#{mode} skipped callback for #{action}" end
          end
        end

        System.put_env("OPSUI_AUTH_MODE", "sigra")
        for action <- actions do
          ref = make_ref()
          result = gating.gate_sensitive_action(socket, action, fn -> send(self(), {:forbidden_sigra_callback, ref}); :called end)
          assert!(is_binary(Map.get(result.assigns.flash, "error")), "Sigra allowed #{action} without operator context")
          receive do {:forbidden_sigra_callback, ^ref} -> raise "Sigra invoked #{action} without operator context" after 0 -> :ok end
        end
      end

      defp assert_search_telemetry! do
        mark!("search:before-attach")
        parent = self()
        events = [[:scrypath, :search, :start], [:scrypath, :search, :stop]]
        id = {__MODULE__, make_ref()}
        :ok = :telemetry.attach_many(id, events, fn event, measurements, metadata, owner -> send(owner, {:ops_boundary_telemetry, event, measurements, metadata}) end, parent)
        mark!("search:before-call")
        result = Scrypath.search(OpsBoundaryDirectProbe.Post, "probe", backend: Backend)
        mark!("search:after-call")
        :ok = :telemetry.detach(id)
        assert!(match?({:ok, %Scrypath.SearchResult{}}, result), "core search probe failed: #{inspect(result)}")
        observed = for _ <- 1..2 do
          receive do {:ops_boundary_telemetry, event, _, _} -> event after 5_000 -> raise "core search telemetry did not complete" end
        end
        assert!(Enum.sort(observed) == Enum.sort(events), "unexpected core telemetry events: #{inspect(observed)}")
        mark!("search:after-events")
      end

      defp mark!(stage) do
        File.write!(System.fetch_env!("SCRYPATH_BOUNDARY_PROGRESS"), stage <> "\n", [:append])
      end

      defp module_available?(module), do: :code.which(module) != :non_existing

      defp load_application!(app) do
        case Application.load(app) do
          :ok -> :ok
          {:error, {:already_loaded, ^app}} -> :ok
          other -> raise "could not load #{app}: #{inspect(other)}"
        end
      end

      defp assert!(condition, message) do
        unless condition, do: raise(message)
      end

      defp sha256(contents), do: :crypto.hash(:sha256, contents) |> Base.encode16(case: :lower)
    end

    OpsBoundaryDirectProbe.run()
    """
    |> String.replace("__DIAGNOSTIC_APPS__", inspect(@diagnostic_apps))
    |> String.replace("__ASSET_APPS__", inspect(@asset_apps))
  end
end
