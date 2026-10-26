if Code.ensure_loaded?(Oban.Worker) and Code.ensure_loaded?(Oban.Job) do
  defmodule Scrypath.TestSupport.ObanTelemetryScenarios do
    @moduledoc false

    # Fixtures and runnable scenarios for the Oban worker telemetry spans. Shared by the
    # worker telemetry tests and the telemetry guide contract test, so keep names stable.

    alias Scrypath.TestSupport.FakeRepo

    @index "tenant_queryable_post"

    defmodule RecordingBackend do
      @moduledoc false
      @behaviour Scrypath.Backend

      @impl true
      def name, do: :recording

      @impl true
      def index_name(_schema_module, config), do: Keyword.get(config, :index_name, "recording")

      @impl true
      def upsert_documents(schema_module, documents, config) do
        send(self(), {:upsert_documents, schema_module, documents, config})
        {:ok, %{document_ids: Enum.map(documents, & &1.id)}}
      end

      @impl true
      def delete_documents(schema_module, document_ids, config) do
        send(self(), {:delete_documents, schema_module, document_ids, config})
        {:ok, %{document_ids: document_ids}}
      end

      @impl true
      def search(_schema_module, _query, _config), do: {:ok, %{hits: []}}

      @impl true
      def search_facet_values(_schema, _facet, _query, _opts, _config),
        do: {:error, :not_implemented}
    end

    @spec worker_event_names() :: [[atom()]]
    def worker_event_names do
      for(
        kind <- [:upsert, :delete],
        suffix <- [:start, :stop, :exception],
        do: [:scrypath, :oban, kind, suffix]
      ) ++ [[:scrypath, :oban, :upsert, :missing_removed]]
    end

    # %Oban.Job{} defaults attempt to 0; a performed job always has attempt >= 1.
    @spec job(map(), keyword()) :: Oban.Job.t()
    def job(args, opts \\ []) do
      %Oban.Job{
        args: args,
        attempt: Keyword.get(opts, :attempt, 1),
        max_attempts: Keyword.get(opts, :max_attempts, 8)
      }
    end

    @spec upsert_args(module(), module(), list(), map()) :: map()
    def upsert_args(schema, backend, ids, extra \\ %{}) do
      Map.merge(
        %{
          "schema" => to_string(schema),
          "backend" => to_string(backend),
          "index" => @index,
          "sync_mode" => "oban",
          "document_count" => length(ids),
          "document_ids" => ids,
          "repo" => to_string(FakeRepo)
        },
        extra
      )
    end

    @spec delete_args(module(), module(), list()) :: map()
    def delete_args(schema, backend, ids) do
      %{
        "schema" => to_string(schema),
        "backend" => to_string(backend),
        "index" => @index,
        "sync_mode" => "oban",
        "document_count" => length(ids),
        "document_ids" => ids
      }
    end
  end
end
