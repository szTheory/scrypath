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
end
