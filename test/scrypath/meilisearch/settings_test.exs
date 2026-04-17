defmodule Scrypath.Meilisearch.SettingsTest do
  use ExUnit.Case, async: true

  alias Scrypath.Meilisearch.Settings

  defmodule RecordingClient do
    def update_settings(index_name, settings, config) do
      send(self(), {:client_update_settings, index_name, settings, config})

      {:ok,
       %{
         "taskUid" => 20,
         "indexUid" => index_name,
         "status" => "enqueued",
         "type" => "settingsUpdate"
       }}
    end
  end

  describe "expand_synonyms/1 (TUNE-02)" do
    test "bidirectional list-of-groups sugar (A)" do
      assert Settings.expand_synonyms([["nyc", "new york"]]) == %{
               "nyc" => ["new york"],
               "new york" => ["nyc"]
             }
    end

    test "one_way tuple form (B)" do
      assert Settings.expand_synonyms({[["nyc", "new york"]], one_way: true}) == %{
               "nyc" => ["new york"]
             }
    end

    test "Meilisearch-native map passthrough (C)" do
      assert Settings.expand_synonyms(%{"nyc" => ["new york"]}) == %{"nyc" => ["new york"]}
    end

    test "empty list (D)" do
      assert Settings.expand_synonyms([]) == %{}
    end

    test "three-term bidirectional (E)" do
      assert Settings.expand_synonyms([["a", "b", "c"]]) == %{
               "a" => ["b", "c"],
               "b" => ["a", "c"],
               "c" => ["a", "b"]
             }
    end

    test "three-term one_way (F)" do
      assert Settings.expand_synonyms({[["a", "b", "c"]], one_way: true}) == %{
               "a" => ["b", "c"]
             }
    end

    test "duplicate terms across groups merge (G)" do
      assert Settings.expand_synonyms([["nyc", "new york"], ["nyc", "big apple"]]) == %{
               "nyc" => ["new york", "big apple"],
               "new york" => ["nyc"],
               "big apple" => ["nyc"]
             }
    end

    test "atom terms stringify (H)" do
      assert Settings.expand_synonyms([[:nyc, :new_york]]) == %{
               "nyc" => ["new_york"],
               "new_york" => ["nyc"]
             }
    end
  end

  describe "translate_settings/1 (TUNE-01 translate half, D-04 meta-key strip, D-17 unrecognized passthrough)" do
    test "atom-snake to camelCase string keys (I)" do
      result =
        Settings.translate_settings(%{
          synonyms: %{"nyc" => ["new york"]},
          ranking_rules: [:words, :typo],
          __unrecognized__: %{}
        })

      assert result["synonyms"] == %{"nyc" => ["new york"]}
      assert result["rankingRules"] == [:words, :typo]
    end

    test "top-level keys camelized; nested typo_tolerance maps (J)" do
      result =
        Settings.translate_settings(%{
          typo_tolerance: %{
            enabled: true,
            min_word_size_for_typos: %{one_typo: 5}
          },
          __unrecognized__: %{}
        })

      assert result["typoTolerance"]["enabled"] == true
      assert result["typoTolerance"]["minWordSizeForTypos"]["oneTypo"] == 5
    end

    test "ranking_rules_strict? stripped from wire (K)" do
      result =
        Settings.translate_settings(%{
          ranking_rules: [:words, :typo, :proximity, :attribute, :sort, :exactness],
          ranking_rules_strict?: false,
          __unrecognized__: %{}
        })

      assert Map.has_key?(result, "rankingRules")
      refute Map.has_key?(result, :ranking_rules_strict?)
      refute Map.has_key?(result, "rankingRulesStrict?")
    end

    test "__unrecognized__ spreads last with arbitrary keys (L)" do
      result =
        Settings.translate_settings(%{
          synonyms: %{"nyc" => ["new york"]},
          __unrecognized__: %{"weirdNewMeilisearchKey" => 42}
        })

      assert result["synonyms"] == %{"nyc" => ["new york"]}
      assert result["weirdNewMeilisearchKey"] == 42
      refute Map.has_key?(result, :__unrecognized__)
    end

    test "__unrecognized__ only synonyms-shaped entry (M)" do
      result =
        Settings.translate_settings(%{
          __unrecognized__: %{"synonyms" => %{"a" => ["b"]}}
        })

      assert result == %{"synonyms" => %{"a" => ["b"]}}
    end

    test "empty __unrecognized__ bucket (N)" do
      result =
        Settings.translate_settings(%{
          synonyms: %{},
          __unrecognized__: %{}
        })

      assert result == %{"synonyms" => %{}}
    end

    test "strip *_strict? via translate_settings (O)" do
      result =
        Settings.translate_settings(%{
          ranking_rules_strict?: false,
          foo_strict?: true,
          synonyms: %{},
          __unrecognized__: %{}
        })

      assert result == %{"synonyms" => %{}}
    end
  end

  describe "apply/3 wire-shape (TUNE-01/02/04)" do
    defmodule ApplyWireSchema do
      use Ecto.Schema

      use Scrypath,
        fields: [:title],
        settings: %{
          ranking_rules: [:words, :typo, :proximity, :attribute, :sort, :exactness]
        }

      embedded_schema do
        field(:title, :string)
      end
    end

    test "sends camelCase wire payload without meta keys" do
      assert {:ok, %{}} =
               Settings.apply(ApplyWireSchema, "posts_v2",
                 meilisearch_client: RecordingClient,
                 settings: %{
                   synonyms: [["nyc", "new york"]],
                   ranking_rules_strict?: false,
                   ranking_rules: [:words, :typo, :proximity, :attribute, :sort, :exactness]
                 }
               )

      assert_received {:client_update_settings, "posts_v2", wire, _}

      assert wire["synonyms"] == %{
               "nyc" => ["new york"],
               "new york" => ["nyc"]
             }

      assert wire["rankingRules"] == [:words, :typo, :proximity, :attribute, :sort, :exactness]
      refute Map.has_key?(wire, :synonyms)
      refute Map.has_key?(wire, "rankingRulesStrict?")
    end
  end

  describe "resolve/2 (TUNE-06, D-09 regression, D-17 normalize-both-sides)" do
    defmodule ResolveSchemaQ do
      use Ecto.Schema

      use Scrypath,
        fields: [:t],
        settings: %{searchableAttributes: ["title"]}

      embedded_schema do
        field(:t, :string)
      end
    end

    test "default :replace mode is semantically identical to v1.2 Map.merge/2 (Q)" do
      result =
        Settings.resolve(ResolveSchemaQ,
          settings: %{sortableAttributes: ["inserted_at"]}
        )

      assert result[:searchable_attributes] == ["title"]
      assert result[:sortable_attributes] == ["inserted_at"]
      assert is_map(result[:__unrecognized__])
    end

    defmodule ResolveSchemaTypo do
      use Ecto.Schema

      use Scrypath,
        fields: [:t],
        settings: %{
          typo_tolerance: %{
            enabled: true,
            min_word_size_for_typos: %{one_typo: 5}
          }
        }

      embedded_schema do
        field(:t, :string)
      end
    end

    test ":replace loses nested keys on override (R)" do
      result =
        Settings.resolve(ResolveSchemaTypo,
          settings: %{typo_tolerance: %{enabled: false}},
          settings_merge: :replace
        )

      assert result[:typo_tolerance] == %{enabled: false}
    end

    test ":deep preserves nested keys on override (S)" do
      result =
        Settings.resolve(ResolveSchemaTypo,
          settings: %{typo_tolerance: %{enabled: false}},
          settings_merge: :deep
        )

      assert result[:typo_tolerance][:enabled] == false
      assert result[:typo_tolerance][:min_word_size_for_typos][:one_typo] == 5
    end

    defmodule ResolveSchemaSynonyms do
      use Ecto.Schema

      use Scrypath,
        fields: [:t],
        settings: %{
          synonyms: [["hello", "hi"]],
          typo_tolerance: %{enabled: true}
        }

      embedded_schema do
        field(:t, :string)
      end
    end

    test ":deep preserves schema top-level keys runtime does not touch (T)" do
      result =
        Settings.resolve(ResolveSchemaSynonyms,
          settings: %{typo_tolerance: %{enabled: false}},
          settings_merge: :deep
        )

      assert result[:synonyms] == [["hello", "hi"]]
      assert result[:typo_tolerance][:enabled] == false
    end

    defmodule ResolveSchemaUnrecLeft do
      use Ecto.Schema

      use Scrypath,
        fields: [:t],
        settings: %{custom_left: 1}

      embedded_schema do
        field(:t, :string)
      end
    end

    test "__unrecognized__ bucket merges with runtime winning on collision (U)" do
      result =
        Settings.resolve(ResolveSchemaUnrecLeft,
          settings: %{custom_left: 2, custom_right: 3},
          settings_merge: :deep
        )

      unrec = result[:__unrecognized__]
      assert unrec[:custom_left] == 2
      assert unrec[:custom_right] == 3
    end

    defmodule ResolveSchemaDoubled do
      use Ecto.Schema

      use Scrypath,
        fields: [:t],
        settings: %{searchable_attributes: ["y"]}

      embedded_schema do
        field(:t, :string)
      end
    end

    test "doubled-key impossibility: runtime camelCase normalizes to single atom key (V)" do
      result =
        Settings.resolve(ResolveSchemaDoubled,
          settings: %{searchableAttributes: ["x"]}
        )

      assert Map.keys(result) |> Enum.frequencies() |> Map.get(:searchable_attributes) == 1
      assert result[:searchable_attributes] == ["x"]
      refute Map.has_key?(result, :searchableAttributes)
    end

    test "settings_merge :replace and :deep both work (Y)" do
      assert %{} =
               Settings.resolve(ResolveSchemaTypo,
                 settings: %{typo_tolerance: %{enabled: false}},
                 settings_merge: :replace
               )

      assert %{} =
               Settings.resolve(ResolveSchemaTypo,
                 settings: %{typo_tolerance: %{enabled: false}},
                 settings_merge: :deep
               )
    end
  end

  describe "deep_merge via resolve/2 (D-12 hand-rolled, maps-only)" do
    defmodule DeepMergeListSchema do
      use Ecto.Schema

      use Scrypath,
        fields: [:t],
        settings: %{a: [1, 2]}

      embedded_schema do
        field(:t, :string)
      end
    end

    test "non-map values are terminal — right wins (W)" do
      result =
        Settings.resolve(DeepMergeListSchema,
          settings: %{a: [3]},
          settings_merge: :deep
        )

      assert result[:__unrecognized__][:a] == [3]
    end

    defmodule DeepMergeNestSchema do
      use Ecto.Schema

      use Scrypath,
        fields: [:t],
        settings: %{nested: %{b: %{c: 1, d: 2}}}

      embedded_schema do
        field(:t, :string)
      end
    end

    test "deep_merge recursion for nested maps (X)" do
      result =
        Settings.resolve(DeepMergeNestSchema,
          settings: %{nested: %{b: %{c: 99}}},
          settings_merge: :deep
        )

      assert result[:__unrecognized__][:nested][:b][:c] == 99
      assert result[:__unrecognized__][:nested][:b][:d] == 2
    end
  end

  describe "verify_applied/3 (TUNE-05)" do
    defmodule VerifyStubClient do
      def get_settings(_index, config), do: Keyword.fetch!(config, :__stub_response__)

      def update_settings(_, _, _), do: {:ok, %{"taskUid" => 1}}
    end

    defmodule VerifyAppliedSchema do
      use Ecto.Schema

      use Scrypath,
        fields: [:title],
        settings: %{
          synonyms: [["nyc", "new york"]],
          ranking_rules: [:words, :typo, :proximity, :attribute, :sort, :exactness]
        }

      embedded_schema do
        field(:title, :string)
      end
    end

    defmodule VerifySynonymsOnlySchema do
      use Ecto.Schema

      use Scrypath,
        fields: [:title],
        settings: %{synonyms: [["nyc", "new york"]]}

      embedded_schema do
        field(:title, :string)
      end
    end

    defmodule VerifyEmptySettingsSchema do
      use Ecto.Schema

      use Scrypath,
        fields: [:title]

      embedded_schema do
        field(:title, :string)
      end
    end

    defmodule VerifyFacetWireSchema do
      use Ecto.Schema

      use Scrypath,
        fields: [:title],
        filterable: [:genre],
        faceting: [attributes: [:genre]],
        settings: %{}

      embedded_schema do
        field(:title, :string)
      end
    end

    @base_config [
      backend: Scrypath.Meilisearch,
      meilisearch_url: "http://localhost:7700",
      meilisearch_client: VerifyStubClient
    ]

    test "parity when applied wire matches declared" do
      declared =
        VerifyAppliedSchema
        |> Settings.resolve(@base_config)
        |> Settings.translate_settings()

      config =
        Keyword.merge(@base_config,
          __stub_response__: {:ok, declared}
        )

      assert :ok = Settings.verify_applied(VerifyAppliedSchema, "posts_v2", config)
    end

    test "FACET verify_applied passes when applied includes facet-augmented filterableAttributes" do
      declared =
        VerifyFacetWireSchema
        |> Settings.resolve(@base_config)
        |> Settings.translate_settings()

      config = Keyword.merge(@base_config, __stub_response__: {:ok, declared})
      assert :ok = Settings.verify_applied(VerifyFacetWireSchema, "posts_v2", config)
    end

    test "drift when rankingRules diverge" do
      declared =
        VerifyAppliedSchema
        |> Settings.resolve(@base_config)
        |> Settings.translate_settings()

      applied = Map.put(declared, "rankingRules", ["typo", "proximity"])

      config =
        Keyword.merge(@base_config, __stub_response__: {:ok, applied})

      assert {:error, {:settings_drift, drift}} =
               Settings.verify_applied(VerifyAppliedSchema, "posts_v2", config)

      assert Enum.any?(drift, fn
               {"rankingRules", _, _} -> true
               _ -> false
             end)
    end

    test "404 becomes :index_not_found" do
      config =
        Keyword.merge(@base_config,
          __stub_response__: {:error, {:http_error, 404, "nope"}}
        )

      assert {:error, :index_not_found} =
               Settings.verify_applied(VerifyAppliedSchema, "posts_v2", config)
    end

    test "__unrecognized__ keys surface as drift when missing from applied" do
      with_unrec =
        Keyword.merge(@base_config,
          settings: %{__unrecognized__: %{"weirdKey" => 42}}
        )

      declared =
        VerifyAppliedSchema
        |> Settings.resolve(with_unrec)
        |> Settings.translate_settings()

      applied = Map.delete(declared, "weirdKey")

      config =
        Keyword.merge(with_unrec, __stub_response__: {:ok, applied})

      assert {:error, {:settings_drift, drift}} =
               Settings.verify_applied(VerifyAppliedSchema, "posts_v2", config)

      assert {"weirdKey", 42, :not_present} in drift
    end

    test "transport errors pass through" do
      config = Keyword.merge(@base_config, __stub_response__: {:error, :econnrefused})

      assert {:error, :econnrefused} =
               Settings.verify_applied(VerifyAppliedSchema, "posts_v2", config)
    end

    test "declared subset of applied does not flag Meilisearch defaults as drift" do
      declared =
        VerifySynonymsOnlySchema
        |> Settings.resolve(@base_config)
        |> Settings.translate_settings()

      applied =
        Map.merge(declared, %{
          "rankingRules" => ["words", "typo", "proximity", "attribute", "sort", "exactness"]
        })

      config =
        Keyword.merge(@base_config, __stub_response__: {:ok, applied})

      assert :ok = Settings.verify_applied(VerifySynonymsOnlySchema, "posts_v2", config)
    end

    test "empty declared settings yields :ok for any applied" do
      declared =
        VerifyEmptySettingsSchema
        |> Settings.resolve(@base_config)
        |> Settings.translate_settings()

      assert declared == %{}

      config =
        Keyword.merge(@base_config,
          __stub_response__: {:ok, %{"rankingRules" => ["words", "typo"]}}
        )

      assert :ok = Settings.verify_applied(VerifyEmptySettingsSchema, "posts_v2", config)
    end
  end

  describe "compute_drift/2 (pure)" do
    alias Scrypath.Meilisearch.Settings

    test "detects value mismatch" do
      assert [{"rankingRules", ["words"], ["typo"]}] ==
               Settings.compute_drift(
                 %{"rankingRules" => ["words"]},
                 %{"rankingRules" => ["typo"]}
               )
    end

    test "detects missing key as :not_present" do
      assert [{"synonyms", %{"a" => ["b"]}, :not_present}] ==
               Settings.compute_drift(
                 %{"synonyms" => %{"a" => ["b"]}},
                 %{}
               )
    end

    test "returns empty when all declared keys match" do
      assert [] ==
               Settings.compute_drift(
                 %{"synonyms" => %{}},
                 %{"synonyms" => %{}, "rankingRules" => ["words"]}
               )
    end
  end

  describe "FACET-07 facet-derived filterableAttributes in resolve/2" do
    test "FacetableMovie gets facetSearch objects for declared facet attrs" do
      resolved = Settings.resolve(FacetableMovie, [])
      wire = Settings.translate_settings(resolved)

      assert length(wire["filterableAttributes"]) == 4

      assert Enum.all?(wire["filterableAttributes"], fn entry ->
               attr = entry["attribute"] || entry[:attribute]
               fs = entry["features"] || entry[:features]
               is_binary(attr) and is_list(fs) and "facetSearch" in fs
             end)
    end

    defmodule FacetOverrideSchema do
      use Ecto.Schema

      use Scrypath,
        fields: [:t],
        filterable: [:genre],
        faceting: [attributes: [:genre]],
        settings: %{filterable_attributes: [%{attribute: "genre", features: ["filtering"]}]}

      embedded_schema do
        field(:t, :string)
      end
    end

    test "explicit filterableAttributes entry wins over facet-derived replacement" do
      resolved = Settings.resolve(FacetOverrideSchema, [])
      assert [%{attribute: "genre", features: ["filtering"]}] == resolved[:filterable_attributes]
    end
  end

  describe "hot_apply/3 (TUNE14-01)" do
    defmodule HotApplySucceededClient do
      def update_settings(index_name, settings, config) do
        send(self(), {:client_update_settings, index_name, settings, config})

        {:ok,
         %{
           "taskUid" => 77,
           "indexUid" => index_name,
           "status" => "succeeded",
           "type" => "settingsUpdate"
         }}
      end
    end

    defmodule HotApplyHttpErrorClient do
      def update_settings(_index_name, _settings, _config) do
        {:error, {:http_error, 400, %{"message" => "bad"}}}
      end
    end

    test "no acknowledge_live_index skips HTTP" do
      assert {:error, :live_ack_required} =
               Settings.hot_apply(ApplyWireSchema, "idx",
                 meilisearch_client: HotApplySucceededClient,
                 settings: %{stop_words: ["a"]}
               )

      refute_received {:client_update_settings, _, _, _}
    end

    test "unsupported key returns sorted atoms and skips HTTP" do
      assert {:error, {:unsupported_hot_apply_keys, [:ranking_rules]}} =
               Settings.hot_apply(ApplyWireSchema, "idx",
                 acknowledge_live_index: true,
                 meilisearch_client: HotApplySucceededClient,
                 settings: %{stop_words: ["a"], ranking_rules: [:words]}
               )

      refute_received {:client_update_settings, _, _, _}
    end

    test "happy path: succeeded task without polling" do
      expected_wire = Settings.translate_settings(%{stop_words: ["the"]})

      assert {:ok, %{index: "idx", task: %{uid: 77, status: :succeeded}}} =
               Settings.hot_apply(ApplyWireSchema, "idx",
                 acknowledge_live_index: true,
                 meilisearch_client: HotApplySucceededClient,
                 backend: Scrypath.Meilisearch,
                 meilisearch_url: "http://localhost:7700",
                 inline_poll_interval: 1,
                 inline_timeout: 10_000,
                 settings: %{stop_words: ["the"]}
               )

      assert_received {:client_update_settings, "idx", ^expected_wire, _}
    end

    test "update_settings HTTP error becomes hot_apply_failed" do
      assert {:error, {:hot_apply_failed, details}} =
               Settings.hot_apply(ApplyWireSchema, "idx",
                 acknowledge_live_index: true,
                 meilisearch_client: HotApplyHttpErrorClient,
                 settings: %{stop_words: ["x"]}
               )

      assert details.type == :http
      assert details.status == 400
      assert inspect(details) =~ "400"
    end
  end
end
