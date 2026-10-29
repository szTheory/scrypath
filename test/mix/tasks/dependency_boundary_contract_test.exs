defmodule Scrypath.Repository.DependencyBoundaryContractTest do
  use ExUnit.Case, async: true

  @ops_manifest "scrypath_ops/mix.exs"
  @host_manifest "examples/scrypath_ecommerce/mix.exs"
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
      {:forward, _, ["/mailbox", {:__aliases__, _, [:Plug, :Swoosh, :MailboxPreview]} | _]} ->
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
