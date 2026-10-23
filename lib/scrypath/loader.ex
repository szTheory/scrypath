defmodule Scrypath.Loader do
  @moduledoc """
  Loads the current source records for search document ids.

  Oban sync jobs carry document ids, not document data. When a job runs, it
  loads the records as they are now, so a retried or delayed job never sends
  an older copy over newer index data.

  By default the loader queries the schema by its `document_id` field with the
  configured `:repo`, then applies the schema's declared `preload:`:

      use Scrypath,
        fields: [:name, :category_name],
        preload: [:category]

  A schema that needs full control, for example tenant-scoped repos, soft
  deletes, or document ids that are not a column, defines `search_records/2`.
  It receives the document ids and a context map with `:repo`, and returns the
  records that still exist and should be searchable:

      def search_records(ids, %{repo: repo}) do
        from(p in __MODULE__, where: p.id in ^ids, preload: :category)
        |> repo.all(skip_tenant_id: true)
      end

  Ids with no returned record are removed from the index.
  """

  import Ecto.Query, only: [from: 2]

  alias Scrypath.Identity
  alias Scrypath.Schema.Metadata

  @doc "Whether the schema defines its own `search_records/2` loader."
  @spec custom_loader?(module()) :: boolean()
  def custom_loader?(schema_module) do
    Code.ensure_loaded?(schema_module) and function_exported?(schema_module, :search_records, 2)
  end

  @doc """
  Checks that records for `schema_module` can be loaded by document id.

  Returns `{:error, :search_records_required}` for schemas with custom document
  ids and no `search_records/2`, and `{:error, :repo_required}` when no `:repo`
  is configured.
  """
  @spec check_loadable(module(), keyword()) :: :ok | {:error, atom()}
  def check_loadable(schema_module, config) do
    cond do
      custom_loader?(schema_module) -> :ok
      Identity.supports_custom_document_id?(schema_module) -> {:error, :search_records_required}
      is_nil(Keyword.get(config, :repo)) -> {:error, :repo_required}
      true -> :ok
    end
  end

  @doc """
  Raises when records for `schema_module` cannot be loaded by document id.

  Called before an Oban job is queued so a missing repo or an unmappable custom
  document id fails at the call site instead of inside the worker.
  """
  @spec ensure_loadable!(module(), keyword()) :: :ok
  def ensure_loadable!(schema_module, config) do
    case check_loadable(schema_module, config) do
      :ok ->
        :ok

      {:error, :search_records_required} ->
        raise ArgumentError,
              "#{inspect(schema_module)} defines search_document_id/1, so Oban sync cannot " <>
                "load its records by document id. Define search_records/2 on the schema."

      {:error, :repo_required} ->
        raise ArgumentError,
              "Oban sync for #{inspect(schema_module)} needs :repo to load current records " <>
                "when the job runs. Pass repo: MyApp.Repo or define search_records/2 on the schema."
    end
  end

  @doc """
  Returns `{:ok, records, missing_ids}` for the given document ids.

  `missing_ids` keeps the caller's id values for documents whose records no
  longer exist.
  """
  @spec load(module(), [term()], keyword()) :: {:ok, [struct()], [term()]} | {:error, term()}
  def load(schema_module, document_ids, config) when is_list(document_ids) do
    with {:ok, records} <- fetch(schema_module, document_ids, config) do
      found = MapSet.new(Identity.document_ids(schema_module, records), &to_string/1)
      missing = Enum.reject(document_ids, &MapSet.member?(found, to_string(&1)))
      {:ok, records, missing}
    end
  end

  defp fetch(_schema_module, [], _config), do: {:ok, []}

  defp fetch(schema_module, document_ids, config) do
    repo = Keyword.get(config, :repo)

    if custom_loader?(schema_module) do
      case schema_module.search_records(document_ids, %{repo: repo}) do
        records when is_list(records) -> {:ok, records}
        other -> {:error, {:invalid_search_records, other}}
      end
    else
      with :ok <- check_loadable(schema_module, config) do
        id_field = Metadata.document_id(schema_module)

        records =
          from(record in schema_module, where: field(record, ^id_field) in ^document_ids)
          |> repo.all()

        {:ok, preload_records(repo, records, Metadata.preload(schema_module))}
      end
    end
  end

  defp preload_records(_repo, records, preload) when preload in [nil, []], do: records
  defp preload_records(_repo, [], _preload), do: []
  defp preload_records(repo, records, preload), do: repo.preload(records, preload)
end
