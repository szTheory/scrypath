defmodule Scrypath.Repository.DependencyBoundaryContractTest do
  use ExUnit.Case, async: true

  @ops_manifest "scrypath_ops/mix.exs"
  @host_manifest "examples/scrypath_ecommerce/mix.exs"
  @root_manifest "mix.exs"
  @support_guide "guides/support-and-compatibility.md"
  @action_dispositions ".planning/milestones/v1.45-phases/184-explicit-and-lean-dependency-graphs/184-ACTIONS-DISPOSITIONS.md"
  @dependency_evidence ".planning/milestones/v1.45-phases/184-explicit-and-lean-dependency-graphs/184-DEPENDENCY-EVIDENCE.md"
  @action_pr_ids ~w(65 68 69 70 71 72 73 74 75 76)
  @dependency_graph_ids [
    ".",
    "examples/phoenix_meilisearch",
    "examples/scrypath_ecommerce",
    "scrypath_ops"
  ]
  @ops_asset_config "scrypath_ops/config/config.exs"
  @host_asset_config "examples/scrypath_ecommerce/config/config.exs"
  @host_prod_config "examples/scrypath_ecommerce/config/prod.exs"
  @host_runtime_config "examples/scrypath_ecommerce/config/runtime.exs"
  @host_test_config "examples/scrypath_ecommerce/config/test.exs"
  @ops_config_files [
    "scrypath_ops/config/config.exs",
    "scrypath_ops/config/dev.exs",
    "scrypath_ops/config/test.exs",
    "scrypath_ops/config/prod.exs",
    "scrypath_ops/config/runtime.exs"
  ]
  @host_config_files [
    "examples/scrypath_ecommerce/config/config.exs",
    "examples/scrypath_ecommerce/config/dev.exs",
    @host_prod_config,
    @host_runtime_config,
    @host_test_config
  ]
  @mailbox_source "scrypath_ops/lib/scrypath_ops/mailer.ex"
  @mailbox_test "scrypath_ops/test/scrypath_ops/swoosh_api_client_req_test.exs"
  @dev_router "scrypath_ops/lib/scrypath_ops_web/dev_router.ex"
  @catalog_routes_source "scrypath_ops/lib/scrypath_ops_web/optional_catalog_routes.ex"
  @boundary_script "examples/scrypath_ecommerce/scripts/verify-dependency-boundaries.sh"
  @boundary_dockerfile "examples/scrypath_ecommerce/Dockerfile"
  @fixtures_copy "COPY fixtures/scrypath_fixtures/mix.exs ./fixtures/scrypath_fixtures/"
  @telemetry_source "scrypath_ops/lib/scrypath_ops_web/telemetry.ex"
  @application_source "scrypath_ops/lib/scrypath_ops/application.ex"
  @endpoint_source "scrypath_ops/lib/scrypath_ops_web/endpoint.ex"
  @static_contract_files [
    "examples/scrypath_ecommerce/Dockerfile",
    "examples/scrypath_ecommerce/docker-e2e-entrypoint.sh",
    "examples/scrypath_ecommerce/scripts/phase173-standalone-entrypoint.sh",
    "examples/scrypath_ecommerce/config/prod.exs",
    "examples/scrypath_ecommerce/config/runtime.exs",
    "scrypath_ops/config/prod.exs",
    "scrypath_ops/config/runtime.exs"
  ]

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

  test "current support guidance separates admitted ranges, witnesses, tiers, and audit status" do
    support = File.read!(@support_guide)
    ops_readme = File.read!("scrypath_ops/README.md") |> String.replace(~r/\s+/, " ")
    phoenix_readme = File.read!("examples/phoenix_meilisearch/README.md")

    assert support =~ ~r/\{:telemetry,\s+"~> 1\.0"\}/
    assert support =~ ~r/\{:req,\s+"~> 0\.6\.1 or ~> 0\.7"\}/
    assert support =~ "`~> 0.7` admits stable releases starting at 0.7.0 and below 1.0.0"
    assert support =~ ~r/two concrete\s+witnesses, Req 0\.6\.3 and Req 0\.7\.5/
    assert support =~ "These are discrete tuples, not"
    assert support =~ "As of **2026-10-30**"
    assert support =~ "no longer supported** by the upstream project"

    assert support =~
             "does not change the root\nlibrary's Elixir 1.17 floor or establish an OTP 27 minimum"

    assert support =~ "The root, Phoenix example, and ecommerce graph audits were clean."
    assert support =~ "The ScrypathOps audit remains affected and nonzero"
    assert support =~ "EEF-CVE-2026-95105"
    assert support =~ "EEF-CVE-2026-94206"
    assert support =~ "That fix does not clear the Cloak findings"

    assert support =~
             "Dependency\nand support changes become Hex-package claims only after a release"

    # The link is absolute on purpose: `../scrypath_ops/README.md` would resolve to the Scrypath
    # README page on HexDocs (ExDoc maps any README.md basename to the landing page), and the
    # built-docs link scan in package_metadata_test.exs rejects it.
    assert support =~
             "[ScrypathOps production runbook](https://github.com/szTheory/scrypath/blob/main/scrypath_ops/README.md#production)"

    assert ops_readme =~ "[security boundary](docs/SECURITY.md)"
    assert ops_readme =~ "**Elixir** 1.18+ for the default standalone checkout"
    assert ops_readme =~ "includes optional Sigra"
    assert ops_readme =~ "root library and mounted hosts without Sigra retain Elixir 1.17"

    assert phoenix_readme =~
             "[support and compatibility guide](../../guides/support-and-compatibility.md)"

    for target <- [
          "scrypath_ops/README.md",
          "scrypath_ops/docs/SECURITY.md",
          "examples/phoenix_meilisearch/README.md"
        ] do
      assert File.regular?(target), "current support link must resolve: #{target}"
    end
  end

  test "all ten dependency proposals have source-bound complete dispositions" do
    rows = markdown_table_rows!(@action_dispositions, "## Ten Dependabot PR dispositions")

    assert Enum.map(rows, &action_pr_id!/1) == @action_pr_ids
    assert action_disposition_errors(rows) == []

    for [pr, proposal, disposition, version, source, evidence, reason, trigger] <- rows do
      assert pr =~ ~r/\[#\d+\]/
      assert proposal =~ "open"
      assert disposition =~ ~r/\A(?:Incorporated|Adopted|Superseded)/
      assert version =~ ~r/\d/
      assert source =~ ~r/\]\(https?:\/\//
      assert String.length(evidence) > 10
      assert String.length(reason) > 10
      assert String.length(trigger) > 10
    end

    assert "missing PR disposition: #76" in action_disposition_errors(Enum.drop(rows, -1))
    assert "duplicate PR disposition: #65" in action_disposition_errors(rows ++ [hd(rows)])

    empty_disposition = List.update_at(hd(rows), 2, &String.replace(&1, &1, ""))

    assert "empty disposition for PR #65" in action_disposition_errors([
             empty_disposition | tl(rows)
           ])
  end

  test "all four dependency audit records bind stable locks and raw evidence" do
    rows =
      markdown_table_rows!(
        @dependency_evidence,
        "## Final four-graph audit receipt — Plan 184-10"
      )

    assert Enum.map(rows, &dependency_graph_id!/1) == @dependency_graph_ids
    assert dependency_graph_record_errors(rows) == []
    assert Enum.map(rows, &Enum.at(&1, 9)) == ["clean", "clean", "clean", "affected"]
    assert Enum.map(rows, &Enum.at(&1, 8)) == ["0", "0", "0", "1"]

    assert "missing dependency graph record: scrypath_ops" in dependency_graph_record_errors(
             Enum.drop(rows, -1)
           )

    assert "duplicate dependency graph record: ." in dependency_graph_record_errors(
             rows ++ [hd(rows)]
           )

    empty_receipt = List.update_at(hd(rows), 10, &String.replace(&1, &1, ""))

    assert "empty raw evidence reference for dependency graph: ." in dependency_graph_record_errors(
             [empty_receipt | tl(rows)]
           )
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

  test "ecommerce production configuration uses a static manifest and explicit runtime inputs" do
    prod_ast = read_ast!(@host_prod_config)
    runtime_ast = read_ast!(@host_runtime_config)
    test_ast = read_ast!(@host_test_config)

    assert host_production_config_valid?(prod_ast),
           "#{@host_prod_config}: production must disable dev behavior and name its static manifest"

    assert host_production_runtime_valid?(runtime_ast),
           "#{@host_runtime_config}: production Repo and Endpoint must use explicit runtime inputs"

    assert config_value?(test_ast, :scrypath_ecommerce, nil, :sandbox, true),
           "#{@host_test_config}: normal tests must keep the SQL Sandbox enabled"

    assert config_value?(runtime_ast, :scrypath_ecommerce, nil, :sandbox, false),
           "#{@host_runtime_config}: the explicit E2E test override must remain available"

    assert has_env_read?(runtime_ast, "SCRYPATH_E2E_NO_SANDBOX"),
           "#{@host_runtime_config}: the non-sandbox override must stay limited to its test input"
  end

  test "production configuration mutations reject copied secrets, sandbox settings, and missing inputs" do
    prod_source = File.read!(@host_prod_config)
    runtime_source = File.read!(@host_runtime_config)

    copied_secret =
      String.replace(
        prod_source,
        "watchers: [],",
        "watchers: [], secret_key_base: \"copied test secret\","
      )

    assert copied_secret != prod_source
    refute host_production_config_valid?(Code.string_to_quoted!(copied_secret))

    sandbox_config = prod_source <> "\nconfig :scrypath_ecommerce, sandbox: true\n"
    refute host_production_config_valid?(Code.string_to_quoted!(sandbox_config))

    missing_secret =
      String.replace(
        runtime_source,
        "System.fetch_env!(\"SECRET_KEY_BASE\")",
        "\"hardcoded test secret\""
      )

    assert missing_secret != runtime_source
    refute host_production_runtime_valid?(Code.string_to_quoted!(missing_secret))
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
                fn args -> alias_argument?(args, [:Telemetry, :Metrics]) end},
               {[:Code], :ensure_loaded?, fn args -> args == [:telemetry_poller] end}
             ],
             fn
               {:defmodule, _, [{:__aliases__, _, [:ScrypathOpsWeb, :Telemetry]} | _]} -> true
               _ -> false
             end
           ),
           "#{@telemetry_source}: diagnostics must require both metrics and the poller"

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

  test "static dependency handoff checker accepts clean output-only targets and rejects mutations" do
    source_root = Path.expand("../../..", __DIR__)

    checker =
      Path.join(
        source_root,
        "examples/scrypath_ecommerce/scripts/verify-dependency-boundaries.sh"
      )

    assert File.regular?(checker),
           "the repository must provide the static dependency boundary checker"

    fixture_parent =
      Path.join(
        System.tmp_dir!(),
        "scrypath-dependency-boundary-#{System.unique_integer([:positive])}"
      )

    File.mkdir_p!(fixture_parent)
    on_exit(fn -> File.rm_rf!(fixture_parent) end)

    clean_fixture = dependency_boundary_fixture!(source_root, Path.join(fixture_parent, "clean"))
    {clean_output, clean_status} = run_static_dependency_contract(clean_fixture)

    assert clean_status == 0, clean_output
    assert clean_output =~ "Static dependency boundary contract passed"

    {usage_output, usage_status} =
      run_static_dependency_contract(clean_fixture, ["--static-contract-only", "extra"])

    assert usage_status == 64, usage_output

    mutations = [
      {"builder dependency transfer",
       fn fixture ->
         append_dependency_boundary_text!(
           fixture,
           "examples/scrypath_ecommerce/Dockerfile",
           "\nCOPY --from=asset_builder /app/scrypath_ops/deps /app/scrypath_ops/deps\n"
         )
       end},
      {"missing CSS output declaration",
       fn fixture ->
         replace_dependency_boundary_text!(
           fixture,
           "examples/scrypath_ecommerce/Dockerfile",
           " && test -s /app/examples/scrypath_ecommerce/priv/static/assets/css/app.css",
           ""
         )
       end},
      {"wrong runtime environment",
       fn fixture ->
         replace_dependency_boundary_text!(
           fixture,
           "examples/scrypath_ecommerce/Dockerfile",
           "ENV MIX_ENV=test ",
           "ENV MIX_ENV=prod "
         )
       end},
      {"runtime wrapper installation",
       fn fixture ->
         append_dependency_boundary_text!(
           fixture,
           "examples/scrypath_ecommerce/docker-e2e-entrypoint.sh",
           "\nmix esbuild.install --if-missing\n"
         )
       end}
    ]

    for {mutation, mutate_fixture} <- mutations do
      fixture =
        dependency_boundary_fixture!(
          source_root,
          Path.join(fixture_parent, String.replace(mutation, " ", "-"))
        )

      mutate_fixture.(fixture)
      {output, status} = run_static_dependency_contract(fixture)

      assert status != 0, "#{mutation} unexpectedly passed:\n#{output}"
    end
  end

  test "parallel Docker targets serialize writers to the shared Hex registry cache" do
    dockerfile = File.read!("examples/scrypath_ecommerce/Dockerfile")

    hex_mounts =
      dockerfile
      |> String.split("\n")
      |> Enum.filter(&String.contains?(&1, "--mount=type=cache,target=/root/.hex"))

    assert length(hex_mounts) == 3
    assert Enum.all?(hex_mounts, &String.contains?(&1, "sharing=locked"))
  end

  # Static boundary checks for the catalog. The dependency is present since v1.49 Phase 195, so every
  # check here is real, and each one has a planted failing case proving it can fail. This is the existing
  # ledger row "Storybook boundary" (gate 4 of the v1.46 required-gate budget, see "Required-gate budget"
  # in CONTRIBUTING.md), not a new gate.
  describe "storybook boundary (catalog, v1.49 Phase 195)" do
    test "root lib never mentions the storybook" do
      paths = Path.wildcard("lib/**/*.{ex,exs}")
      assert paths != [], "expected root lib sources to scan"

      mentions = paths |> Enum.map(&{&1, File.read!(&1)}) |> storybook_mentions()

      assert mentions == [],
             "the published package must not reference the storybook: #{inspect(mentions)}"
    end

    test "root manifest does not depend on the storybook" do
      refute :phoenix_storybook in direct_dependency_names!(@root_manifest),
             "#{@root_manifest}: the storybook belongs to scrypath_ops only, never the Hex package"
    end

    test "ScrypathOps storybook dependency is dev and test only" do
      assert storybook_dependency_violation(@ops_manifest) == nil
    end

    test "planted storybook mention and unrestricted dependency are flagged" do
      sources = [
        {"lib/planted_module.ex", "alias PhoenixStorybook.Component"},
        {"lib/planted_package.ex", "# uses phoenix_storybook somewhere"},
        {"lib/clean.ex", "defmodule Clean do\nend\n"}
      ]

      assert storybook_mentions(sources) == ["lib/planted_module.ex", "lib/planted_package.ex"]

      tmp =
        Path.join(System.tmp_dir!(), "storybook-boundary-#{System.unique_integer([:positive])}")

      File.mkdir_p!(tmp)
      on_exit(fn -> File.rm_rf(tmp) end)

      manifest = fn name, dependency_line ->
        path = Path.join(tmp, name)

        File.write!(path, """
        defmodule Planted.MixProject do
          defp deps do
            [
              {:phoenix, "~> 1.7"},
              #{dependency_line}
            ]
          end
        end
        """)

        path
      end

      unrestricted = manifest.("unrestricted.exs", ~s({:phoenix_storybook, "~> 1.5"}))
      dev_only = manifest.("dev_only.exs", ~s({:phoenix_storybook, "~> 1.5", only: :dev}))

      all_envs =
        manifest.("all_envs.exs", ~s({:phoenix_storybook, "~> 1.5", only: [:dev, :test, :prod]}))

      compliant =
        manifest.("compliant.exs", ~s({:phoenix_storybook, "~> 1.5", only: [:test, :dev]}))

      absent = manifest.("absent.exs", ~s({:jason, "~> 1.4"}))

      wrong_requirement =
        manifest.(
          "wrong_requirement.exs",
          ~s({:phoenix_storybook, "~> 1.4", only: [:dev, :test]})
        )

      assert storybook_dependency_violation(unrestricted) =~ "only: [:dev, :test]"
      assert storybook_dependency_violation(dev_only) =~ "only: [:dev, :test]"
      assert storybook_dependency_violation(all_envs) =~ "only: [:dev, :test]"
      assert storybook_dependency_violation(wrong_requirement) =~ "~> 1.5"
      assert storybook_dependency_violation(compliant) == nil
      assert storybook_dependency_violation(absent) =~ "must declare"
    end

    test "catalog route guard sits outside the quote and fails when moved, deleted, flag-blind or untracked" do
      ast = read_ast!(@catalog_routes_source)

      assert catalog_guard_violation(ast) == nil

      for mutation <- [
            :delete_guard,
            :move_guard_inside_quote,
            :drop_flag_read,
            :untrack_flag_read
          ] do
        mutated = mutate_catalog_guard(ast, mutation)

        assert mutated != ast, "mutation #{mutation} left the AST unchanged"

        assert catalog_guard_violation(mutated) =~ "route guard",
               "mutation #{mutation} must be reported as a route guard violation"
      end
    end

    test "the dev router mounts the catalog only through the guarded macro" do
      dev_router_ast = read_ast!(@dev_router)

      assert has_node?(dev_router_ast, fn node ->
               remote_call?(
                 node,
                 [:ScrypathOpsWeb, :OptionalCatalogRoutes],
                 :catalog_routes,
                 fn args -> args == [] end
               )
             end),
             "#{@dev_router}: the catalog mount must go through OptionalCatalogRoutes.catalog_routes()"

      refute has_node?(dev_router_ast, fn
               {:live_storybook, _, _} -> true
               {:__aliases__, _, [:PhoenixStorybook | _]} -> true
               _ -> false
             end),
             "#{@dev_router}: the router must not name the storybook itself; only the guarded macro does"
    end

    test "the Docker boundary script forbids the catalog in prod and host graphs and requires a 404" do
      script = File.read!(@boundary_script)

      assert storybook_script_violations(script) == []

      {output, status} = System.cmd("bash", ["-n", @boundary_script], stderr_to_stdout: true)
      assert status == 0, "#{@boundary_script} has a shell syntax error: #{output}"

      # Planted: each edit below removes one thing the script must prove, so each must be reported.
      mutants = [
        {~s(forbidden_deps="$forbidden_deps phoenix_storybook mdex mdex_native"),
         ~s(forbidden_deps="$forbidden_deps phoenix_storybook mdex")},
        {~s(forbidden_deps="esbuild tailwind phoenix_live_dashboard telemetry_metrics telemetry_poller"),
         ~s(forbidden_deps="esbuild tailwind phoenix_live_dashboard telemetry_metrics telemetry_poller phoenix_storybook mdex mdex_native")},
        {", PhoenixStorybook, MDEx]", ", PhoenixStorybook]"},
        {~s("host|$base_url" "ops|$ops_base_url"), ~s("host|$base_url")}
      ]

      tmp = Path.join(System.tmp_dir!(), "storybook-script-#{System.unique_integer([:positive])}")
      File.mkdir_p!(tmp)
      on_exit(fn -> File.rm_rf(tmp) end)

      for {from, to} <- mutants do
        mutated = String.replace(script, from, to)
        assert mutated != script, "planted edit found nothing to change: #{from}"

        # Each mutant must be well-formed shell, so the check is caught by the one thing it removed and
        # not by a syntax break that happens to defeat a regex.
        mutant_path = Path.join(tmp, "mutant.sh")
        File.write!(mutant_path, mutated)
        {output, status} = System.cmd("bash", ["-n", mutant_path], stderr_to_stdout: true)
        assert status == 0, "planted edit is malformed shell (#{from} -> #{to}): #{output}"

        assert storybook_script_violations(mutated) != [],
               "the script check accepted a planted edit: #{from} -> #{to}"
      end
    end

    test "catalog flag is off whenever the test endpoint is not loopback" do
      test_unset = read_catalog_bind!("scrypath_ops/config/test.exs", :test, nil)
      test_served = read_catalog_bind!("scrypath_ops/config/test.exs", :test, "true")
      dev = read_catalog_bind!("scrypath_ops/config/dev.exs", :dev, nil)

      assert test_unset == {{127, 0, 0, 1}, true}
      assert test_served == {{0, 0, 0, 0}, false}
      assert dev == {{127, 0, 0, 1}, true}

      for bind <- [test_unset, test_served, dev] do
        assert catalog_bind_violation(bind) == nil
      end

      # Planted: a non-loopback bind with the catalog on, and an unset bind, are violations.
      assert catalog_bind_violation({{0, 0, 0, 0}, true}) =~ "loopback"
      assert catalog_bind_violation({nil, true}) =~ "loopback"
      assert catalog_bind_violation({{0, 0, 0, 0}, false}) == nil
    end
  end

  # Static boundary checks for the fixtures project (ADR 0002, v1.49 Phase 196). It is a dev and test path
  # dependency of Ops: it must stay out of the Hex package (package_metadata_test), every mounted consumer,
  # production graph and the prod image. A path dependency is in no lock, so these rows read the manifest
  # options and the scripts directly, and the integration probes (ops_dependency_boundary_test) check the
  # built graphs. Each check has a planted failing case that asserts its own cause, not only "a violation".
  describe "fixtures boundary (ADR 0002, v1.49 Phase 196)" do
    test "the Ops manifest declares the fixtures path dependency for dev and test only" do
      assert path_dependency_options!(@ops_manifest, :scrypath_fixtures) ==
               [path: "../fixtures/scrypath_fixtures", only: [:dev, :test]]

      assert fixtures_dependency_violation(@ops_manifest) == nil
    end

    test "neither the root manifest nor the host depends on the fixtures project" do
      for manifest <- [@root_manifest, @host_manifest] do
        refute :scrypath_fixtures in direct_dependency_names!(manifest),
               "#{manifest}: the fixtures project belongs to scrypath_ops only"
      end
    end

    test "planted manifests are each rejected for their own cause" do
      tmp =
        Path.join(System.tmp_dir!(), "fixtures-boundary-#{System.unique_integer([:positive])}")

      File.mkdir_p!(tmp)
      on_exit(fn -> File.rm_rf(tmp) end)

      path = ~s(path: "../fixtures/scrypath_fixtures")
      manifest = fn name, line -> write_planted_manifest!(tmp, name, line) end

      compliant = manifest.("compliant.exs", "{:scrypath_fixtures, #{path}, only: [:test, :dev]}")
      absent = manifest.("absent.exs", ~s({:jason, "~> 1.4"}))
      unrestricted = manifest.("unrestricted.exs", "{:scrypath_fixtures, #{path}}")
      dev_only = manifest.("dev_only.exs", "{:scrypath_fixtures, #{path}, only: :dev}")

      all_envs =
        manifest.("all_envs.exs", "{:scrypath_fixtures, #{path}, only: [:dev, :test, :prod]}")

      wrong_path =
        manifest.(
          "wrong_path.exs",
          ~s({:scrypath_fixtures, path: "../fixtures/other", only: [:dev, :test]})
        )

      hex_two = manifest.("hex_two.exs", ~s({:scrypath_fixtures, "~> 0.1"}))

      hex_three =
        manifest.("hex_three.exs", ~s({:scrypath_fixtures, "~> 0.1", only: [:dev, :test]}))

      assert fixtures_dependency_violation(compliant) == nil

      assert fixtures_dependency_violation(absent) ==
               "#{absent}: the manifest must declare the fixtures dependency, but :scrypath_fixtures is absent"

      only_message = fn file, got ->
        "#{file}: the fixtures dependency must declare only: [:dev, :test], got #{got}"
      end

      assert fixtures_dependency_violation(unrestricted) == only_message.(unrestricted, "nil")
      assert fixtures_dependency_violation(dev_only) == only_message.(dev_only, ":dev")

      assert fixtures_dependency_violation(all_envs) ==
               only_message.(all_envs, "[:dev, :test, :prod]")

      path_message = fn file, got ->
        "#{file}: the fixtures dependency must use path: \"../fixtures/scrypath_fixtures\", got #{got}"
      end

      assert fixtures_dependency_violation(wrong_path) ==
               path_message.(wrong_path, ~s("../fixtures/other"))

      assert fixtures_dependency_violation(hex_two) == path_message.(hex_two, "nil")
      assert fixtures_dependency_violation(hex_three) == path_message.(hex_three, "nil")
    end

    test "root lib and scrypath_ops lib never mention the fixtures project" do
      root = Path.wildcard("lib/**/*.{ex,exs}")
      ops = Path.wildcard("scrypath_ops/lib/**/*.{ex,exs}")
      assert root != [] and ops != [], "expected sources under lib/ and scrypath_ops/lib/"

      mentions = (root ++ ops) |> Enum.map(&{&1, File.read!(&1)}) |> fixtures_mentions()

      assert mentions == [],
             "a fixtures name in a production source breaks the prod compile and the Hex package: #{inspect(mentions)}"
    end

    test "planted mentions are reported by exact path" do
      sources = [
        {"lib/planted_module.ex", "alias ScrypathFixtures.Logistify"},
        {"scrypath_ops/lib/planted_task.ex",
         ~s[Mix.Task.run("scrypath_fixtures.check_fixtures")]},
        {"lib/clean.ex", "defmodule Clean do\nend\n"}
      ]

      assert fixtures_mentions(sources) == [
               "lib/planted_module.ex",
               "scrypath_ops/lib/planted_task.ex"
             ]
    end

    test "the Docker boundary script forbids the fixtures project in prod and host graphs" do
      script = File.read!(@boundary_script)

      assert fixtures_script_violations(script) == []

      # Planted: each edit removes one thing the script must prove. It must stay well-formed shell and leave the
      # catalog checks untouched, so that exactly the one fixtures message names what was removed.
      mutants = [
        {"the fixtures if-block", ~s(forbidden_deps="$forbidden_deps scrypath_fixtures"), ":",
         "its own if block"},
        {"the shared list",
         ~s(forbidden_deps="esbuild tailwind phoenix_live_dashboard telemetry_metrics telemetry_poller"),
         ~s(forbidden_deps="esbuild tailwind phoenix_live_dashboard telemetry_metrics telemetry_poller scrypath_fixtures"),
         "shared forbidden list must not contain scrypath_fixtures"},
        {"ScrypathFixtures in forbidden_modules", ", ScrypathFixtures, PhoenixStorybook, MDEx]",
         ", PhoenixStorybook, MDEx]", "must forbid the ScrypathFixtures module"},
        {"the prod _build check", ~s(if [ "$MIX_ENV" = "prod" ]; then),
         ~s(if [ "$MIX_ENV" = "test" ]; then), "_build/prod/lib/scrypath_fixtures"},
        {"the prod _build path", "/app/scrypath_ops/_build/prod/lib/scrypath_fixtures",
         "/app/scrypath_ops/_build/test/lib/scrypath_fixtures",
         "_build/prod/lib/scrypath_fixtures"}
      ]

      tmp = Path.join(System.tmp_dir!(), "fixtures-script-#{System.unique_integer([:positive])}")
      File.mkdir_p!(tmp)
      on_exit(fn -> File.rm_rf(tmp) end)

      for {removed, from, to, fragment} <- mutants do
        mutated = String.replace(script, from, to)
        assert mutated != script, "planted edit (#{removed}) found nothing to change: #{from}"

        mutant_path = Path.join(tmp, "mutant.sh")
        File.write!(mutant_path, mutated)
        {output, status} = System.cmd("bash", ["-n", mutant_path], stderr_to_stdout: true)
        assert status == 0, "planted edit (#{removed}) is malformed shell: #{output}"

        assert [message] = fixtures_script_violations(mutated),
               "removing #{removed} must be reported by exactly one fixtures message"

        assert message =~ fragment, "removing #{removed} was reported as: #{message}"

        assert storybook_script_violations(mutated) == [],
               "removing #{removed} must not disturb the catalog checks"
      end
    end

    test "the Dockerfile copies the fixtures manifest in each stage that resolves Ops" do
      dockerfile = File.read!(@boundary_dockerfile)

      assert Enum.map(dockerfile_stages(dockerfile), &elem(&1, 0)) ==
               ["beam_base", "asset_builder", "runtime_prod", "runtime_test"]

      assert fixtures_dockerfile_violations(dockerfile) == []

      # Planted: each edit removes or misplaces the line in exactly one stage.
      for stage <- ["asset_builder", "runtime_prod", "runtime_test"] do
        removed =
          edit_dockerfile_stage(
            dockerfile,
            stage,
            &String.replace(&1, @fixtures_copy <> "\n", "")
          )

        refute removed == dockerfile, "removing the fixtures COPY from #{stage} changed nothing"

        assert fixtures_dockerfile_violations(removed) ==
                 [
                   "stage #{stage} copies scrypath_ops/mix.exs but has no `#{@fixtures_copy}` line"
                 ]

        late =
          edit_dockerfile_stage(dockerfile, stage, fn text ->
            text
            |> String.replace(@fixtures_copy <> "\n", "")
            |> then(
              &Regex.replace(~r/\nCOPY (--exclude=\S+ )?\. \.\n/, &1, "\n#{@fixtures_copy}\n\\0")
            )
          end)

        refute late == dockerfile, "moving the fixtures COPY in #{stage} changed nothing"

        assert fixtures_dockerfile_violations(late) ==
                 ["stage #{stage} must copy the fixtures manifest before its first mix deps.get"]

        doubled =
          edit_dockerfile_stage(
            dockerfile,
            stage,
            &String.replace(
              &1,
              @fixtures_copy <> "\n",
              @fixtures_copy <> "\n" <> @fixtures_copy <> "\n"
            )
          )

        assert fixtures_dockerfile_violations(doubled) ==
                 ["stage #{stage} copies the fixtures manifest more than once"]
      end
    end

    test ".dockerignore keeps the fixtures sources and ignores their build output" do
      text = File.read!(".dockerignore")

      assert fixtures_dockerignore_violations(text) == []

      assert fixtures_dockerignore_violations(text <> "fixtures/\n") ==
               ["excludes the fixtures sources: fixtures/"]

      assert fixtures_dockerignore_violations(text <> "fixtures/*\n") ==
               ["excludes the fixtures sources: fixtures/*"]

      assert fixtures_dockerignore_violations(String.replace(text, "fixtures/*/_build\n", "")) ==
               ["must ignore fixtures/*/_build"]

      assert fixtures_dockerignore_violations(String.replace(text, "fixtures/*/deps\n", "")) ==
               ["must ignore fixtures/*/deps"]
    end
  end

  defp storybook_mentions(sources) do
    for {path, text} <- sources, text =~ ~r/PhoenixStorybook|phoenix_storybook/, do: path
  end

  defp storybook_dependency_violation(manifest_path) do
    if :phoenix_storybook in direct_dependency_names!(manifest_path) do
      requirement = direct_dependency_requirement!(manifest_path, :phoenix_storybook)
      only = manifest_path |> dependency_options!(:phoenix_storybook) |> Keyword.get(:only)

      cond do
        requirement != "~> 1.5" ->
          "#{manifest_path}: the storybook dependency must require \"~> 1.5\", got #{inspect(requirement)}"

        Enum.sort(List.wrap(only)) != [:dev, :test] ->
          "#{manifest_path}: the storybook dependency must declare only: [:dev, :test], got #{inspect(only)}"

        true ->
          nil
      end
    else
      "#{manifest_path}: the manifest must declare {:phoenix_storybook, \"~> 1.5\", only: [:dev, :test]}"
    end
  end

  # The guard must be an `if` outside any `quote`, so it is read at router expansion. It must test both
  # that the storybook router is loadable and the catalog flag, and its body must mount `live_storybook`.
  defp catalog_guard_violation(ast) do
    guard? = fn
      {:if, _, [condition, clauses]} when is_list(clauses) ->
        has_node?(condition, fn node ->
          remote_call?(node, [:Code], :ensure_loaded?, fn args ->
            alias_argument?(args, [:PhoenixStorybook, :Router])
          end)
        end) and has_node?(condition, &catalog_flag_read?/1) and
          has_node?(clauses, fn
            {:live_storybook, _, _} -> true
            _ -> false
          end)

      _ ->
        false
    end

    if has_node_outside_quote?(ast, guard?) do
      nil
    else
      "#{@catalog_routes_source}: the route guard must be an if outside the quote that checks " <>
        "Code.ensure_loaded?(PhoenixStorybook.Router) and the :catalog_routes flag around live_storybook"
    end
  end

  # The flag must be read through the macro-aware, tracked `Application.compile_env(env, app, key, default)`
  # (its first argument is the caller env). An untracked `Application.get_env` read, or the three-argument
  # `compile_env` macro (which would expand to a call AST), is not accepted: Mix would not notice a flag
  # change and a stale router could keep `/storybook` mounted.
  defp catalog_flag_read?(node) do
    remote_call?(node, [:Application], :compile_env, fn args ->
      match?([_env, :scrypath_ops, :catalog_routes | _], args)
    end)
  end

  # Quotes are pruned, so nothing inside a quote is ever a candidate. The predicate sees each remaining
  # node as the walker receives it, before its children are walked, so a candidate `if` keeps its body.
  defp has_node_outside_quote?(ast, predicate) do
    {_ast, found?} =
      Macro.prewalk(ast, false, fn
        {:quote, _, _}, found? -> {:pruned, found?}
        node, found? -> {node, found? or predicate.(node)}
      end)

    found?
  end

  defp mutate_catalog_guard(ast, mutation) do
    {mutated, changes} =
      Macro.postwalk(ast, 0, fn
        {:if, _, [_condition, clauses]}, changes
        when is_list(clauses) and mutation == :delete_guard ->
          {Keyword.fetch!(clauses, :do), changes + 1}

        {:if, _, [_condition, clauses]} = node, changes
        when is_list(clauses) and mutation == :move_guard_inside_quote ->
          {{:quote, [], [[do: node]]}, changes + 1}

        {{:., _, [{:__aliases__, _, [:Application]}, :compile_env]}, _,
         [_env, :scrypath_ops, :catalog_routes | _]},
        changes
        when mutation == :drop_flag_read ->
          {true, changes + 1}

        # The pre-fix shape: the same read, but untracked by Mix.
        {{:., dot_meta, [{:__aliases__, _, [:Application]} = app, :compile_env]}, call_meta,
         [_env | [:scrypath_ops, :catalog_routes | _] = untracked_args]},
        changes
        when mutation == :untrack_flag_read ->
          {{{:., dot_meta, [app, :get_env]}, call_meta, untracked_args}, changes + 1}

        node, changes ->
          {node, changes}
      end)

    if changes == 0, do: flunk("mutation #{mutation} found nothing to change"), else: mutated
  end

  # Text-level check of the Docker verify script, the cheap local mirror of the 15 to 20 minute
  # ecommerce-mounted lane. The catalog names are forbidden for the prod image and for the host project in
  # both images; in the test image Ops legitimately has them, so they must not join the shared list.
  defp storybook_script_violations(script) do
    shared = ~r/^\s*forbidden_deps="([^"$]*)"$/m

    conditional =
      ~r/if \[\[ "\$environment" == "prod" \|\| "\$project_dir" == "\/app\/examples\/scrypath_ecommerce" \]\]; then\n\s*forbidden_deps="\$forbidden_deps phoenix_storybook mdex mdex_native"\n\s*fi/

    modules = ~r/^\s*forbidden_modules = \[([^\]]*)\]$/m

    [
      {not Regex.match?(conditional, script),
       "the prod-or-host condition must add phoenix_storybook mdex mdex_native to the forbidden dependencies"},
      {not (script =~ "for forbidden_dep in $forbidden_deps; do"),
       "the dependency loop must iterate the env-aware forbidden_deps list"},
      {case Regex.run(shared, script) do
         [_, names] -> names =~ ~r/phoenix_storybook|mdex/
         nil -> true
       end, "the shared forbidden list must exist and must not contain the catalog dependencies"},
      {case Regex.run(modules, script) do
         [_, names] -> not (names =~ "PhoenixStorybook" and names =~ "MDEx")
         nil -> true
       end, "the runtime probe must forbid the PhoenixStorybook and MDEx modules"},
      {not (script =~ ~s(for catalog_target in "host|$base_url" "ops|$ops_base_url"; do)),
       "the /storybook 404 probe must cover both the host and standalone Ops"},
      {not (script =~ ~s([[ "$catalog_status" == "404" ]])),
       "the /storybook probe must require HTTP 404"}
    ]
    |> Enum.filter(&elem(&1, 0))
    |> Enum.map(&elem(&1, 1))
  end

  defp write_planted_manifest!(tmp, name, dependency_line) do
    path = Path.join(tmp, name)

    File.write!(path, """
    defmodule Planted.MixProject do
      defp deps do
        [
          {:phoenix, "~> 1.7"},
          #{dependency_line}
        ]
      end
    end
    """)

    path
  end

  # Reads the options of a dependency written as `{:name, path: ..., only: ...}` (a two-tuple whose second
  # element is a keyword list) or `{:name, "~> 1.0", only: ...}`. dependency_options!/2 above cannot: its
  # first clause matches the two-tuple and returns [] for a path dependency, which would make every
  # assertion on `only:` read nil (research N4, Pitfall 2). A requirement with no options reads as [].
  defp path_dependency_options!(path, dependency) do
    deps_body = path |> read_ast!() |> find_deps_body!()

    Enum.find_value(deps_body, fn
      {^dependency, options} when is_list(options) -> options
      {^dependency, requirement} when is_binary(requirement) -> []
      {:{}, _, [^dependency, _requirement, options]} when is_list(options) -> options
      _ -> nil
    end) || flunk("#{path}: expected direct dependency #{dependency}")
  end

  defp fixtures_dependency_violation(manifest_path) do
    if :scrypath_fixtures in direct_dependency_names!(manifest_path) do
      options = path_dependency_options!(manifest_path, :scrypath_fixtures)
      path = Keyword.get(options, :path)
      only = Keyword.get(options, :only)

      cond do
        path != "../fixtures/scrypath_fixtures" ->
          "#{manifest_path}: the fixtures dependency must use path: \"../fixtures/scrypath_fixtures\", got #{inspect(path)}"

        Enum.sort(List.wrap(only)) != [:dev, :test] ->
          "#{manifest_path}: the fixtures dependency must declare only: [:dev, :test], got #{inspect(only)}"

        true ->
          nil
      end
    else
      "#{manifest_path}: the manifest must declare the fixtures dependency, but :scrypath_fixtures is absent"
    end
  end

  defp fixtures_mentions(sources) do
    for {path, text} <- sources, text =~ ~r/ScrypathFixtures|scrypath_fixtures/, do: path
  end

  # Text-level check of the Docker verify script. The fixtures project is a dev and test dependency of Ops,
  # like the catalog, so the prod image and the host project (in both images) must not list it while the test
  # image's /app/scrypath_ops legitimately does. It has its own `if` block, separate from the catalog block, so
  # storybook_script_violations/1 above keeps reading a single statement.
  defp fixtures_script_violations(script) do
    shared = ~r/^\s*forbidden_deps="([^"$]*)"$/m

    conditional =
      ~r/if \[\[ "\$environment" == "prod" \|\| "\$project_dir" == "\/app\/examples\/scrypath_ecommerce" \]\]; then\n\s*forbidden_deps="\$forbidden_deps scrypath_fixtures"\n\s*fi/

    modules = ~r/^\s*forbidden_modules = \[([^\]]*)\]$/m

    prod_build =
      ~r/if \[ "\$MIX_ENV" = "prod" \]; then\n\s*test ! -e "\/app\/scrypath_ops\/_build\/prod\/lib\/scrypath_fixtures" \|\|/

    [
      {not Regex.match?(conditional, script),
       "the prod-or-host condition must add scrypath_fixtures to the forbidden dependencies in its own if block"},
      {case Regex.run(shared, script) do
         [_, names] -> names =~ "scrypath_fixtures"
         nil -> true
       end,
       "the shared forbidden list must exist and the shared forbidden list must not contain scrypath_fixtures"},
      {case Regex.run(modules, script) do
         [_, names] -> not (names =~ "ScrypathFixtures")
         nil -> true
       end, "the runtime probe must forbid the ScrypathFixtures module"},
      {not Regex.match?(prod_build, script),
       "the prod image check must fail when _build/prod/lib/scrypath_fixtures exists"}
    ]
    |> Enum.filter(&elem(&1, 0))
    |> Enum.map(&elem(&1, 1))
  end

  # `{stage_name, text}` for each FROM block, in file order.
  defp dockerfile_stages(dockerfile) do
    ~r/(?=^FROM )/m
    |> Regex.split(dockerfile, trim: true)
    |> Enum.filter(&String.starts_with?(&1, "FROM "))
    |> Enum.map(fn text ->
      [_, name] = Regex.run(~r/^FROM \S+ AS (\S+)/m, text)
      {name, text}
    end)
  end

  defp edit_dockerfile_stage(dockerfile, stage, edit) do
    ~r/(?=^FROM )/m
    |> Regex.split(dockerfile, trim: true)
    |> Enum.map_join(fn text ->
      if text =~ ~r/^FROM \S+ AS #{stage}$/m, do: edit.(text), else: text
    end)
  end

  # Each stage that copies the Ops manifest for its early `mix deps.get` must copy the fixtures manifest too,
  # once, before that `deps.get`: Mix reads a path dependency's manifest there, and a missing one only fails
  # later at compile ("the dependency is not available").
  defp fixtures_dockerfile_violations(dockerfile) do
    ops_copy = "COPY scrypath_ops/mix.exs scrypath_ops/mix.lock ./scrypath_ops/"

    for {name, text} <- dockerfile_stages(dockerfile),
        text =~ ops_copy,
        message = fixtures_copy_problem(name, text),
        do: message
  end

  defp fixtures_copy_problem(name, text) do
    copies = length(String.split(text, @fixtures_copy)) - 1
    copy_at = offset(text, @fixtures_copy)
    deps_get_at = offset(text, "mix deps.get")

    cond do
      copies == 0 ->
        "stage #{name} copies scrypath_ops/mix.exs but has no `#{@fixtures_copy}` line"

      copies > 1 ->
        "stage #{name} copies the fixtures manifest more than once"

      copy_at > deps_get_at ->
        "stage #{name} must copy the fixtures manifest before its first mix deps.get"

      true ->
        nil
    end
  end

  defp offset(text, needle) do
    case :binary.match(text, needle) do
      {at, _length} -> at
      :nomatch -> -1
    end
  end

  # The builder and runtime_test stages compile the fixtures sources, so .dockerignore must not exclude them;
  # their _build and deps directories are ignored like the other nested projects'.
  defp fixtures_dockerignore_violations(text) do
    lines = text |> String.split("\n") |> Enum.map(&String.trim/1)
    excluding = ~r{^/?(\*\*/)?fixtures(/(\*\*?|scrypath_fixtures(/(\*\*?|lib|mix\.exs)?)?))?/?$}

    for(
      line <- lines,
      Regex.match?(excluding, line),
      do: "excludes the fixtures sources: #{line}"
    ) ++
      for required <- ["fixtures/*/_build", "fixtures/*/deps"],
          required not in lines,
          do: "must ignore #{required}"
  end

  defp catalog_bind_violation({ip, flag}) do
    loopback? = ip in [{127, 0, 0, 1}, {0, 0, 0, 0, 0, 0, 0, 1}]

    if flag == true and not loopback? do
      "the catalog flag is on while the endpoint binds #{inspect(ip)}; it must stay loopback-only"
    end
  end

  # Reads a config file in a subprocess so PHX_SERVER can differ per call while this module stays async.
  defp read_catalog_bind!(config_file, env, phx_server) do
    program =
      ~s|c = Config.Reader.read!("#{config_file}", env: :#{env})[:scrypath_ops]; | <>
        "IO.puts(inspect({c[ScrypathOpsWeb.Endpoint][:http][:ip], c[:catalog_routes]}))"

    {output, status} =
      System.cmd(System.find_executable("elixir"), ["-e", program],
        env: [{"PHX_SERVER", phx_server}],
        stderr_to_stdout: true
      )

    assert status == 0, "#{config_file}: config read failed: #{output}"

    {bind, _binding} =
      output |> String.split("\n", trim: true) |> List.last() |> Code.eval_string()

    bind
  end

  defp markdown_table_rows!(path, heading) do
    lines = path |> File.read!() |> String.split("\n")

    heading_index =
      Enum.find_index(lines, &(&1 == heading)) ||
        flunk("#{path}: expected Markdown table heading #{inspect(heading)}")

    lines
    |> Enum.drop(heading_index + 1)
    |> Enum.drop_while(&(not String.starts_with?(String.trim(&1), "|")))
    |> Enum.take_while(&String.starts_with?(String.trim(&1), "|"))
    |> Enum.drop(1)
    |> Enum.map(&markdown_table_cells!/1)
    |> Enum.reject(fn cells -> Enum.all?(cells, &Regex.match?(~r/^:?-+:?$/, &1)) end)
  end

  defp markdown_table_cells!(line) do
    line
    |> String.trim()
    |> String.trim_leading("|")
    |> String.trim_trailing("|")
    |> String.split("|")
    |> Enum.map(&(String.trim(&1) |> String.trim("`")))
  end

  defp action_pr_id!([first | _]) do
    case Regex.run(~r/\[#(\d+)\]/, first) do
      [_, id] -> id
      _ -> flunk("expected a linked GitHub PR number in #{inspect(first)}")
    end
  end

  defp action_pr_id!(_row), do: flunk("expected a non-empty PR disposition row")

  defp action_disposition_errors(rows) do
    ids = Enum.map(rows, &action_pr_id!/1)
    frequencies = Enum.frequencies(ids)

    missing =
      Enum.reject(@action_pr_ids, &(&1 in ids))
      |> Enum.map(&"missing PR disposition: ##{&1}")

    duplicates =
      frequencies
      |> Enum.filter(fn {_id, count} -> count > 1 end)
      |> Enum.map(fn {id, _count} -> "duplicate PR disposition: ##{id}" end)

    empty_fields =
      Enum.flat_map(rows, fn row ->
        id = action_pr_id!(row)

        cond do
          length(row) != 8 ->
            ["invalid PR disposition schema: ##{id}"]

          Enum.at(row, 2) == "" ->
            ["empty disposition for PR ##{id}"]

          Enum.any?(Enum.drop(row, 1), &(&1 == "")) ->
            ["empty required disposition field for PR ##{id}"]

          true ->
            []
        end
      end)

    missing ++ duplicates ++ empty_fields
  end

  defp dependency_graph_id!([graph | _]), do: String.trim(graph, "`")
  defp dependency_graph_id!(_row), do: flunk("expected a non-empty dependency graph record")

  defp dependency_graph_record_errors(rows) do
    ids = Enum.map(rows, &dependency_graph_id!/1)
    frequencies = Enum.frequencies(ids)

    missing =
      Enum.reject(@dependency_graph_ids, &(&1 in ids))
      |> Enum.map(&"missing dependency graph record: #{&1}")

    duplicates =
      frequencies
      |> Enum.filter(fn {_id, count} -> count > 1 end)
      |> Enum.map(fn {id, _count} -> "duplicate dependency graph record: #{id}" end)

    row_errors =
      Enum.flat_map(rows, &dependency_graph_row_errors/1)

    source_shas = Enum.map(rows, &Enum.at(&1, 1)) |> Enum.uniq()

    source_errors =
      if length(source_shas) == 1, do: [], else: ["dependency graphs do not share one source SHA"]

    missing ++ duplicates ++ row_errors ++ source_errors
  end

  defp dependency_graph_row_errors(row) do
    graph = dependency_graph_id!(row)

    [
      graph_schema_error(row, graph),
      graph_raw_evidence_error(row, graph),
      graph_required_field_error(row, graph),
      graph_source_sha_error(row, graph),
      graph_manifest_lock_hash_error(row, graph),
      graph_lock_stability_error(row, graph),
      graph_hex_version_error(row, graph),
      graph_fetch_status_error(row, graph),
      graph_audit_exit_error(row, graph),
      graph_audit_status_error(row, graph),
      graph_evidence_location_error(row, graph)
    ]
    |> Enum.reject(&is_nil/1)
  end

  defp graph_schema_error(row, graph),
    do: if(length(row) == 11, do: nil, else: "invalid dependency graph record schema: #{graph}")

  defp graph_raw_evidence_error(row, graph),
    do:
      if(Enum.at(row, 10) == "",
        do: "empty raw evidence reference for dependency graph: #{graph}"
      )

  defp graph_required_field_error(row, graph),
    do: if(Enum.any?(row, &(&1 == "")), do: "empty required field for dependency graph: #{graph}")

  defp graph_source_sha_error(row, graph) do
    valid_sha? = Regex.match?(~r/\A(?:[0-9a-f]{40}|[0-9a-f]{64})\z/, Enum.at(row, 1) || "")
    if valid_sha?, do: nil, else: "invalid source SHA for dependency graph: #{graph}"
  end

  defp graph_manifest_lock_hash_error(row, graph) do
    valid_hashes? =
      Enum.slice(row, 2, 3) |> Enum.all?(&Regex.match?(~r/\A[0-9a-f]{64}\z/, &1))

    if valid_hashes?, do: nil, else: "invalid manifest/lock SHA for dependency graph: #{graph}"
  end

  defp graph_lock_stability_error(row, graph),
    do:
      if(Enum.at(row, 3) == Enum.at(row, 4),
        do: nil,
        else: "dependency lock changed during audit for graph: #{graph}"
      )

  defp graph_hex_version_error(row, graph),
    do:
      if(Enum.at(row, 6) == "2.5.1",
        do: nil,
        else: "unexpected Hex version for dependency graph: #{graph}"
      )

  defp graph_fetch_status_error(row, graph),
    do: if(Enum.at(row, 7) == "0", do: nil, else: "dependency fetch failed for graph: #{graph}")

  defp graph_audit_exit_error(row, graph),
    do:
      if(Enum.at(row, 8) in ["0", "1"],
        do: nil,
        else: "invalid Hex audit exit status for graph: #{graph}"
      )

  defp graph_audit_status_error(row, graph),
    do:
      if(Enum.at(row, 9) in ["clean", "affected"],
        do: nil,
        else: "invalid dependency audit status for graph: #{graph}"
      )

  defp graph_evidence_location_error(row, graph),
    do:
      if(String.starts_with?(Enum.at(row, 10) || "", "/private/tmp/"),
        do: nil,
        else: "empty raw evidence reference for dependency graph: #{graph}"
      )

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

  defp host_production_config_valid?(ast) do
    endpoint_options =
      config_options(ast, :scrypath_ecommerce, [:ScrypathEcommerceWeb, :Endpoint])

    is_list(endpoint_options) and
      Keyword.get(endpoint_options, :code_reloader) == false and
      Keyword.get(endpoint_options, :debug_errors) == false and
      Keyword.get(endpoint_options, :watchers) == [] and
      Keyword.get(endpoint_options, :cache_static_manifest) == "priv/static/cache_manifest.json" and
      not Keyword.has_key?(endpoint_options, :secret_key_base) and
      not config_has_key?(ast, :scrypath_ecommerce, nil, :sandbox)
  end

  defp host_production_runtime_valid?(ast) do
    case environment_branch(ast, :prod) do
      nil ->
        false

      branch ->
        endpoint_options =
          config_options(branch, :scrypath_ecommerce, [:ScrypathEcommerceWeb, :Endpoint])

        has_config_target?(branch, :scrypath_ecommerce, [:ScrypathEcommerce, :Repo]) and
          is_list(endpoint_options) and
          has_env_read?(endpoint_options, "SECRET_KEY_BASE") and
          has_env_read?(endpoint_options, "PHX_SERVER") and
          has_env_read?(endpoint_options, "PORT") and
          Enum.all?(
            ["DATABASE_URL", "PGUSER", "PGPASSWORD", "PGHOST", "PGPORT", "PGDATABASE"],
            &has_env_read?(branch, &1)
          ) and
          not config_has_key?(branch, :scrypath_ecommerce, nil, :sandbox)
    end
  end

  defp environment_branch(ast, environment) do
    {_ast, branch} =
      Macro.prewalk(ast, nil, fn
        {:if, _, [condition, clauses]} = node, nil when is_list(clauses) ->
          if config_env_condition?(condition, environment) do
            {node, Keyword.get(clauses, :do)}
          else
            {node, nil}
          end

        node, branch ->
          {node, branch}
      end)

    branch
  end

  defp config_env_condition?(condition, environment) do
    has_node?(condition, fn
      {:==, _, [{:config_env, _, []}, ^environment]} -> true
      _ -> false
    end)
  end

  defp config_options(ast, app, target) do
    {_ast, options} =
      Macro.prewalk(ast, nil, fn
        {:config, _, [^app, found_options]} = node, nil
        when is_list(found_options) and is_nil(target) ->
          {node, found_options}

        {:config, _, [^app, found_target, found_options]} = node, nil
        when is_list(found_options) ->
          if module_alias?(found_target, target), do: {node, found_options}, else: {node, nil}

        node, options ->
          {node, options}
      end)

    options
  end

  defp config_has_key?(ast, app, target, key) do
    case config_options(ast, app, target) do
      options when is_list(options) -> Keyword.has_key?(options, key)
      _ -> false
    end
  end

  defp config_value?(ast, app, target, key, value) do
    case config_options(ast, app, target) do
      options when is_list(options) -> Keyword.get(options, key) == value
      _ -> false
    end
  end

  defp has_config_target?(ast, app, target) do
    has_node?(ast, fn
      {:config, _, [^app, found_target | _]} -> module_alias?(found_target, target)
      _ -> false
    end)
  end

  defp module_alias?({:__aliases__, _, found_alias}, expected_alias),
    do: found_alias == expected_alias

  defp module_alias?(_ast, _expected_alias), do: false

  defp has_env_read?(ast, name) do
    has_node?(ast, fn node ->
      remote_call?(node, [:System], :get_env, fn args -> args == [name] end) or
        remote_call?(node, [:System], :fetch_env!, fn args -> args == [name] end)
    end)
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

  defp dependency_boundary_fixture!(source_root, fixture_root) do
    Enum.each(
      @static_contract_files ++
        ["examples/scrypath_ecommerce/scripts/verify-dependency-boundaries.sh"],
      fn path ->
        source = Path.join(source_root, path)
        target = Path.join(fixture_root, path)
        File.mkdir_p!(Path.dirname(target))
        File.cp!(source, target)
      end
    )

    fixture_root
  end

  defp run_static_dependency_contract(fixture_root, args \\ ["--static-contract-only"]) do
    script =
      Path.join(
        fixture_root,
        "examples/scrypath_ecommerce/scripts/verify-dependency-boundaries.sh"
      )

    System.cmd("bash", [script | args],
      cd: fixture_root,
      env: [{"SCRYPATH_DEPENDENCY_BOUNDARY_ROOT", fixture_root}],
      stderr_to_stdout: true
    )
  end

  defp append_dependency_boundary_text!(fixture_root, path, addition) do
    target = Path.join(fixture_root, path)
    File.write!(target, File.read!(target) <> addition)
  end

  defp replace_dependency_boundary_text!(fixture_root, path, original, replacement) do
    target = Path.join(fixture_root, path)
    contents = File.read!(target)
    mutated = String.replace(contents, original, replacement, global: false)
    if mutated == contents, do: flunk("fixture mutation did not match #{path}: #{original}")
    File.write!(target, mutated)
  end
end
