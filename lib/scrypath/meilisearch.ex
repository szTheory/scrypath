defmodule Scrypath.Meilisearch do
  @moduledoc """
  Meilisearch-specific runtime entrypoints for Scrypath.

  `Scrypath.*` remains the common path for sync and the stable search happy path.
  This namespace is the explicit escape hatch for Meilisearch-native behavior that
  should stay visible instead of being tunneled through generic options.

  Use `Scrypath.search/3` for text plus validated `filter:`, `sort:`, `page:`,
  and optional explicit hydration through `repo:`. Use `Scrypath.Meilisearch.search/3`
  when you need native Meilisearch payloads that do not belong on the common path.
  """

  @behaviour Scrypath.Backend

  alias Scrypath.Document
  alias Scrypath.Meilisearch.Client
  alias Scrypath.Meilisearch.IndexManagement
  alias Scrypath.Meilisearch.Operations
  alias Scrypath.Meilisearch.Settings
  alias Scrypath.Query

  @impl true
  def name, do: :meilisearch

  @impl true
  def index_name(schema_module, config) do
    prefix =
      Keyword.get(config, :index_prefix) ||
        Scrypath.schema_config(schema_module).index_prefix ||
        "scrypath"

    schema_name = schema_module |> Module.split() |> List.last() |> Macro.underscore()

    "#{prefix}_#{schema_name}"
  end

  @impl true
  @spec upsert_documents(module(), [Document.t()], keyword()) :: {:ok, map()} | {:error, term()}
  def upsert_documents(schema_module, documents, config) when is_list(documents) do
    with {:ok, result} <- Operations.upsert_documents(schema_module, documents, config) do
      {:ok, Operations.to_public_result(result)}
    end
  end

  @impl true
  def delete_documents(schema_module, document_ids, config) when is_list(document_ids) do
    with {:ok, result} <- Operations.delete_documents(schema_module, document_ids, config) do
      {:ok, Operations.to_public_result(result)}
    end
  end

  @impl true
  @doc """
  Run a native Meilisearch search request against either the live index or an
  explicit target/index override.
  """
  @spec search(module(), Query.t() | map() | String.t(), keyword()) ::
          {:ok, map()} | {:error, term()}
  def search(schema_module, query, config) do
    index =
      Keyword.get(config, :index_name) ||
        Keyword.get(config, :target_index) ||
        index_name(schema_module, config)

    client(config).search(index, query, config)
  end

  @spec apply_settings(module(), String.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def apply_settings(schema_module, index_name, config \\ []) do
    Settings.apply(schema_module, index_name, config)
  end

  @spec create_index(module(), String.t() | atom() | nil, keyword()) ::
          {:ok, map()} | {:error, term()}
  def create_index(schema_module, primary_key, config \\ []) do
    IndexManagement.create_index(schema_module, primary_key, config)
  end

  @spec swap_indexes(module(), keyword()) :: {:ok, map()} | {:error, term()}
  def swap_indexes(schema_module, config \\ []) do
    IndexManagement.swap_indexes(schema_module, config)
  end

  defp client(config) do
    Keyword.get(config, :meilisearch_client) || Client
  end

  @doc false
  def normalize_task(response, stage \\ :initial)

  def normalize_task(response, stage) when is_map(response) and stage in [:initial, :poll] do
    task_uid = extract_task_uid(response)
    {status, status_problem} = normalize_task_status(response["status"] || response[:status])

    problems =
      []
      |> maybe_problem(:uid, uid_problem(task_uid))
      |> maybe_problem(:status, status_problem)

    if problems == [] do
      {:ok,
       %{
         uid: task_uid,
         status: status,
         type: response["type"] || response[:type],
         index_uid: response["indexUid"] || response[:indexUid],
         raw: response
       }}
    else
      {:error,
       {:invalid_task_payload,
        invalid_task_payload(stage, task_uid, problems, response)}}
    end
  end

  def normalize_task(response, stage) when stage in [:initial, :poll] do
    {:error,
     {:invalid_task_payload,
      invalid_task_payload(stage, nil, [payload: :not_a_map], %{raw: response})}}
  end

  defp extract_task_uid(response) do
    case response["taskUid"] || response[:taskUid] || response["uid"] || response[:uid] do
      task_uid when is_integer(task_uid) -> task_uid
      _other -> nil
    end
  end

  defp uid_problem(nil), do: :missing_or_invalid
  defp uid_problem(_task_uid), do: nil

  defp normalize_task_status(status) when is_atom(status) do
    normalize_task_status(Atom.to_string(status))
  end

  defp normalize_task_status("enqueued"), do: {:enqueued, nil}
  defp normalize_task_status("processing"), do: {:processing, nil}
  defp normalize_task_status("queued"), do: {:enqueued, nil}
  defp normalize_task_status("succeeded"), do: {:succeeded, nil}
  defp normalize_task_status("failed"), do: {:failed, nil}
  defp normalize_task_status("canceled"), do: {:cancelled, nil}
  defp normalize_task_status("cancelled"), do: {:cancelled, nil}
  defp normalize_task_status(nil), do: {nil, :missing}
  defp normalize_task_status(_status), do: {nil, :unknown}

  defp invalid_task_payload(:initial, task_uid, problems, payload) do
    %{stage: :initial, task_uid: task_uid, problems: problems, payload: payload}
  end

  defp invalid_task_payload(:poll, task_uid, problems, payload) do
    %{stage: :poll, task_uid: task_uid, problems: problems, payload: payload}
  end

  defp maybe_problem(problems, _key, nil), do: problems
  defp maybe_problem(problems, key, value), do: Keyword.put(problems, key, value)
end
