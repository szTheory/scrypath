defmodule Scrypath.OptionsTest do
  use ExUnit.Case, async: false

  import Ecto.Query
  import ExUnit.CaptureIO

  alias Scrypath.Config
  alias Scrypath.Options
  alias Scrypath.TestSupport.FakeBackend

  setup do
    original_defaults = Application.get_env(:scrypath, :defaults)

    on_exit(fn ->
      if original_defaults == nil do
        Application.delete_env(:scrypath, :defaults)
      else
        Application.put_env(:scrypath, :defaults, original_defaults)
      end
    end)

    :ok
  end

  test "validate_runtime_options!/1 accepts Meilisearch and inline waiting options" do
    config =
      Scrypath.Options.validate_runtime_options!(
        backend: FakeBackend,
        meilisearch_url: "http://localhost:7700",
        meilisearch_api_key: "secret",
        inline_poll_interval: 250,
        inline_timeout: 9_000
      )

    assert config[:backend] == FakeBackend
    assert config[:meilisearch_url] == "http://localhost:7700"
    assert config[:meilisearch_api_key] == "secret"
    assert config[:inline_poll_interval] == 250
    assert config[:inline_timeout] == 9_000
  end

  test "Scrypath.Config.resolve!/1 merges defaults and explicit runtime options" do
    Application.put_env(:scrypath, :defaults,
      backend: FakeBackend,
      meilisearch_url: "http://defaults.test:7700",
      meilisearch_api_key: "default-key",
      inline_poll_interval: 150,
      inline_timeout: 7_500
    )

    config =
      Config.resolve!(
        meilisearch_api_key: "explicit-key",
        inline_timeout: 12_000
      )

    assert config[:backend] == FakeBackend
    assert Config.fetch_meilisearch_url!(config) == "http://defaults.test:7700"
    assert Config.meilisearch_api_key(config) == "explicit-key"
    assert Config.inline_poll_interval(config) == 150
    assert Config.inline_timeout(config) == 12_000
  end

  test "validate_runtime_options!/1 rejects invalid inline waiting values" do
    assert_raise ArgumentError, ~r/inline_poll_interval/, fn ->
      Scrypath.Options.validate_runtime_options!(
        backend: FakeBackend,
        inline_poll_interval: 0
      )
    end

    assert_raise ArgumentError, ~r/inline_timeout/, fn ->
      Scrypath.Options.validate_runtime_options!(
        backend: FakeBackend,
        inline_timeout: -1
      )
    end

    assert_raise ArgumentError, ~r/meilisearch_url/, fn ->
      Scrypath.Options.validate_runtime_options!(
        backend: FakeBackend,
        meilisearch_url: 123
      )
    end
  end

  test "validate_backfill_options!/1 requires backend and repo and accepts explicit overrides" do
    query = from("posts")

    config =
      Scrypath.Options.validate_backfill_options!(
        backend: FakeBackend,
        repo: Scrypath.TestRepo,
        batch_size: 500,
        query: query,
        index_prefix: "tenant",
        index_name: "posts_v2",
        meilisearch_url: "http://localhost:7700",
        inline_poll_interval: 250,
        inline_timeout: 6_000,
        sync_mode: :manual
      )

    assert config[:backend] == FakeBackend
    assert config[:repo] == Scrypath.TestRepo
    assert config[:batch_size] == 500
    assert config[:query] == query
    assert config[:index_prefix] == "tenant"
    assert config[:index_name] == "posts_v2"
    assert config[:meilisearch_url] == "http://localhost:7700"
    assert config[:inline_poll_interval] == 250
    assert config[:inline_timeout] == 6_000
    assert config[:sync_mode] == :manual
  end

  test "validate_reindex_options!/1 requires backend and repo and validates cutover contract" do
    config =
      Scrypath.Options.validate_reindex_options!(
        backend: FakeBackend,
        repo: Scrypath.TestRepo,
        batch_size: 1_000,
        index_prefix: "tenant",
        target_index: "posts_tmp",
        cutover?: false,
        settings: %{sortableAttributes: ["inserted_at"]},
        meilisearch_url: "http://localhost:7700",
        inline_poll_interval: 200,
        inline_timeout: 8_000,
        sync_mode: :manual
      )

    assert config[:backend] == FakeBackend
    assert config[:repo] == Scrypath.TestRepo
    assert config[:batch_size] == 1_000
    assert config[:index_prefix] == "tenant"
    assert config[:target_index] == "posts_tmp"
    assert config[:cutover?] == false

    assert config[:settings] == %{
             sortable_attributes: ["inserted_at"],
             __unrecognized__: %{}
           }

    assert config[:meilisearch_url] == "http://localhost:7700"
    assert config[:inline_poll_interval] == 200
    assert config[:inline_timeout] == 8_000
    assert config[:sync_mode] == :manual
  end

  test "bulk workflow validators reject impossible values before execution" do
    assert_raise ArgumentError, ~r/repo/, fn ->
      Scrypath.Options.validate_backfill_options!(
        backend: FakeBackend,
        batch_size: 100
      )
    end

    assert_raise ArgumentError, ~r/batch_size/, fn ->
      Scrypath.Options.validate_backfill_options!(
        backend: FakeBackend,
        repo: Scrypath.TestRepo,
        batch_size: 0
      )
    end

    assert_raise ArgumentError, ~r/sync_mode/, fn ->
      Scrypath.Options.validate_backfill_options!(
        backend: FakeBackend,
        repo: Scrypath.TestRepo,
        batch_size: 100,
        sync_mode: :oban
      )
    end

    assert_raise ArgumentError, ~r/sync_mode/, fn ->
      Scrypath.Options.validate_reindex_options!(
        backend: FakeBackend,
        repo: Scrypath.TestRepo,
        batch_size: 100,
        sync_mode: :oban
      )
    end
  end

  describe "settings_merge opt" do
    test "validate_reindex_options!/1 accepts settings_merge: :replace" do
      config =
        Options.validate_reindex_options!(
          backend: FakeBackend,
          repo: Scrypath.TestRepo,
          batch_size: 100,
          settings_merge: :replace,
          sync_mode: :manual
        )

      assert config[:settings_merge] == :replace
    end

    test "validate_reindex_options!/1 accepts settings_merge: :deep" do
      config =
        Options.validate_reindex_options!(
          backend: FakeBackend,
          repo: Scrypath.TestRepo,
          batch_size: 100,
          settings_merge: :deep,
          sync_mode: :manual
        )

      assert config[:settings_merge] == :deep
    end

    test "validate_runtime_options!/1 accepts settings_merge: :replace and :deep" do
      replace_cfg =
        Options.validate_runtime_options!(
          backend: FakeBackend,
          settings_merge: :replace
        )

      deep_cfg =
        Options.validate_runtime_options!(
          backend: FakeBackend,
          settings_merge: :deep
        )

      assert replace_cfg[:settings_merge] == :replace
      assert deep_cfg[:settings_merge] == :deep
    end

    test "validate_reindex_options!/1 rejects invalid settings_merge values" do
      assert_raise ArgumentError,
                   ~r/:settings_merge.*\[:replace, :deep\].*:fooey/,
                   fn ->
                     Options.validate_reindex_options!(
                       backend: FakeBackend,
                       repo: Scrypath.TestRepo,
                       batch_size: 100,
                       settings_merge: :fooey,
                       sync_mode: :manual
                     )
                   end
    end

    test "validate_reindex_options!/1 defaults settings_merge to :replace" do
      config =
        Options.validate_reindex_options!(
          backend: FakeBackend,
          repo: Scrypath.TestRepo,
          batch_size: 100,
          sync_mode: :manual
        )

      assert config[:settings_merge] == :replace
    end
  end

  describe ":settings removal from @backfill_options (D-08)" do
    test "validate_backfill_options!/1 rejects settings: %{...}" do
      assert_raise ArgumentError, fn ->
        Options.validate_backfill_options!(
          backend: FakeBackend,
          repo: Scrypath.TestRepo,
          batch_size: 100,
          settings: %{filterableAttributes: ["status"]},
          sync_mode: :manual
        )
      end
    end

    test "validate_backfill_options!/1 rejects settings_merge" do
      assert_raise ArgumentError, fn ->
        Options.validate_backfill_options!(
          backend: FakeBackend,
          repo: Scrypath.TestRepo,
          batch_size: 100,
          settings_merge: :deep,
          sync_mode: :manual
        )
      end
    end
  end

  describe "validate_settings/1 (Posture D normalize-on-entry)" do
    test "preserves nested snake_case recognized settings (I)" do
      input = %{
        synonyms: [["nyc", "new york"]],
        typo_tolerance: %{
          enabled: true,
          min_word_size_for_typos: %{one_typo: 5, two_typos: 9}
        }
      }

      assert {:ok, canonical} = Options.validate_settings(input)
      assert canonical.synonyms == [["nyc", "new york"]]
      assert canonical.typo_tolerance.enabled == true
      assert canonical.typo_tolerance.min_word_size_for_typos == %{one_typo: 5, two_typos: 9}
      assert canonical.__unrecognized__ == %{}
    end

    test "canonicalizes atom-camelCase searchableAttributes (J)" do
      assert {:ok, canonical} = Options.validate_settings(%{searchableAttributes: ["title"]})
      assert %{searchable_attributes: ["title"]} = canonical
      assert canonical.__unrecognized__ == %{}
    end

    test "canonicalizes string-camelCase keys (K)" do
      assert {:ok, canonical} =
               Options.validate_settings(%{"searchableAttributes" => ["title"]})

      assert canonical[:searchable_attributes] == ["title"]
      assert canonical.__unrecognized__ == %{}
    end

    test "buckets unknown Meilisearch subkeys under :__unrecognized__ (L)" do
      assert {:ok, canonical} = Options.validate_settings(%{weird_new_meilisearch_key: 42})

      assert canonical[:__unrecognized__] == %{weird_new_meilisearch_key: 42}
      refute Map.has_key?(canonical, :weird_new_meilisearch_key)
    end

    test "rejects invalid nested typo_tolerance.enabled shape (M)" do
      assert {:error, msg} =
               Options.validate_settings(%{typo_tolerance: %{enabled: "yes"}})

      assert msg =~ "enabled"
    end

    test "canonicalize_key/1 maps legacy and recognized keys (N)" do
      assert Options.canonicalize_key(:searchableAttributes) == :searchable_attributes
      assert Options.canonicalize_key(:synonyms) == :synonyms

      assert Options.canonicalize_key("synonyms") == :synonyms
      assert Options.canonicalize_key(:weird_key) == {:unrecognized, :weird_key}
    end

    test "warns on stderr when ranking_rules omits Meilisearch defaults (O)" do
      input = %{ranking_rules: [:typo, :proximity, :attribute, :sort, :exactness]}

      err =
        capture_io(:stderr, fn ->
          assert {:ok, _} = Options.validate_settings(input)
        end)

      assert err =~ "ranking_rules is missing the following Meilisearch default"
      assert err =~ "words"
    end

    test "does not warn when ranking_rules_strict?: false (P)" do
      input = %{
        ranking_rules: [:exactness, :words, :typo, :proximity, :attribute, :sort],
        ranking_rules_strict?: false
      }

      err =
        capture_io(:stderr, fn ->
          assert {:ok, _} = Options.validate_settings(input)
        end)

      assert err == ""
    end

    test "emits camelCase informational hint on stderr (Q)" do
      err =
        capture_io(:stderr, fn ->
          assert {:ok, _} = Options.validate_settings(%{searchableAttributes: ["title"]})
        end)

      assert err =~ "camelCase"
      assert err =~ "No action required"
    end

    test "does not emit stderr on canonical snake_case happy path (R)" do
      input = %{synonyms: [["nyc", "new york"]]}

      err =
        capture_io(:stderr, fn ->
          assert {:ok, _} = Options.validate_settings(input)
        end)

      assert err == ""
    end
  end

  describe "schema faceting" do
    test "FacetableMovie compiles with aligned faceting and filterable" do
      faceting = FacetableMovie.__scrypath__(:faceting)

      assert Keyword.get(faceting, :attributes) == [
               :genre,
               :year,
               :rating,
               :director
             ]

      assert Keyword.get(faceting, :nested_facet_paths) == false
      assert Scrypath.schema_faceting(FacetableMovie) == faceting
    end

    test "FacetableHierarchy compiles with nested facet paths" do
      faceting = FacetableHierarchy.__scrypath__(:faceting)

      assert Keyword.get(faceting, :nested_facet_paths) == true

      assert Keyword.get(faceting, :attributes) == [
               :"categories.lvl0",
               :"categories.lvl1"
             ]
    end

    test "hierarchy sugar expands attributes and enables nested paths" do
      [{mod, _}] =
        Code.compile_string("""
        defmodule HierarchySugarSchema do
          use Ecto.Schema

          use Scrypath,
            fields: [:title],
            filterable: [:"demo.lvl0", :"demo.lvl1"],
            faceting: [
              hierarchy: [base: :demo, depth: 2],
              max_values_per_facet: 50
            ]

          embedded_schema do
            field :title, :string
          end
        end
        """)

      faceting = mod.__scrypath__(:faceting)

      assert Keyword.get(faceting, :attributes) == [:"demo.lvl0", :"demo.lvl1"]
      assert Keyword.get(faceting, :nested_facet_paths) == true
      refute Keyword.has_key?(faceting, :hierarchy)
    end

    test "rejects facet attribute not in filterable (FACET-02)" do
      assert_raise ArgumentError, ~r/not in filterable/, fn ->
        Code.compile_string("""
        defmodule InvalidFacetNotFilterable do
          use Ecto.Schema

          use Scrypath,
            fields: [:title],
            filterable: [:genre],
            faceting: [attributes: [:orphan]]

          embedded_schema do
            field :title, :string
          end
        end
        """)
      end
    end

    test "rejects wildcard facet attribute (FACET-10)" do
      assert_raise ArgumentError, ~r/wildcard/, fn ->
        Code.compile_string("""
        defmodule InvalidFacetWildcard do
          use Ecto.Schema

          use Scrypath,
            fields: [:title],
            filterable: [:genre],
            faceting: [attributes: [:*]]

          embedded_schema do
            field :title, :string
          end
        end
        """)
      end
    end

    test "rejects dotted facet attributes without nested_facet_paths (FACET-10 default)" do
      assert_raise ArgumentError, ~r/hierarchical/, fn ->
        Code.compile_string("""
        defmodule InvalidFacetHierarchical do
          use Ecto.Schema

          use Scrypath,
            fields: [:title],
            filterable: [:genre, :"foo.bar"],
            faceting: [attributes: [:"foo.bar"]]

          embedded_schema do
            field :title, :string
          end
        end
        """)
      end
    end

    test "rejects dotted facet names that do not match lvlN pattern when nested paths are on" do
      assert_raise ArgumentError, ~r/lvlN/, fn ->
        Code.compile_string("""
        defmodule InvalidDottedFacetShape do
          use Ecto.Schema

          use Scrypath,
            fields: [:title],
            filterable: [:"foo.bar", :title],
            faceting: [
              nested_facet_paths: true,
              attributes: [:"foo.bar"],
              max_values_per_facet: 10
            ]

          embedded_schema do
            field :title, :string
          end
        end
        """)
      end
    end
  end

  describe "fan_outs metadata (DATA-01)" do
    test "validate_fan_outs/1 accepts a list of keyword configurations with target and MFA resolver" do
      input = [
        posts: [target: Post, resolver: {Scrypath.DocResolver, :resolve, [:posts]}],
        comments: [target: Comment, resolver: {Scrypath.DocResolver, :resolve, [:comments]}]
      ]

      assert {:ok, result} = Options.validate_fan_outs(input)
      assert length(result) == 2

      assert Keyword.get(result, :posts) == [
               target: Post,
               resolver: {Scrypath.DocResolver, :resolve, [:posts]}
             ]

      assert Keyword.get(result, :comments) == [
               target: Comment,
               resolver: {Scrypath.DocResolver, :resolve, [:comments]}
             ]
    end

    test "validate_fan_outs/1 rejects if resolver is not a valid MFA" do
      input = [
        posts: [target: Post, resolver: {Scrypath.DocResolver, :resolve}]
      ]

      assert {:error, msg} = Options.validate_fan_outs(input)
      assert msg =~ "fan_out :resolver must be a valid MFA tuple"
    end

    test "validate_fan_outs/1 rejects if target is not a module" do
      input = [
        posts: [target: "Post", resolver: {Scrypath.DocResolver, :resolve, []}]
      ]

      assert {:error, msg} = Options.validate_fan_outs(input)
      assert msg =~ "fan_out :target must be a module"
    end
  end

  describe "tenant_field: option" do
    test "validate_schema_options!/1 returns a map where :tenant_id is present in both :fields and :filterable" do
      config = Options.validate_schema_options!(fields: [:title], tenant_field: :tenant_id)
      assert :tenant_id in config.fields
      assert :tenant_id in config.filterable
    end

    test "auto-injection into fields: is idempotent — validate_schema_options!/1 does not duplicate :tenant_id in :fields" do
      config =
        Options.validate_schema_options!(fields: [:title, :tenant_id], tenant_field: :tenant_id)

      assert config.fields == [:title, :tenant_id]
    end

    test "IO.warn/2 advisory emitted to :stderr when tenant_field: field is NOT in fields:" do
      stderr =
        capture_io(:stderr, fn ->
          Code.compile_string("""
          defmodule TenantFieldAutoInjectWarns do
            use Scrypath.Schema,
              fields: [:title],
              tenant_field: :tenant_id
          end
          """)
        end)

      assert stderr =~ "tenant_field :tenant_id is not listed in fields:"
      assert stderr =~ "auto-added"
    end

    test "no :stderr output when tenant_field: field IS already in fields:" do
      stderr =
        capture_io(:stderr, fn ->
          Code.compile_string("""
          defmodule TenantFieldIdempotentNoWarn do
            use Scrypath.Schema,
              fields: [:title, :tenant_id],
              tenant_field: :tenant_id
          end
          """)
        end)

      refute stderr =~ "is not listed in fields"
    end

    test "auto-injection into filterable: is idempotent — field already in filterable: produces no duplicate" do
      config =
        Options.validate_schema_options!(
          fields: [:title],
          filterable: [:tenant_id],
          tenant_field: :tenant_id
        )

      assert Enum.count(config.filterable, &(&1 == :tenant_id)) == 1
    end

    test "validate_schema_options!/1 is valid when tenant_field: nil (no injection, no warn)" do
      config = Options.validate_schema_options!(fields: [:title], tenant_field: nil)
      refute :tenant_field in config.fields
      assert config.tenant_field == nil
    end
  end

  describe "tenant_scope: search option" do
    defmodule MockTenantSchema do
      def __scrypath__(:tenant_field), do: :tenant_id
      def __scrypath__(:filterable), do: [:tenant_id, :status]
      def __scrypath__(:sortable), do: []
      def __scrypath__(:faceting), do: []
    end

    defmodule MockNoTenantSchema do
      def __scrypath__(:tenant_field), do: nil
      def __scrypath__(:filterable), do: [:status]
      def __scrypath__(:sortable), do: []
      def __scrypath__(:faceting), do: []
    end

    test "injects tenant field into empty filter" do
      opts = Options.validate_search_options!(MockTenantSchema, tenant_scope: 123)
      assert opts[:filter] == [tenant_id: 123]
      refute Keyword.has_key?(opts, :tenant_scope)
    end

    test "injects tenant field into existing filter" do
      opts =
        Options.validate_search_options!(MockTenantSchema,
          tenant_scope: 123,
          filter: [status: "active"]
        )

      assert opts[:filter] == [tenant_id: 123, status: "active"]
    end

    test "raises when filter already contains tenant field" do
      assert_raise ArgumentError, ~r/already contains the tenant_field/, fn ->
        Options.validate_search_options!(MockTenantSchema,
          tenant_scope: 123,
          filter: [tenant_id: 456]
        )
      end
    end

    test "raises when schema lacks tenant_field:" do
      assert_raise ArgumentError, ~r/does not declare a tenant_field:/, fn ->
        Options.validate_search_options!(MockNoTenantSchema, tenant_scope: 123)
      end
    end
  end
end
