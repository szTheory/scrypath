defmodule Scrypath.Operator.RecoveryAction do
  @moduledoc """
  Explicit recovery action used by Scrypath operator APIs.

  Recovery actions are opt-in. They carry the stable references needed to route
  retries, backfills, or reindexes through existing Scrypath write paths rather
  than backend-native admin commands.
  """

  alias Scrypath.Document
  alias Scrypath.Backfill
  alias Scrypath.Oban.Enqueue
  alias Scrypath.Sync
  alias Scrypath.Reindex

  @enforce_keys [:schema, :backend, :mode, :operation]
  defstruct [:schema, :backend, :mode, :operation, :index, kind: :retry, reference: %{}]

  @type t :: %__MODULE__{
          schema: module(),
          backend: module(),
          mode: :inline | :manual | :oban | atom(),
          operation: :upsert | :delete | :unknown,
          kind: :retry | :backfill | :reindex,
          index: String.t() | nil,
          reference: map()
        }

  @spec new(keyword()) :: t()
  def new(attrs) when is_list(attrs), do: struct!(__MODULE__, attrs)

  @spec retry(t(), keyword()) :: {:ok, map()} | {:error, term()}

  def retry(%__MODULE__{kind: :backfill} = action, opts) do
    opts = Keyword.put_new(opts, :backend, action.backend)
    Backfill.backfill(action.schema, opts)
  end

  def retry(%__MODULE__{kind: :reindex} = action, opts) do
    opts = Keyword.put_new(opts, :backend, action.backend)
    Reindex.run(action.schema, opts)
  end

  def retry(%__MODULE__{mode: :oban} = action, opts) do
    config = oban_retry_config(action, opts)
    payload = Map.get(action.reference, :payload, %{})

    with :ok <- validate_oban_retry(action, config, payload) do
      case action.operation do
        :upsert ->
          documents = decode_documents(Map.get(payload, "documents", []))
          Enqueue.enqueue_upsert(action.schema, documents, config)

        :delete ->
          Enqueue.enqueue_delete(action.schema, Map.get(payload, "document_ids", []), config)

        _other ->
          {:error, :unsupported_operation}
      end
    end
  end

  def retry(%__MODULE__{mode: mode, operation: :delete} = action, opts)
      when mode in [:manual, :inline] do
    case Keyword.get(opts, :document_ids) do
      document_ids when is_list(document_ids) ->
        config = base_retry_config(opts, action, mode)
        Sync.delete_documents(action.schema, document_ids, config)

      _other ->
        {:error, {:missing_retry_input, :document_ids}}
    end
  end

  def retry(%__MODULE__{mode: mode, operation: :upsert} = action, opts)
      when mode in [:manual, :inline] do
    case Keyword.get(opts, :records) do
      records when is_list(records) ->
        config = base_retry_config(opts, action, mode)
        Sync.sync_records(action.schema, records, config)

      _other ->
        {:error, {:missing_retry_input, :records}}
    end
  end

  def retry(%__MODULE__{}, _opts), do: {:error, :unsupported_recovery_mode}

  defp validate_oban_retry(action, config, payload) do
    current_index = action.backend.index_name(action.schema, config)

    cond do
      Keyword.get(config, :backend) != action.backend ->
        {:error, :backend_mismatch}

      action.index && current_index != action.index ->
        {:error, :index_mismatch}

      action.operation == :upsert and not is_list(Map.get(payload, "documents")) ->
        {:error, {:missing_retry_input, :documents}}

      action.operation == :delete and not is_list(Map.get(payload, "document_ids")) ->
        {:error, {:missing_retry_input, :document_ids}}

      true ->
        :ok
    end
  end

  defp oban_retry_config(action, opts) do
    opts = base_retry_config(opts, action, :oban)

    case normalize_queue(Map.get(action.reference, :queue)) do
      nil -> opts
      queue -> Keyword.put_new(opts, :oban_queue, queue)
    end
  end

  defp base_retry_config(opts, action, sync_mode) do
    opts
    |> Keyword.put_new(:backend, action.backend)
    |> Keyword.put(:sync_mode, sync_mode)
  end

  defp normalize_queue(queue) when is_atom(queue), do: queue

  defp normalize_queue(queue) when is_binary(queue) do
    String.to_existing_atom(queue)
  rescue
    ArgumentError -> nil
  end

  defp normalize_queue(_queue), do: nil

  defp decode_documents(documents) when is_list(documents) do
    Enum.map(documents, fn
      %{"id" => id, "data" => data, "source" => source} ->
        %Document{id: id, data: data, source: normalize_source(source)}
    end)
  end

  defp normalize_source("fields"), do: :fields
  defp normalize_source("custom"), do: :custom
  defp normalize_source(source) when is_atom(source), do: source
end
