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

  @spec validate_schema_options!(keyword()) :: map()
  def validate_schema_options!(opts) do
    opts
    |> validate!(@schema_options)
    |> ensure_non_empty_fields!()
    |> Map.put(:document_source, :fields)
  end

  @spec validate_runtime_options!(keyword()) :: keyword()
  def validate_runtime_options!(opts) do
    validate!(opts, @runtime_options)
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

  def validate_backend(value) when is_atom(value) or is_nil(value), do: {:ok, value}
  def validate_backend(_value), do: {:error, "expected a module, atom, or nil"}

  def validate_optional_module(value) when is_atom(value) or is_nil(value), do: {:ok, value}
  def validate_optional_module(_value), do: {:error, "expected a module or nil"}

  def validate_keyword_list(value) when is_list(value) do
    if Keyword.keyword?(value), do: {:ok, value}, else: {:error, "expected a keyword list"}
  end

  def validate_keyword_list(_value), do: {:error, "expected a keyword list"}

  def validate_positive_integer(value) when is_integer(value) and value > 0, do: {:ok, value}
  def validate_positive_integer(_value), do: {:error, "expected a positive integer"}

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
