defmodule Scrypath.Options do
  @moduledoc false

  @schema_options [
    fields: [
      type: {:list, :atom},
      required: true,
      doc: "Fields projected by default into a search document."
    ],
    filterable: [
      type: {:list, :atom},
      default: [],
      doc: "Fields that later search APIs may expose as filters."
    ],
    faceting: [
      type: {:custom, __MODULE__, :validate_schema_faceting, []},
      default: [],
      doc:
        "Optional facet metadata: non-empty :attributes (subset of :filterable), :max_values_per_facet, :sort_facet_values_by, optional :nested_facet_paths, optional :hierarchy (compile-time expansion into lvlN attributes)."
    ],
    sortable: [
      type: {:list, :atom},
      default: [],
      doc: "Fields that later search APIs may expose as sorts."
    ],
    settings: [
      type: {:custom, __MODULE__, :validate_settings, []},
      default: %{},
      doc: "Explicit Meilisearch index settings stored as schema metadata."
    ],
    document_id: [
      type: :atom,
      default: :id,
      doc: "Field used as the canonical search document identifier."
    ],
    index_prefix: [
      type: {:custom, __MODULE__, :validate_optional_string, []},
      default: nil,
      doc: "Optional per-schema index prefix."
    ],
    fan_outs: [
      type: {:custom, __MODULE__, :validate_fan_outs, []},
      default: [],
      doc: "Explicit related-data fan-out metadata for propagation."
    ],
    backend: [
      type: {:custom, __MODULE__, :validate_backend, []},
      default: nil,
      doc: "Optional backend override."
    ],
    tenant_field: [
      type: {:custom, __MODULE__, :validate_tenant_field, []},
      default: nil,
      doc:
        "Optional tenant field name auto-injected into both `filterable:` and `fields:` for shared-index multitenancy."
    ]
  ]

  @runtime_options [
    fan_out: [
      type: {:custom, __MODULE__, :validate_optional_atom, []},
      default: nil,
      doc: "Optional fan_out key used by sync_related to resolve related records."
    ],
    backend: [
      type: {:custom, __MODULE__, :validate_backend, []},
      required: true,
      doc: "Backend module responsible for search operations."
    ],
    repo: [
      type: {:custom, __MODULE__, :validate_optional_module, []},
      default: nil,
      doc: "Optional Ecto repo used by runtime operations."
    ],
    otp_app: [
      type: {:custom, __MODULE__, :validate_optional_atom, []},
      default: nil,
      doc:
        "Optional OTP application used to resolve per-repo `:scrypath` config when `:repo` is set and `Application.get_application/1` is nil (common in tests)."
    ],
    index_prefix: [
      type: {:custom, __MODULE__, :validate_optional_string, []},
      default: nil,
      doc: "Optional runtime index prefix override."
    ],
    sync_mode: [
      type: {:in, [:inline, :manual, :oban]},
      default: :inline,
      doc:
        "Synchronization mode for writes (`:inline`, `:manual`, `:oban`). This controls visibility " <>
          "latency vs durability—see guides/sync-modes-and-visibility.md; do not confuse enqueue acceptance with search visibility."
    ],
    oban: [
      type: {:custom, __MODULE__, :validate_optional_module, []},
      default: Oban,
      doc: "Optional Oban instance module override used for durable sync enqueueing."
    ],
    oban_queue: [
      type: {:custom, __MODULE__, :validate_optional_atom, []},
      default: nil,
      doc: "Explicit Oban queue used when sync_mode is :oban."
    ],
    oban_max_attempts: [
      type: {:custom, __MODULE__, :validate_positive_integer_or_nil, []},
      default: 8,
      doc: "Maximum Oban retry attempts to use for sync jobs."
    ],
    meilisearch_url: [
      type: {:custom, __MODULE__, :validate_optional_string, []},
      default: nil,
      doc: "Base URL for the configured Meilisearch server."
    ],
    meilisearch_api_key: [
      type: {:custom, __MODULE__, :validate_optional_string, []},
      default: nil,
      doc: "Optional API key for Meilisearch requests."
    ],
    meilisearch_client: [
      type: {:custom, __MODULE__, :validate_optional_module, []},
      default: nil,
      doc: "Optional Meilisearch client override for tests."
    ],
    req_options: [
      type: {:custom, __MODULE__, :validate_keyword_list, []},
      default: [],
      doc: "Optional Req overrides passed through to Meilisearch transport calls."
    ],
    inline_poll_interval: [
      type: {:custom, __MODULE__, :validate_positive_integer, []},
      default: 100,
      doc:
        "Poll interval in milliseconds between Meilisearch task status checks during inline waits—lower values mean more frequent polls."
    ],
    inline_timeout: [
      type: {:custom, __MODULE__, :validate_positive_integer, []},
      default: 5_000,
      doc:
        "Maximum time in milliseconds to wait for a Meilisearch task to reach a terminal state when `sync_mode: :inline`."
    ],
    preload: [
      type: {:custom, __MODULE__, :validate_preload, []},
      default: [],
      doc: "Optional preload list applied only to repo-side hydration."
    ],
    settings_merge: [
      type: {:in, [:replace, :deep]},
      default: :replace,
      doc:
        "Merge strategy for runtime settings overrides against schema-declared settings. :replace (default) mirrors v1.2 Map.merge/2 behavior; :deep enables recursive map merge."
    ],
    federation_limit: [
      type: {:custom, __MODULE__, :validate_positive_integer, []},
      default: 200,
      doc: "Federated multi-search global hit limit passed to Meilisearch (shared opts only)."
    ],
    federation_offset: [
      type: :non_neg_integer,
      default: 0,
      doc: "Federated multi-search global offset (shared opts only)."
    ],
    federation_timeout: [
      type: {:custom, __MODULE__, :validate_positive_integer, []},
      default: 7_500,
      doc: "Reserved cumulative federation timeout budget in milliseconds (shared configuration)."
    ],
    hydration_timeout: [
      type: {:custom, __MODULE__, :validate_positive_integer, []},
      default: 5_000,
      doc: "Per-schema hydration timeout for search_many/2 (Task.async_stream/5)."
    ],
    max_schemas: [
      type: {:custom, __MODULE__, :validate_positive_integer, []},
      default: 10,
      doc: "Maximum number of schemas per search_many/2 call (cardinality rail)."
    ],
    global_schemas: [
      type: {:custom, __MODULE__, :validate_global_schemas, []},
      required: false,
      doc:
        "When set, replaces Application.get_env(otp_app, :scrypath_global_search_schemas, []) as the " <>
          "ordered allowlist for `{:all, …}` expansion in search_many/2 for this call."
    ]
  ]

  @search_options [
    tenant_scope: [
      type: :any,
      doc: "Hard-injected filter for the declared tenant_field."
    ],
    facets: [
      type: {:list, :atom},
      default: [],
      doc:
        "Facet attribute names to request facet distribution for (must be declared on the schema's faceting.attributes)."
    ],
    facet_filter: [
      type: {:custom, __MODULE__, :validate_search_filter, []},
      default: [],
      doc:
        "Keyword of facet-field filters; keys must be declared faceting attributes. Same value shapes as :filter where applicable."
    ],
    filter: [
      type: {:custom, __MODULE__, :validate_search_filter, []},
      default: [],
      doc: "Structured common-path filters over declared filterable fields."
    ],
    sort: [
      type: {:custom, __MODULE__, :validate_search_sort, []},
      default: [],
      doc: "Ecto-style sort order over declared sortable fields."
    ],
    page: [
      type: {:custom, __MODULE__, :validate_search_page, []},
      default: [],
      doc: "Nested common-path pagination options."
    ],
    per_query: [
      type: {:custom, __MODULE__, :validate_per_query_map, []},
      default: %{},
      doc:
        "Allowlisted Plane B per-request Meilisearch ranking-score knobs (see guides/per-query-tuning-pipeline.md)."
    ]
  ]

  @backfill_options [
    backend: [
      type: {:custom, __MODULE__, :validate_module, []},
      required: true,
      doc: "Backend module responsible for bulk indexing operations."
    ],
    repo: [
      type: {:custom, __MODULE__, :validate_module, []},
      required: true,
      doc: "Ecto repo used to read source records for the backfill."
    ],
    batch_size: [
      type: {:custom, __MODULE__, :validate_positive_integer, []},
      required: true,
      doc: "Positive batch size for bulk reads and writes."
    ],
    query: [
      type: :any,
      default: nil,
      doc: "Optional explicit queryable override for the source dataset."
    ],
    index_prefix: [
      type: {:custom, __MODULE__, :validate_optional_string, []},
      default: nil,
      doc: "Optional runtime index prefix override for the bulk workflow."
    ],
    index_name: [
      type: {:custom, __MODULE__, :validate_optional_string, []},
      default: nil,
      doc: "Optional explicit index target override."
    ],
    meilisearch_url: [
      type: {:custom, __MODULE__, :validate_optional_string, []},
      default: nil,
      doc: "Base URL for the configured Meilisearch server."
    ],
    meilisearch_api_key: [
      type: {:custom, __MODULE__, :validate_optional_string, []},
      default: nil,
      doc: "Optional API key for Meilisearch requests."
    ],
    meilisearch_client: [
      type: {:custom, __MODULE__, :validate_optional_module, []},
      default: nil,
      doc: "Optional Meilisearch client override for tests."
    ],
    req_options: [
      type: {:custom, __MODULE__, :validate_keyword_list, []},
      default: [],
      doc: "Optional Req overrides passed through to Meilisearch transport calls."
    ],
    inline_poll_interval: [
      type: {:custom, __MODULE__, :validate_positive_integer, []},
      default: 100,
      doc: "Polling interval in milliseconds while waiting for Meilisearch workflow tasks."
    ],
    inline_timeout: [
      type: {:custom, __MODULE__, :validate_positive_integer, []},
      default: 5_000,
      doc: "Task wait timeout in milliseconds for Meilisearch workflow steps."
    ],
    sync_mode: [
      type: {:in, [:inline, :manual, :oban]},
      default: :manual,
      doc: "Execution mode for the bulk workflow."
    ]
  ]

  @reindex_options [
    backend: [
      type: {:custom, __MODULE__, :validate_module, []},
      required: true,
      doc: "Backend module responsible for reindex operations."
    ],
    repo: [
      type: {:custom, __MODULE__, :validate_module, []},
      required: true,
      doc: "Ecto repo used to read source records for the rebuild."
    ],
    batch_size: [
      type: {:custom, __MODULE__, :validate_positive_integer, []},
      required: true,
      doc: "Positive batch size for rebuild reads and writes."
    ],
    index_prefix: [
      type: {:custom, __MODULE__, :validate_optional_string, []},
      default: nil,
      doc: "Optional runtime index prefix override for the rebuild."
    ],
    target_index: [
      type: {:custom, __MODULE__, :validate_optional_string, []},
      default: nil,
      doc: "Optional explicit target index name override."
    ],
    cutover?: [
      type: :boolean,
      default: true,
      doc: "Whether the managed rebuild should perform cutover."
    ],
    settings: [
      type: {:custom, __MODULE__, :validate_settings, []},
      default: %{},
      doc: "Optional explicit settings override applied during rebuild."
    ],
    meilisearch_url: [
      type: {:custom, __MODULE__, :validate_optional_string, []},
      default: nil,
      doc: "Base URL for the configured Meilisearch server."
    ],
    meilisearch_api_key: [
      type: {:custom, __MODULE__, :validate_optional_string, []},
      default: nil,
      doc: "Optional API key for Meilisearch requests."
    ],
    meilisearch_client: [
      type: {:custom, __MODULE__, :validate_optional_module, []},
      default: nil,
      doc: "Optional Meilisearch client override for tests."
    ],
    req_options: [
      type: {:custom, __MODULE__, :validate_keyword_list, []},
      default: [],
      doc: "Optional Req overrides passed through to Meilisearch transport calls."
    ],
    inline_poll_interval: [
      type: {:custom, __MODULE__, :validate_positive_integer, []},
      default: 100,
      doc: "Polling interval in milliseconds while waiting for Meilisearch workflow tasks."
    ],
    inline_timeout: [
      type: {:custom, __MODULE__, :validate_positive_integer, []},
      default: 5_000,
      doc: "Task wait timeout in milliseconds for Meilisearch workflow steps."
    ],
    sync_mode: [
      type: {:in, [:inline, :manual, :oban]},
      default: :manual,
      doc: "Execution mode for the reindex workflow."
    ],
    settings_merge: [
      type: {:in, [:replace, :deep]},
      default: :replace,
      doc:
        "Merge strategy for runtime settings overrides against schema-declared settings. :replace (default) mirrors v1.2 Map.merge/2 behavior; :deep enables recursive map merge."
    ],
    skip_settings_verification?: [
      type: :boolean,
      default: false,
      doc:
        "When true, skips the post-apply Meilisearch settings drift check during managed reindex. Emits a warning and telemetry."
    ]
  ]

  @spec validate_schema_options!(keyword()) :: map()
  def validate_schema_options!(opts) do
    opts
    |> validate!(@schema_options)
    |> ensure_non_empty_fields!()
    |> Scrypath.Options.Faceting.validate_rules!()
    |> normalize_tenant_field!()
    |> Map.put(:document_source, :fields)
  end

  @spec validate_runtime_options!(keyword()) :: keyword()
  def validate_runtime_options!(opts) do
    opts
    |> validate!(@runtime_options)
    |> validate_oban_runtime_options!()
  end

  @spec validate_backfill_options!(keyword()) :: keyword()
  def validate_backfill_options!(opts) do
    opts
    |> validate!(@backfill_options)
    |> validate_bulk_sync_mode!()
  end

  @spec validate_reindex_options!(keyword()) :: keyword()
  def validate_reindex_options!(opts) do
    opts
    |> validate!(@reindex_options)
    |> validate_bulk_sync_mode!()
  end

  @doc """
  Validates search options for `schema_module` without raising.

  Returns `{:ok, keyword()}` with the same keys as `validate_search_options!/2`.

  When the schema declares no `faceting:` attributes, any non-empty `:facets`
  list fails with `{:error, {:unknown_facet, first_atom}}` using the first
  requested facet (Meilisearch still requires declared facet settings).

  For `{:error, {:invalid_options, _}}` and related federation / `:all` expansion
  failures surfaced through `Scrypath.search_many/2`, see
  [guides/multi-index-search.md](guides/multi-index-search.md) for the canonical
  rules—this function only validates per-schema search options, not the full
  multi-search composition.
  """
  @spec validate_search_options(module(), keyword()) :: {:ok, keyword()} | {:error, term()}
  def validate_search_options(schema_module, opts) when is_list(opts) do
    Scrypath.Options.Search.validate(
      schema_module,
      opts,
      @search_options,
      Keyword.keys(@runtime_options)
    )
  end

  @spec validate_search_options!(module(), keyword()) :: keyword()
  def validate_search_options!(schema_module, opts) do
    case validate_search_options(schema_module, opts) do
      {:ok, kw} ->
        kw

      {:error, {:validation, message}} when is_binary(message) ->
        raise ArgumentError, message

      {:error, {:invalid_options, _field, message}} when is_binary(message) ->
        raise ArgumentError, message

      {:error, {:unknown_facet, facet}} ->
        raise ArgumentError, "unknown facet #{inspect(facet)}"

      {:error, {:invalid_facet_filter, reason}} ->
        raise ArgumentError, "facet_filter: #{inspect(reason)}"
    end
  end

  @doc false
  defdelegate validate_schema_faceting(value),
    to: Scrypath.Options.Faceting,
    as: :validate_declaration

  def validate_optional_string(value) when is_binary(value), do: {:ok, value}
  def validate_optional_string(nil), do: {:ok, nil}
  def validate_optional_string(_value), do: {:error, "expected a string or nil"}

  def validate_module(value) when is_atom(value), do: {:ok, value}
  def validate_module(_value), do: {:error, "expected a module"}

  @doc false
  def validate_global_schemas(value) when is_list(value) do
    Enum.reduce_while(value, {:ok, value}, fn m, _acc ->
      case validate_module(m) do
        {:ok, _} -> {:cont, {:ok, value}}
        {:error, msg} -> {:halt, {:error, "global_schemas must be a list of modules (#{msg})"}}
      end
    end)
  end

  def validate_global_schemas(_value),
    do: {:error, "global_schemas must be a list of module atoms or be omitted"}

  defdelegate validate_settings(value), to: Scrypath.Options.Settings, as: :validate

  @doc false
  @spec normalize_settings(map()) :: map()
  defdelegate normalize_settings(value), to: Scrypath.Options.Settings, as: :normalize

  @doc false
  defdelegate canonicalize_key(key), to: Scrypath.Options.Settings

  @doc false
  @spec validate_recognized_subkeys(map()) :: :ok | {:error, String.t()}
  defdelegate validate_recognized_subkeys(canonical), to: Scrypath.Options.Settings

  @doc false
  defdelegate check_ranking_rules_completeness(canonical), to: Scrypath.Options.Settings

  def validate_backend(value) when is_atom(value) or is_nil(value), do: {:ok, value}
  def validate_backend(_value), do: {:error, "expected a module, atom, or nil"}

  @doc false
  def validate_tenant_field(nil), do: {:ok, nil}
  def validate_tenant_field(value) when is_atom(value), do: {:ok, value}
  def validate_tenant_field(_value), do: {:error, "tenant_field must be an atom or nil"}

  @doc false
  def validate_fan_outs([]), do: {:ok, []}

  def validate_fan_outs(value) when is_list(value) do
    if Keyword.keyword?(value) do
      Enum.reduce_while(value, {:ok, []}, fn {key, config}, {:ok, acc} ->
        case validate_fan_out_config(config) do
          {:ok, validated} -> {:cont, {:ok, [{key, validated} | acc]}}
          {:error, msg} -> {:halt, {:error, msg}}
        end
      end)
      |> case do
        {:ok, list} -> {:ok, Enum.reverse(list)}
        error -> error
      end
    else
      {:error, "fan_outs must be a keyword list"}
    end
  end

  def validate_fan_outs(_value), do: {:error, "fan_outs must be a keyword list"}

  defp validate_fan_out_config(config) when is_list(config) do
    if Keyword.keyword?(config) do
      with {:ok, target} <- fetch_and_validate_module(config, :target),
           {:ok, resolver} <- fetch_and_validate_mfa(config, :resolver) do
        {:ok, [target: target, resolver: resolver]}
      end
    else
      {:error, "fan_out configuration must be a keyword list"}
    end
  end

  defp validate_fan_out_config(_), do: {:error, "fan_out configuration must be a keyword list"}

  defp fetch_and_validate_module(config, key) do
    case Keyword.fetch(config, key) do
      {:ok, module} when is_atom(module) -> {:ok, module}
      {:ok, _} -> {:error, "fan_out :#{key} must be a module"}
      :error -> {:error, "fan_out is missing required :#{key}"}
    end
  end

  defp fetch_and_validate_mfa(config, key) do
    case Keyword.fetch(config, key) do
      {:ok, {mod, fun, args}} when is_atom(mod) and is_atom(fun) and is_list(args) ->
        {:ok, {mod, fun, args}}

      {:ok, _} ->
        {:error, "fan_out :#{key} must be a valid MFA tuple {Module, :func, [args]}"}

      :error ->
        {:error, "fan_out is missing required :#{key}"}
    end
  end

  def validate_optional_module(value) when is_atom(value) or is_nil(value), do: {:ok, value}
  def validate_optional_module(_value), do: {:error, "expected a module or nil"}

  def validate_optional_atom(value) when is_atom(value) or is_nil(value), do: {:ok, value}
  def validate_optional_atom(_value), do: {:error, "expected an atom or nil"}

  def validate_keyword_list(value) when is_list(value) do
    if Keyword.keyword?(value), do: {:ok, value}, else: {:error, "expected a keyword list"}
  end

  def validate_keyword_list(_value), do: {:error, "expected a keyword list"}

  def validate_positive_integer(value) when is_integer(value) and value > 0, do: {:ok, value}
  def validate_positive_integer(_value), do: {:error, "expected a positive integer"}

  def validate_positive_integer_or_nil(nil), do: {:ok, nil}

  def validate_positive_integer_or_nil(value) do
    validate_positive_integer(value)
  end

  def validate_preload(nil), do: {:ok, []}
  def validate_preload(value) when is_atom(value), do: {:ok, [value]}
  def validate_preload(value) when is_list(value), do: {:ok, value}
  def validate_preload(_value), do: {:error, "expected a preload atom, list, or nil"}

  def validate_search_filter(value) when is_list(value) do
    if Keyword.keyword?(value) do
      {:ok, value}
    else
      {:error, "expected filter to be a keyword list"}
    end
  end

  def validate_search_filter(_value), do: {:error, "expected filter to be a keyword list"}

  def validate_search_sort(value) when is_list(value) do
    if Keyword.keyword?(value) do
      {:ok, value}
    else
      {:error, "expected sort to be a keyword list"}
    end
  end

  def validate_search_sort(_value), do: {:error, "expected sort to be a keyword list"}

  @per_query_allowlist ~w(
    ranking_score_threshold
    show_ranking_score
    show_ranking_score_details
  )a

  @doc false
  def per_query_allowlist, do: @per_query_allowlist

  @doc false
  def validate_per_query_map(nil), do: {:ok, %{}}

  def validate_per_query_map(value) when value == %{} or value == [] do
    {:ok, %{}}
  end

  def validate_per_query_map(value) when is_list(value) do
    if Keyword.keyword?(value) do
      value |> Map.new() |> validate_per_query_map()
    else
      {:error, "expected per_query to be a keyword list, map, [], or %{}"}
    end
  end

  def validate_per_query_map(value) when is_map(value) do
    validate_per_query_entries(value)
  end

  def validate_per_query_map(_value),
    do: {:error, "expected per_query to be a keyword list, map, [], or %{}"}

  defp validate_per_query_entries(map) do
    Enum.reduce_while(map, {:ok, %{}}, fn {key, val}, {:ok, acc} ->
      cond do
        not is_atom(key) ->
          {:halt, {:error, "per_query keys must be atoms"}}

        key not in @per_query_allowlist ->
          {:halt, {:error, "unknown per_query key #{inspect(key)}"}}

        true ->
          case validate_per_query_value(key, val) do
            {:ok, normalized} -> {:cont, {:ok, Map.put(acc, key, normalized)}}
            {:error, _} = err -> {:halt, err}
          end
      end
    end)
  end

  defp validate_per_query_value(:ranking_score_threshold, val)
       when is_number(val) and val >= 0 do
    {:ok, val}
  end

  defp validate_per_query_value(:ranking_score_threshold, val),
    do:
      {:error,
       "per_query :ranking_score_threshold must be a non-negative number, got: #{inspect(val)}"}

  defp validate_per_query_value(:show_ranking_score, val) when val in [true, false],
    do: {:ok, val}

  defp validate_per_query_value(:show_ranking_score, val),
    do: {:error, "per_query :show_ranking_score must be a boolean, got: #{inspect(val)}"}

  defp validate_per_query_value(:show_ranking_score_details, val) when val in [true, false],
    do: {:ok, val}

  defp validate_per_query_value(:show_ranking_score_details, val),
    do: {:error, "per_query :show_ranking_score_details must be a boolean, got: #{inspect(val)}"}

  def validate_search_page(value) when is_list(value) do
    if Keyword.keyword?(value) do
      value
      |> validate!(page_options_schema())
      |> validate_page_bounds!()
      |> Enum.into(%{})
      |> then(&{:ok, &1})
    else
      {:error, "expected page to be a keyword list"}
    end
  end

  def validate_search_page(_value), do: {:error, "expected page to be a keyword list"}

  defp validate!(opts, schema) do
    case NimbleOptions.validate(opts, schema) do
      {:ok, validated} ->
        validated

      {:error, error} ->
        raise ArgumentError, Exception.message(error)
    end
  end

  defp validate_oban_runtime_options!(opts) do
    if Keyword.get(opts, :sync_mode) == :oban and is_nil(Keyword.get(opts, :oban_queue)) do
      raise ArgumentError, "oban_queue is required when sync_mode is :oban"
    end

    opts
  end

  defp validate_bulk_sync_mode!(opts) do
    if Keyword.get(opts, :sync_mode) == :oban do
      raise ArgumentError, "sync_mode :oban is not supported for bulk workflows"
    end

    opts
  end

  defp normalize_tenant_field!(%{tenant_field: nil} = m), do: m

  defp normalize_tenant_field!(%{tenant_field: field} = m) when is_atom(field) do
    existing_fields = Map.fetch!(m, :fields)
    new_fields = dedupe_preserve_order(existing_fields ++ [field])

    if field not in existing_fields do
      IO.warn(
        "[scrypath] tenant_field #{inspect(field)} is not listed in fields:. It has been auto-added so search documents include the tenant value. To silence this warning, add #{inspect(field)} to fields: explicitly.",
        []
      )
    end

    new_filterable = dedupe_preserve_order(Map.fetch!(m, :filterable) ++ [field])
    %{m | fields: new_fields, filterable: new_filterable}
  end

  defp ensure_non_empty_fields!(opts) do
    case Keyword.fetch!(opts, :fields) do
      [] ->
        raise ArgumentError, "fields must contain at least one field"

      _fields ->
        Enum.into(opts, %{})
    end
  end

  defp dedupe_preserve_order(attrs) when is_list(attrs) do
    {uniq, _} =
      Enum.reduce(attrs, {[], MapSet.new()}, fn a, {acc, seen} ->
        if MapSet.member?(seen, a) do
          {acc, seen}
        else
          {[a | acc], MapSet.put(seen, a)}
        end
      end)

    Enum.reverse(uniq)
  end

  defp validate_page_bounds!(page) do
    case Keyword.get(page, :number) do
      nil -> :ok
      number when number > 0 -> :ok
      _ -> raise ArgumentError, "page number must be greater than 0"
    end

    case Keyword.get(page, :size) do
      nil -> :ok
      size when size > 0 -> :ok
      _ -> raise ArgumentError, "page size must be greater than 0"
    end

    page
  end

  defp page_options_schema do
    [
      number: [
        type: :integer,
        required: false
      ],
      size: [
        type: :integer,
        required: false
      ]
    ]
  end
end
