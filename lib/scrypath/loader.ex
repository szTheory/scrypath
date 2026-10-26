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

  Ids are deduped and loaded in batches of at most 1000, so `search_records/2`
  and the default query never see more than 1000 ids per call. There is no
  ordering contract for the ids a batch receives.
  """

  import Ecto.Query, only: [from: 2]

  alias Scrypath.Chunks
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
  longer exist. Ids are deduped and loaded in batches of at most 1000; the
  first failing batch stops the load and its error is returned.

  The default query first casts ids to the Ecto type of the schema's
  `document_id` field and checks that the repo's adapter can dump them, and
  returns `{:error, {:invalid_arg, "document_ids"}}` when one fails, for example
  `"abc"` for an integer key or for a `:binary_id` key on Postgres.
  """
  @spec load(module(), [term()], keyword()) :: {:ok, [struct()], [term()]} | {:error, term()}
  def load(schema_module, document_ids, config) when is_list(document_ids) do
    with {:ok, records} <- fetch_chunks(schema_module, document_ids, config) do
      found = MapSet.new(Identity.document_ids(schema_module, records), &to_string/1)
      missing = Enum.reject(document_ids, &MapSet.member?(found, to_string(&1)))
      {:ok, records, missing}
    end
  end

  # Prepares rows backfill already selected for projection, through the same
  # loader rules Oban sync uses. Returns `{:ok, records, omitted_ids}`.
  #
  # With `search_records/2`, the loader decides which batch rows are still
  # searchable; records it returns for ids outside the batch are dropped so a
  # caller's scope can never leak into the index. Without it, rows are kept and
  # the schema's `preload:` is applied.
  @doc false
  @spec prepare_records(module(), [struct()], keyword()) ::
          {:ok, [struct()], [term()]} | {:error, term()}
  def prepare_records(_schema_module, [], _config), do: {:ok, [], []}

  def prepare_records(schema_module, rows, config) when is_list(rows) do
    if custom_loader?(schema_module) do
      ids = Identity.document_ids(schema_module, rows)
      batch = MapSet.new(ids, &to_string/1)

      with {:ok, records, omitted} <- load(schema_module, ids, config) do
        in_batch =
          Enum.filter(records, fn record ->
            MapSet.member?(batch, to_string(Identity.document_id(schema_module, record)))
          end)

        {:ok, in_batch, omitted}
      end
    else
      repo = Keyword.fetch!(config, :repo)
      {:ok, preload_records(repo, rows, preload_for(schema_module)), []}
    end
  end

  defp fetch_chunks(schema_module, document_ids, config) do
    document_ids
    |> Chunks.ids()
    |> Chunks.reduce_ok(&fetch(schema_module, &1, config))
    |> case do
      {:ok, chunk_records} -> {:ok, Enum.concat(chunk_records)}
      {:error, _reason} = error -> error
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
      id_field = Metadata.document_id(schema_module)

      with :ok <- check_loadable(schema_module, config),
           {:ok, query_ids} <- cast_ids(schema_module, id_field, document_ids, repo) do
        records =
          from(record in schema_module, where: field(record, ^id_field) in ^query_ids)
          |> repo.all()

        {:ok, preload_records(repo, records, preload_for(schema_module))}
      end
    end
  end

  # Casts ids the way the Ecto planner binds them: Ecto.Type.cast/2 to the type of the
  # field the default query filters on (the schema's primary key unless it declares
  # another document id), then a dump through the repo's adapter. Both steps matter:
  # "abc" casts to :binary_id but the Postgres adapter cannot dump it as a UUID. An id
  # that fails either step would make the query raise Ecto.Query.CastError on every
  # retry, so it is reported as invalid input instead. Schemas whose records load
  # through search_records/2 never reach this, a field with no Ecto type is left as is,
  # and a repo without an adapter skips the dump step.
  defp cast_ids(schema_module, id_field, document_ids, repo) do
    case ecto_type(schema_module, id_field) do
      nil ->
        {:ok, document_ids}

      type ->
        adapter = repo_adapter(repo)

        Enum.reduce_while(document_ids, {:ok, []}, fn id, {:ok, acc} ->
          case cast_id(type, adapter, id) do
            {:ok, cast} -> {:cont, {:ok, [cast | acc]}}
            :error -> {:halt, {:error, {:invalid_arg, "document_ids"}}}
          end
        end)
        |> case do
          {:ok, cast} -> {:ok, Enum.reverse(cast)}
          {:error, _tag} = error -> error
        end
    end
  end

  defp cast_id(type, adapter, id) do
    with {:ok, cast} <- Ecto.Type.cast(type, id),
         :ok <- dump_id(type, adapter, cast) do
      {:ok, cast}
    else
      _error -> :error
    end
  end

  defp dump_id(_type, nil, _cast), do: :ok

  defp dump_id(type, adapter, cast) do
    case Ecto.Type.adapter_dump(adapter, type, cast) do
      {:ok, _dumped} -> :ok
      :error -> :error
    end
  end

  defp repo_adapter(repo) do
    with true <- is_atom(repo) and Code.ensure_loaded?(repo),
         true <- function_exported?(repo, :__adapter__, 0),
         adapter when is_atom(adapter) <- repo.__adapter__(),
         true <- Code.ensure_loaded?(adapter) and function_exported?(adapter, :dumpers, 2) do
      adapter
    else
      _other -> nil
    end
  end

  defp ecto_type(schema_module, id_field) do
    if function_exported?(schema_module, :__schema__, 2),
      do: schema_module.__schema__(:type, id_field),
      else: nil
  end

  # Hand-written owner-only fan-out schemas define only :fan_outs and :document_id,
  # so a schema that does not answer :preload has nothing to preload.
  defp preload_for(schema_module) do
    Metadata.preload(schema_module)
  rescue
    error in FunctionClauseError ->
      if error.module == schema_module and error.function == :__scrypath__,
        do: [],
        else: reraise(error, __STACKTRACE__)
  end

  defp preload_records(_repo, records, preload) when preload in [nil, []], do: records
  defp preload_records(_repo, [], _preload), do: []
  # force: true so rows that arrive with an association already loaded (for
  # example from a caller query) are reloaded the same way on every path.
  defp preload_records(repo, records, preload),
    do: repo.preload(records, preload, force: true)
end
