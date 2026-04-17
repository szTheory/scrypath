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
    backend: [
      type: {:custom, __MODULE__, :validate_backend, []},
      default: nil,
      doc: "Optional backend override."
    ]
  ]

  @runtime_options [
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
      doc: "Synchronization mode to use for write operations."
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
      doc: "Polling interval in milliseconds while waiting for inline task completion."
    ],
    inline_timeout: [
      type: {:custom, __MODULE__, :validate_positive_integer, []},
      default: 5_000,
      doc: "Inline task wait timeout in milliseconds."
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
    ]
  ]

  @search_options [
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

  @recognized_subkeys [
    :synonyms,
    :typo_tolerance,
    :ranking_rules,
    :distinct_attribute,
    :stop_words
  ]

  @legacy_camel_allowlist [
    :searchableAttributes,
    :sortableAttributes,
    :filterableAttributes,
    :displayedAttributes,
    :typoTolerance
  ]

  @legacy_camel_strings Enum.map(@legacy_camel_allowlist, &Atom.to_string/1)

  @attribute_keys [
    :searchable_attributes,
    :sortable_attributes,
    :filterable_attributes,
    :displayed_attributes
  ]

  @meilisearch_default_ranking_rules [:words, :typo, :proximity, :attribute, :sort, :exactness]

  @nested_settings_schema [
    synonyms: [type: {:or, [:map, {:list, :any}]}, required: false],
    typo_tolerance: [
      type: {:or, [:keyword_list, :map]},
      keys: [
        enabled: [type: :boolean, required: false],
        min_word_size_for_typos: [type: :map, required: false],
        disable_on_words: [type: {:list, :string}, required: false],
        disable_on_attributes: [type: {:list, :string}, required: false]
      ],
      required: false
    ],
    ranking_rules: [type: {:list, {:or, [:atom, :string]}}, required: false],
    ranking_rules_strict?: [type: :boolean, required: false],
    distinct_attribute: [type: {:or, [:atom, :string, nil]}, required: false],
    stop_words: [type: {:list, :string}, required: false],
    searchable_attributes: [type: {:list, :any}, required: false],
    sortable_attributes: [type: {:list, :any}, required: false],
    filterable_attributes: [type: {:list, :any}, required: false],
    displayed_attributes: [type: {:list, :any}, required: false]
  ]

  @spec validate_schema_options!(keyword()) :: map()
  def validate_schema_options!(opts) do
    opts
    |> validate!(@schema_options)
    |> ensure_non_empty_fields!()
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

  @spec validate_search_options!(module(), keyword()) :: keyword()
  def validate_search_options!(schema_module, opts) do
    filterable = MapSet.new(schema_module.__scrypath__(:filterable))
    sortable = MapSet.new(schema_module.__scrypath__(:sortable))

    opts
    |> Keyword.drop(runtime_option_keys())
    |> validate!(@search_options)
    |> validate_filterable_fields!(filterable)
    |> validate_sortable_fields!(sortable)
  end

  def validate_optional_string(value) when is_binary(value), do: {:ok, value}
  def validate_optional_string(nil), do: {:ok, nil}
  def validate_optional_string(_value), do: {:error, "expected a string or nil"}

  def validate_module(value) when is_atom(value), do: {:ok, value}
  def validate_module(_value), do: {:error, "expected a module"}

  def validate_settings(value) when is_map(value) do
    canonical = normalize_settings(value)

    case validate_recognized_subkeys(canonical) do
      :ok ->
        check_ranking_rules_completeness(canonical)
        {:ok, canonical}

      {:error, msg} ->
        {:error, msg}
    end
  end

  def validate_settings(value) do
    cond do
      Macro.quoted_literal?(value) ->
        {evaluated, _binding} = Code.eval_quoted(value)

        if is_map(evaluated) do
          validate_settings(evaluated)
        else
          {:error, "expected settings to be a plain map"}
        end

      true ->
        {:error, "expected settings to be a plain map"}
    end
  end

  @doc false
  @spec normalize_settings(map()) :: map()
  def normalize_settings(value) when is_map(value) do
    entries =
      Enum.map(value, fn {raw_key, val} ->
        ckey = canonicalize_key(raw_key)
        {raw_key, ckey, val}
      end)

    emit_camel_hint? =
      Enum.any?(entries, fn {raw_key, _ckey, _val} -> camel_case_source_key?(raw_key) end)

    if emit_camel_hint? do
      IO.puts(
        :stderr,
        "[scrypath] a schema declared settings using camelCase keys. Canonical form is snake_case atom keys for recognized settings. Both forms work; No action required."
      )
    end

    {recognized_pairs, unrecognized_pairs} =
      Enum.split_with(entries, fn {_raw, ckey, _val} -> is_atom(ckey) end)

    recognized_pairs =
      Enum.map(recognized_pairs, fn {_raw, ckey, val} -> {ckey, val} end)

    unrecognized_pairs =
      Enum.map(unrecognized_pairs, fn {_raw, {:unrecognized, rk}, val} -> {rk, val} end)

    recognized_map = Map.new(recognized_pairs)
    unrecognized_map = Map.new(unrecognized_pairs)

    Map.put(recognized_map, :__unrecognized__, unrecognized_map)
  end

  @doc false
  def canonicalize_key(key) when is_atom(key) do
    cond do
      key in @recognized_subkeys ->
        key

      key in @attribute_keys ->
        key

      key in @legacy_camel_allowlist ->
        key
        |> Atom.to_string()
        |> Macro.underscore()
        |> string_to_existing_atom!()

      true ->
        {:unrecognized, key}
    end
  end

  def canonicalize_key(key) when is_binary(key) do
    cond do
      key in @legacy_camel_strings ->
        legacy = Enum.find(@legacy_camel_allowlist, &(Atom.to_string(&1) == key))
        canonicalize_key(legacy)

      true ->
        snake = Macro.underscore(key)
        snake_atom = safe_string_to_existing_atom(snake)

        cond do
          snake_atom != nil and snake_atom in @recognized_subkeys ->
            snake_atom

          snake_atom != nil and snake_atom in @attribute_keys ->
            snake_atom

          true ->
            {:unrecognized, key}
        end
    end
  end

  def canonicalize_key(key), do: {:unrecognized, key}

  @doc false
  @spec validate_recognized_subkeys(map()) :: :ok | {:error, String.t()}
  def validate_recognized_subkeys(canonical) when is_map(canonical) do
    slice =
      canonical
      |> Map.delete(:__unrecognized__)
      |> Map.to_list()

    case NimbleOptions.validate(slice, @nested_settings_schema) do
      {:ok, _} ->
        :ok

      {:error, %NimbleOptions.ValidationError{} = error} ->
        {:error, Exception.message(error)}
    end
  end

  @doc false
  def check_ranking_rules_completeness(canonical) when is_map(canonical) do
    rules = canonical[:ranking_rules]
    strict? = Map.get(canonical, :ranking_rules_strict?)

    if is_list(rules) and strict? != false do
      normalized =
        Enum.map(rules, fn rule ->
          cond do
            is_atom(rule) ->
              rule

            is_binary(rule) ->
              safe_string_to_existing_atom(rule) || rule

            true ->
              rule
          end
        end)

      missing = @meilisearch_default_ranking_rules -- normalized

      if missing != [] do
        IO.puts(
          :stderr,
          "[scrypath] ranking_rules is missing the following Meilisearch defaults: #{inspect(missing)}. Add them or set ranking_rules_strict?: false. This is a warning; reindex will hard-error (TUNE-04)."
        )
      end
    end

    canonical
  end

  defp camel_case_source_key?(key) when is_atom(key), do: key in @legacy_camel_allowlist

  defp camel_case_source_key?(key) when is_binary(key) do
    String.match?(key, ~r/[A-Z]/)
  end

  defp camel_case_source_key?(_), do: false

  defp string_to_existing_atom!(str) do
    String.to_existing_atom(str)
  end

  defp safe_string_to_existing_atom(str) when is_binary(str) do
    try do
      String.to_existing_atom(str)
    rescue
      ArgumentError -> nil
    end
  end

  def validate_backend(value) when is_atom(value) or is_nil(value), do: {:ok, value}
  def validate_backend(_value), do: {:error, "expected a module, atom, or nil"}

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

  defp ensure_non_empty_fields!(opts) do
    case Keyword.fetch!(opts, :fields) do
      [] ->
        raise ArgumentError, "fields must contain at least one field"

      _fields ->
        Enum.into(opts, %{})
    end
  end

  defp validate_filterable_fields!(opts, filterable) do
    filter =
      opts
      |> Keyword.get(:filter, [])
      |> Enum.map(&validate_filter_entry!(&1, filterable))

    Keyword.put(opts, :filter, filter)
  end

  defp validate_sortable_fields!(opts, sortable) do
    sort =
      opts
      |> Keyword.get(:sort, [])
      |> Enum.map(&validate_sort_entry!(&1, sortable))

    Keyword.put(opts, :sort, sort)
  end

  defp validate_filter_entry!({operator, _value}, _filterable)
       when operator in [:or, :and, :not] do
    raise ArgumentError, "boolean composition is not supported in common search filters"
  end

  defp validate_filter_entry!({field, value}, filterable) do
    unless MapSet.member?(filterable, field) do
      raise ArgumentError, "filter field #{inspect(field)} is not declared as filterable"
    end

    {field, validate_filter_value!(field, value)}
  end

  defp validate_filter_value!(_field, value) when is_list(value) do
    unless Keyword.keyword?(value) do
      raise ArgumentError, "range filter operators must be a keyword list"
    end

    allowed = [:eq, :gt, :gte, :lt, :lte]

    Enum.each(value, fn {operator, _operand} ->
      unless operator in allowed do
        raise ArgumentError, "unsupported filter operator #{inspect(operator)}"
      end
    end)

    value
  end

  defp validate_filter_value!(_field, value), do: value

  defp validate_sort_entry!({direction, field}, sortable) when direction in [:asc, :desc] do
    unless MapSet.member?(sortable, field) do
      raise ArgumentError, "sort field #{inspect(field)} is not declared as sortable"
    end

    {direction, field}
  end

  defp validate_sort_entry!({direction, _field}, _sortable) do
    raise ArgumentError, "sort direction must be :asc or :desc, got #{inspect(direction)}"
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

  defp runtime_option_keys do
    Keyword.keys(@runtime_options)
  end
end
