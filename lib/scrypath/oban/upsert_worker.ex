if Code.ensure_loaded?(Oban.Worker) and Code.ensure_loaded?(Oban.Job) do
  defmodule Scrypath.Oban.UpsertWorker do
    @moduledoc false

    use Oban.Worker, queue: :scrypath, max_attempts: 8

    alias Scrypath.Chunks
    alias Scrypath.Document
    alias Scrypath.Loader
    alias Scrypath.Oban.IndexingAck
    alias Scrypath.Oban.JobArgs
    alias Scrypath.Projection
    alias Scrypath.Telemetry

    @impl Oban.Worker
    def perform(%Oban.Job{args: args} = oban_job) do
      with {:ok, job} <- JobArgs.decode_upsert(args),
           {:ok, config} <-
             JobArgs.resolve_config([backend: job.backend, sync_mode: :manual] ++ job.opts) do
        config = Keyword.put(config, :index_name, job.index)
        metadata = start_metadata(job, config, oban_job)

        # The span starts only once decode and config succeeded, so every tag is known.
        # The stop map never carries document_count, so the start count stands.
        Telemetry.span([:scrypath, :oban, :upsert], metadata, fn ->
          {result, facts} = sync(job, args, config, metadata)
          {result, Map.merge(Telemetry.job_stop_metadata(result), facts)}
        end)
      else
        {:error, tag} -> {:cancel, {:invalid_job, tag}}
      end
    end

    # sync_mode: :oban overrides the :manual the config resolves with: extra merges last.
    # index is the one the job writes to (job.index, set as :index_name above). A backend's
    # index_name/2 may rebuild the name from the current prefix config instead, which
    # differs from the queued name after a deploy that changes the prefix.
    defp start_metadata(job, config, %Oban.Job{} = oban_job) do
      Telemetry.common_metadata(job.schema, config,
        sync_mode: :oban,
        attempt: oban_job.attempt,
        max_attempts: oban_job.max_attempts,
        document_count: Chunks.distinct_count(job.document_ids),
        index: job.index
      )
    end

    # Returns {result, facts}: facts are the upsert-only stop keys, present only when a
    # load or legacy snapshot produced a plan. Counts describe the plan; the outcome in
    # the stop metadata says whether it was carried out.
    defp sync(
           %{backend: backend, schema: schema_module, document_ids: document_ids},
           args,
           config,
           metadata
         ) do
      # Load the records as they are now; a retried or delayed job must never
      # send an older copy over newer index data.
      case Loader.load(schema_module, document_ids, config) do
        {:ok, records, missing_ids} ->
          documents = Enum.map(records, &Projection.document(schema_module, &1))

          facts = %{
            source: :loaded,
            upserted_count: upserted_count(documents),
            missing_count: Chunks.distinct_count(missing_ids)
          }

          # missing_removed fires only after every delete chunk succeeded, so a retry that
          # reloads records never counts the same removal twice.
          result =
            with :ok <- write(backend, :upsert_documents, schema_module, documents, config),
                 :ok <- write(backend, :delete_documents, schema_module, missing_ids, config) do
              emit_missing_removed(missing_ids, metadata)
            end

          {result, facts}

        {:error, reason} when reason in [:repo_required, :search_records_required] ->
          # Jobs enqueued before 0.3.16 carry a document snapshot. When this app can't
          # load records, write that snapshot as those versions did rather than drop it.
          case legacy_snapshot(args, document_ids) do
            {:ok, documents} ->
              result = write(backend, :upsert_documents, schema_module, documents, config)

              {result,
               %{
                 source: :legacy_snapshot,
                 upserted_count: upserted_count(documents),
                 missing_count: 0
               }}

            :error ->
              {{:cancel, {:invalid_job, reason}}, %{}}
          end

        # search_records/2 returned something other than a list: an app bug that no retry
        # fixes. The tag names the problem without the returned value.
        {:error, {:invalid_search_records, _returned}} ->
          {{:cancel, {:invalid_job, :invalid_search_records}}, %{}}

        # An id the key's Ecto type cannot cast ("abc" for an integer key): no retry fixes it.
        {:error, {:invalid_arg, _key} = tag} ->
          {{:cancel, {:invalid_job, tag}}, %{}}

        {:error, reason} ->
          {{:error, reason}, %{}}
      end
    end

    # Counts what write/5 sends: Chunks.by_id/2 keeps one document per id, so duplicate
    # rows from a custom search_records/2 are counted once, like document_count.
    defp upserted_count(documents), do: documents |> Enum.map(& &1.id) |> Chunks.distinct_count()

    defp emit_missing_removed(missing_ids, metadata) do
      case Chunks.distinct_count(missing_ids) do
        0 ->
          :ok

        count ->
          :telemetry.execute(
            [:scrypath, :oban, :upsert, :missing_removed],
            %{count: count},
            metadata
          )
      end
    end

    # Sends at most Chunks.max_ids/0 entries per backend call and waits for each chunk's
    # task before the next; the first failure stops the job so Oban retries it.
    defp write(_backend, _fun, _schema_module, [], _config), do: :ok

    defp write(backend, fun, schema_module, entries, config) do
      entries
      |> chunk(fun)
      |> Chunks.each_ok(fn chunk ->
        IndexingAck.await(backend, apply(backend, fun, [schema_module, chunk, config]), config)
      end)
    end

    defp chunk(documents, :upsert_documents), do: Chunks.by_id(documents, & &1.id)
    defp chunk(document_ids, :delete_documents), do: Chunks.ids(document_ids)

    defp legacy_snapshot(%{"documents" => documents} = args, document_ids)
         when is_list(documents) do
      with {:ok, normalized} <- normalize_documents(documents),
           true <- args["document_count"] == length(normalized),
           true <- Enum.map(normalized, & &1.id) == document_ids do
        {:ok, normalized}
      else
        _ -> :error
      end
    end

    defp legacy_snapshot(_args, _document_ids), do: :error

    defp normalize_documents(documents) do
      Enum.reduce_while(documents, {:ok, []}, fn
        %{"id" => id, "data" => data, "source" => source}, {:ok, acc}
        when is_map(data) and source in ["fields", "custom"] ->
          document = %Document{id: id, data: data, source: String.to_existing_atom(source)}
          {:cont, {:ok, [document | acc]}}

        _document, _acc ->
          {:halt, :error}
      end)
      |> case do
        {:ok, documents} -> {:ok, Enum.reverse(documents)}
        :error -> :error
      end
    end
  end
end
