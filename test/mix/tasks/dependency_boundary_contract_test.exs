defmodule Scrypath.Repository.DependencyBoundaryContractTest do
  use ExUnit.Case, async: true

  @ops_manifest "scrypath_ops/mix.exs"
  @host_manifest "examples/scrypath_ecommerce/mix.exs"
  @root_manifest "mix.exs"
  @ops_asset_config "scrypath_ops/config/config.exs"
  @host_asset_config "examples/scrypath_ecommerce/config/config.exs"
  @ops_config_files [
    "scrypath_ops/config/config.exs",
    "scrypath_ops/config/dev.exs",
    "scrypath_ops/config/test.exs",
    "scrypath_ops/config/prod.exs",
    "scrypath_ops/config/runtime.exs"
  ]
  @host_config_files [
    "examples/scrypath_ecommerce/config/config.exs",
    "examples/scrypath_ecommerce/config/dev.exs"
  ]
  @mailbox_source "scrypath_ops/lib/scrypath_ops/mailer.ex"
  @mailbox_test "scrypath_ops/test/scrypath_ops/swoosh_api_client_req_test.exs"
  @dev_router "scrypath_ops/lib/scrypath_ops_web/dev_router.ex"
  @telemetry_source "scrypath_ops/lib/scrypath_ops_web/telemetry.ex"
  @application_source "scrypath_ops/lib/scrypath_ops/application.ex"
  @endpoint_source "scrypath_ops/lib/scrypath_ops_web/endpoint.ex"

  test "Ops and ecommerce do not directly declare Swoosh" do
    for path <- [@ops_manifest, @host_manifest] do
      dependencies = direct_dependency_names!(path)

      refute :swoosh in dependencies,
             "#{path}: remove the direct {:swoosh, ...} dependency tuple"

      assert :phoenix in dependencies,
             "#{path}: unrelated Phoenix dependency must remain declared"
    end

    assert :oban in direct_dependency_names!(@host_manifest),
           "#{@host_manifest}: unrelated Oban dependency must remain declared"
  end

  test "the unused Ops Mailer module and Swoosh-only test stay deleted" do
    refute File.exists?(@mailbox_source),
           "#{@mailbox_source}: deleted mail implementation must not return"

    refute File.exists?(@mailbox_test),
           "#{@mailbox_test}: obsolete mail-client test must not return"
  end

  test "Ops and host configuration ASTs contain no mail client or Mailer settings" do
    for path <- @ops_config_files ++ @host_config_files do
      ast = read_ast!(path)

      refute has_swoosh_config?(ast),
             "#{path}: remove active config calls for the Swoosh application"

      refute has_mailer_module?(ast),
             "#{path}: remove active ScrypathOps.Mailer configuration"
    end
  end

  test "the dev router drops only the mailbox route and retains supported routes" do
    ast = read_ast!(@dev_router)

    refute has_swoosh_mailbox_forward?(ast),
           "#{@dev_router}: remove the /dev/mailbox Swoosh preview forward"

    assert has_node?(ast, fn
             {:get, _, ["/", {:__aliases__, _, [:PageController]}, :home | _]} -> true
             _ -> false
           end),
           "#{@dev_router}: standalone root route must remain"

    assert has_node?(ast, fn
             {:scrypath_ops_routes, _, ["/ops", _opts]} -> true
             _ -> false
           end),
           "#{@dev_router}: the supported /ops route mount must remain"

    assert has_node?(ast, fn
             {:live_dashboard, _, ["/dashboard", _opts]} -> true
             _ -> false
           end),
           "#{@dev_router}: standalone development dashboard must remain"

    assert has_node?(ast, fn
             {:live, _,
              [
                "/health",
                {:__aliases__, _, [:ScrypathOpsWeb, :PostureLive]},
                :phase173_fixture | _
              ]} ->
               true

             _ ->
               false
           end),
           "#{@dev_router}: the diagnostics test fixture route must remain"
  end

  test "mail configuration fixtures reject restored settings in every configuration site" do
    restored_swoosh_config = Code.string_to_quoted!("config :swoosh, :api_client, false")

    restored_mailer_config =
      Code.string_to_quoted!("config :scrypath_ops, mailer: ScrypathOps.Mailer")

    retained_host_config =
      Code.string_to_quoted!(
        "config :scrypath_ecommerce, ScrypathEcommerceWeb.Endpoint, adapter: Bandit.PhoenixAdapter"
      )

    for path <- @ops_config_files ++ @host_config_files do
      clean_ast = read_ast!(path)

      refute has_swoosh_config?(clean_ast), "#{path}: clean fixture must have no Swoosh config"
      refute has_mailer_module?(clean_ast), "#{path}: clean fixture must have no Mailer config"

      assert has_swoosh_config?(restored_swoosh_config),
             "#{path}: restored Swoosh client configuration must be detected"

      assert has_mailer_module?(restored_mailer_config),
             "#{path}: restored ScrypathOps.Mailer configuration must be detected"

      refute has_swoosh_config?(retained_host_config),
             "#{path}: unrelated host Endpoint configuration must remain allowed"
    end
  end

  test "mailbox route fixtures reject the removed path regardless of target alias" do
    clean_route = Code.string_to_quoted!("forward(\"/assets\", ScrypathOpsWeb.AssetPlug)")

    qualified_mailbox_route =
      Code.string_to_quoted!("forward(\"/mailbox\", Plug.Swoosh.MailboxPreview, [])")

    aliased_mailbox_route = Code.string_to_quoted!("forward(\"/mailbox\", MailboxPreview)")

    refute has_swoosh_mailbox_forward?(clean_route),
           "ordinary asset forwards must remain allowed"

    assert has_swoosh_mailbox_forward?(qualified_mailbox_route),
           "the qualified mailbox route fixture must be detected"

    assert has_swoosh_mailbox_forward?(aliased_mailbox_route),
           "the removed /dev/mailbox route must be rejected regardless of Plug alias form"
  end

  test "diagnostic dependencies are development-only and optional for mounted hosts" do
    for dependency <- [:phoenix_live_dashboard, :telemetry_metrics, :telemetry_poller] do
      options = dependency_options!(@ops_manifest, dependency)

      assert Keyword.get(options, :only) == :dev,
             "#{@ops_manifest}: #{dependency} must be available only during direct development"

      assert Keyword.get(options, :optional) == true,
             "#{@ops_manifest}: mounted hosts must not be forced to include #{dependency}"
    end
  end

  test "asset tools and host diagnostics stay development-only" do
    for path <- [@ops_manifest, @host_manifest], dependency <- [:esbuild, :tailwind] do
      options = dependency_options!(path, dependency)

      assert Keyword.get(options, :only) == :dev,
             "#{path}: #{dependency} must be available only in direct development"
    end

    for dependency <- [:phoenix_live_dashboard, :telemetry_metrics, :telemetry_poller] do
      options = dependency_options!(@host_manifest, dependency)

      assert Keyword.get(options, :only) == :dev,
             "#{@host_manifest}: #{dependency} must be development-only in the host graph"
    end
  end

  test "direct Req and Ops Telemetry requirements match the approved public contract" do
    for path <- [@root_manifest, @ops_manifest, @host_manifest] do
      assert direct_dependency_requirement!(path, :req) == "~> 0.6.1 or ~> 0.7",
             "#{path}: direct Req must admit exactly the approved requirement union"
    end

    assert direct_dependency_requirement!(@ops_manifest, :telemetry) == "~> 1.0",
           "#{@ops_manifest}: Ops directly calls Telemetry and must declare it"

    assert dependency_options!(@ops_manifest, :telemetry) == [],
           "#{@ops_manifest}: direct Telemetry must remain mandatory"
  end

  test "dev asset aliases preserve the configured Mix tools and output paths" do
    ops_manifest = read_ast!(@ops_manifest)
    host_manifest = read_ast!(@host_manifest)

    assert project_alias!(ops_manifest, "assets.setup") == [
             "tailwind.install --if-missing",
             "esbuild.install --if-missing"
           ]

    assert project_alias!(ops_manifest, "assets.build") == [
             "compile",
             "tailwind scrypath_ops",
             "esbuild scrypath_ops"
           ]

    assert project_alias!(ops_manifest, "assets.deploy") == [
             "tailwind scrypath_ops --minify",
             "esbuild scrypath_ops --minify",
             "phx.digest"
           ]

    assert project_alias!(host_manifest, "setup") == [
             "deps.get",
             "ecto.setup",
             "assets.setup",
             "assets.build"
           ]

    assert project_alias!(host_manifest, "assets.setup") == [
             "tailwind.install --if-missing",
             "esbuild.install --if-missing"
           ]

    assert project_alias!(host_manifest, "assets.build") == [
             "compile",
             "tailwind scrypath_ecommerce",
             "esbuild scrypath_ecommerce"
           ]

    for {manifest, task} <- [
          {ops_manifest, "assets.setup"},
          {ops_manifest, "assets.build"},
          {ops_manifest, "assets.deploy"},
          {host_manifest, "setup"},
          {host_manifest, "assets.setup"},
          {host_manifest, "assets.build"}
        ] do
      assert preferred_env!(manifest, task) == :dev,
             "#{task}: asset generation aliases must default to MIX_ENV=dev"
    end

    for path <- [@ops_asset_config, @host_asset_config] do
      source = File.read!(path)

      assert source =~ ~s(version: "0.25.4"), "#{path}: keep the approved esbuild authority"
      assert source =~ ~s(version: "4.1.12"), "#{path}: keep the approved Tailwind authority"

      assert source =~ "--outdir=../priv/static/assets/js",
             "#{path}: keep the configured JavaScript output location"

      assert source =~ "--output=priv/static/assets/css/app.css",
             "#{path}: keep the configured CSS output location"
    end
  end

  test "diagnostic compilation, plugs, child startup, and dev routes share capability guards" do
    telemetry_ast = read_ast!(@telemetry_source)
    application_ast = read_ast!(@application_source)
    endpoint_ast = read_ast!(@endpoint_source)
    dev_router_ast = read_ast!(@dev_router)

    assert conditional_has_calls_and_body?(
             telemetry_ast,
             [
               {[:Code], :ensure_loaded?,
                fn args -> alias_argument?(args, [:Telemetry, :Metrics]) end}
             ],
             fn
               {:defmodule, _, [{:__aliases__, _, [:ScrypathOpsWeb, :Telemetry]} | _]} -> true
               _ -> false
             end
           ),
           "#{@telemetry_source}: module compilation must require Telemetry.Metrics"

    assert conditional_has_calls_and_body?(
             application_ast,
             [
               {[:Code], :ensure_loaded?,
                fn args ->
                  alias_argument?(args, [:ScrypathOpsWeb, :Telemetry])
                end}
             ],
             fn
               {:__aliases__, _, [:ScrypathOpsWeb, :Telemetry]} -> true
               _ -> false
             end
           ),
           "#{@application_source}: the diagnostics child must require its compiled module"

    assert conditional_has_calls_and_body?(
             endpoint_ast,
             [
               {[:Code], :ensure_loaded?,
                fn args ->
                  alias_argument?(args, [:Phoenix, :LiveDashboard, :RequestLogger])
                end}
             ],
             fn
               {:plug, _, [{:__aliases__, _, [:Phoenix, :LiveDashboard, :RequestLogger]} | _]} ->
                 true

               _ ->
                 false
             end
           ),
           "#{@endpoint_source}: RequestLogger must be installed only when available"

    assert has_node?(dev_router_ast, fn node ->
             remote_call?(node, [:Application], :compile_env, fn args ->
               args == [:scrypath_ops, :dev_routes]
             end)
           end),
           "#{@dev_router}: route policy must be tracked as a compile-time configuration input"

    assert has_node?(dev_router_ast, fn
             {{:., _,
               [{:__aliases__, _, [:ScrypathOpsWeb, :OptionalDevRoutes]}, :dashboard_routes]}, _,
              [policy_ast]} ->
               has_node?(policy_ast, fn node ->
                 remote_call?(node, [:Application], :compile_env, fn args ->
                   args == [:scrypath_ops, :dev_routes]
                 end)
               end)

             _ ->
               false
           end),
           "#{@dev_router}: compile-time dev_routes policy must gate dashboard macro expansion"

    assert conditional_has_calls_and_body?(
             dev_router_ast,
             [
               {[:Code], :ensure_loaded?,
                fn args ->
                  alias_argument?(args, [:Phoenix, :LiveDashboard, :Router])
                end}
             ],
             fn
               {:live_dashboard, _, ["/dashboard", _opts]} -> true
               _ -> false
             end
           ),
           "#{@dev_router}: dashboard route must require both availability and dev_routes policy"
  end

  defp direct_dependency_names!(path) do
    deps_body =
      path
      |> read_ast!()
      |> find_deps_body!()

    case deps_body do
      deps when is_list(deps) -> Enum.flat_map(deps, &dependency_name/1)
      other -> flunk("#{path}: expected a literal deps list, got #{Macro.to_string(other)}")
    end
  end

  defp dependency_options!(path, dependency) do
    deps_body = path |> read_ast!() |> find_deps_body!()

    Enum.find_value(deps_body, fn
      {^dependency, _version} -> []
      {:{}, _, [^dependency, _version, options]} when is_list(options) -> options
      {:{}, _, [^dependency, options]} when is_list(options) -> options
      _ -> nil
    end) || flunk("#{path}: expected direct dependency #{dependency}")
  end

  defp direct_dependency_requirement!(path, dependency) do
    deps_body = path |> read_ast!() |> find_deps_body!()

    Enum.find_value(deps_body, fn
      {^dependency, requirement} when is_binary(requirement) -> requirement
      {:{}, _, [^dependency, requirement | _]} when is_binary(requirement) -> requirement
      _ -> nil
    end) || flunk("#{path}: expected direct dependency #{dependency} with a literal requirement")
  end

  defp project_alias!(ast, alias_name) do
    aliases = ast |> project_function_body!(:aliases)
    key = String.to_atom(alias_name)

    Enum.find_value(aliases, fn
      {^key, commands} -> commands
      _ -> nil
    end) || flunk("expected Mix alias #{alias_name}")
  end

  defp preferred_env!(ast, task_name) do
    cli_options = ast |> project_function_body!(:cli)
    preferred_envs = Keyword.fetch!(cli_options, :preferred_envs)
    key = String.to_atom(task_name)

    Enum.find_value(preferred_envs, fn
      {^key, env} -> env
      _ -> nil
    end) || flunk("expected preferred environment for Mix task #{task_name}")
  end

  defp project_function_body!(ast, name) do
    {_ast, body} =
      Macro.prewalk(ast, nil, fn
        {visibility, _, [{^name, _, nil}, [do: body]]} = node, nil
        when visibility in [:def, :defp] ->
          {node, body}

        node, body ->
          {node, body}
      end)

    if is_nil(body), do: flunk("expected project function #{name}/0"), else: body
  end

  defp conditional_has_calls_and_body?(ast, calls, body_predicate) do
    has_node?(ast, fn
      {:if, _, [condition, clauses]} when is_list(clauses) ->
        Enum.all?(calls, fn {module, function, argument_predicate} ->
          has_node?(condition, &remote_call?(&1, module, function, argument_predicate))
        end) and has_node?(clauses, body_predicate)

      _ ->
        false
    end)
  end

  defp remote_call?(
         {{:., _, [{:__aliases__, _, module}, function]}, _, args},
         module,
         function,
         argument_predicate
       ) do
    argument_predicate.(args)
  end

  defp remote_call?(_node, _module, _function, _argument_predicate), do: false

  defp alias_argument?(args, expected_alias) do
    Enum.any?(args, fn
      {:__aliases__, _, ^expected_alias} -> true
      _ -> false
    end)
  end

  defp find_deps_body!(ast) do
    {_ast, body} =
      Macro.prewalk(ast, nil, fn
        {:defp, _, [{:deps, _, nil}, [do: body]]} = node, nil -> {node, body}
        node, body -> {node, body}
      end)

    if is_nil(body), do: flunk("expected a private deps/0 function"), else: body
  end

  defp dependency_name({name, _version}) when is_atom(name), do: [name]
  defp dependency_name({:{}, _, [name | _]}) when is_atom(name), do: [name]
  defp dependency_name(_entry), do: []

  defp read_ast!(path) do
    path
    |> File.read!()
    |> Code.string_to_quoted!(file: path)
  end

  defp has_swoosh_config?(ast) do
    has_node?(ast, fn
      {:config, _, [:swoosh | _]} -> true
      _ -> false
    end)
  end

  defp has_mailer_module?(ast) do
    has_node?(ast, fn
      {:__aliases__, _, [:ScrypathOps, :Mailer]} -> true
      _ -> false
    end)
  end

  defp has_swoosh_mailbox_forward?(ast) do
    has_node?(ast, fn
      {:forward, _, ["/mailbox", _target | _]} ->
        true

      _ ->
        false
    end)
  end

  defp has_node?(ast, predicate) do
    {_ast, found?} =
      Macro.prewalk(ast, false, fn node, found? ->
        {node, found? or predicate.(node)}
      end)

    found?
  end
end
