# test_helper.exs requires support files alphabetically; load the capture helper first so
# run/1 compiles against it. require_file loads a file once, so the later pass skips it.
Code.require_file("telemetry_capture.ex", __DIR__)

if Code.ensure_loaded?(Oban.Worker) and Code.ensure_loaded?(Oban.Job) do
  defmodule Scrypath.TestSupport.ObanTelemetryScenarios do
    @moduledoc false

    # Fixtures and runnable scenarios for the Oban worker telemetry spans. Shared by the
    # worker telemetry tests and the telemetry guide contract test, so keep names stable.

    alias Scrypath.Oban.DeleteWorker
    alias Scrypath.Oban.UpsertWorker
    alias Scrypath.TestSupport.FakeRepo
    alias Scrypath.TestSupport.TelemetryCapture

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

    defmodule TransientBackend do
      @moduledoc false
      @behaviour Scrypath.Backend

      @impl true
      def name, do: :transient

      @impl true
      def index_name(_schema_module, config), do: Keyword.get(config, :index_name, "transient")

      @impl true
      def upsert_documents(_schema_module, _documents, _config), do: {:error, :timeout}

      @impl true
      def delete_documents(_schema_module, _document_ids, _config), do: {:error, :timeout}

      @impl true
      def search(_schema_module, _query, _config), do: {:ok, %{hits: []}}

      @impl true
      def search_facet_values(_schema, _facet, _query, _opts, _config),
        do: {:error, :not_implemented}
    end

    defmodule RaisingBackend do
      @moduledoc false
      @behaviour Scrypath.Backend

      @impl true
      def name, do: :raising

      @impl true
      def index_name(_schema_module, config), do: Keyword.get(config, :index_name, "raising")

      @impl true
      def upsert_documents(_schema_module, _documents, _config),
        do: raise(RuntimeError, "backend exploded")

      @impl true
      def delete_documents(_schema_module, _document_ids, _config),
        do: raise(RuntimeError, "backend exploded")

      @impl true
      def search(_schema_module, _query, _config), do: {:ok, %{hits: []}}

      @impl true
      def search_facet_values(_schema, _facet, _query, _opts, _config),
        do: {:error, :not_implemented}
    end

    # Names its index the way Scrypath.Meilisearch.Naming does: rebuilt from the schema,
    # ignoring the :index_name the worker sets from the job. Stands for a prefix that
    # changed between enqueue and run.
    defmodule RebuiltNameBackend do
      @moduledoc false
      @behaviour Scrypath.Backend

      @impl true
      def name, do: :rebuilt_name

      @impl true
      def index_name(_schema_module, _config), do: "renamed_prefix_post"

      @impl true
      def upsert_documents(_schema_module, documents, _config),
        do: {:ok, %{document_ids: Enum.map(documents, & &1.id)}}

      @impl true
      def delete_documents(_schema_module, document_ids, _config),
        do: {:ok, %{document_ids: document_ids}}

      @impl true
      def search(_schema_module, _query, _config), do: {:ok, %{hits: []}}

      @impl true
      def search_facet_values(_schema, _facet, _query, _opts, _config),
        do: {:error, :not_implemented}
    end

    # Fails the second delete_documents call in this process, so a two-chunk delete halts
    # after the first chunk. Call reset/0 before each use.
    defmodule SecondDeleteFailsBackend do
      @moduledoc false
      @behaviour Scrypath.Backend

      @calls {__MODULE__, :delete_calls}

      def reset, do: Process.delete(@calls)

      @impl true
      def name, do: :second_delete_fails

      @impl true
      def index_name(_schema_module, config), do: Keyword.get(config, :index_name, "flaky")

      @impl true
      def upsert_documents(_schema_module, documents, _config),
        do: {:ok, %{document_ids: Enum.map(documents, & &1.id)}}

      @impl true
      def delete_documents(schema_module, document_ids, config) do
        calls = Process.get(@calls, 0) + 1
        Process.put(@calls, calls)
        send(self(), {:delete_documents, schema_module, document_ids, config})

        if calls == 2,
          do: {:error, {:timeout, :second_chunk}},
          else: {:ok, %{document_ids: document_ids}}
      end

      @impl true
      def search(_schema_module, _query, _config), do: {:ok, %{hits: []}}

      @impl true
      def search_facet_values(_schema, _facet, _query, _opts, _config),
        do: {:error, :not_implemented}
    end

    # Loads every id except 404, which stands for a record deleted since enqueue.
    defmodule LoaderPost do
      @moduledoc false
      use Ecto.Schema
      use Scrypath, fields: [:title]

      schema "loader_posts" do
        field(:title, :string)
      end

      def search_records(ids, _context) do
        Enum.map(ids -- [404], &%__MODULE__{id: &1, title: "Loaded #{&1}"})
      end
    end

    # Every record is gone.
    defmodule GoneLoaderPost do
      @moduledoc false
      use Ecto.Schema
      use Scrypath, fields: [:title]

      schema "gone_loader_posts" do
        field(:title, :string)
      end

      def search_records(_ids, _context), do: []
    end

    # An app bug: search_records/2 returns something other than a list.
    defmodule BrokenLoaderPost do
      @moduledoc false
      use Ecto.Schema
      use Scrypath, fields: [:title]

      schema "broken_loader_posts" do
        field(:title, :string)
      end

      def search_records(ids, _context), do: {:ok, Enum.map(ids, &%__MODULE__{id: &1})}
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

    # A job queued before 0.3.16: no repo, so the worker writes its document snapshot.
    @spec legacy_args() :: map()
    def legacy_args do
      snapshot = %{
        "documents" => [%{"id" => 1, "data" => %{"title" => "Queued"}, "source" => "fields"}]
      }

      QueryablePost
      |> upsert_args(RecordingBackend, [1], snapshot)
      |> Map.delete("repo")
    end

    @scenarios [
      :upsert_ok,
      :upsert_legacy,
      :upsert_error,
      :upsert_cancel,
      :upsert_raise,
      :upsert_missing,
      :upsert_missing_many,
      :upsert_missing_chunk_fail,
      :delete_ok,
      :delete_error,
      :delete_raise,
      :decode_failure
    ]

    @spec scenarios() :: [atom()]
    def scenarios, do: @scenarios

    @doc """
    Performs one scenario with a capture attached to worker_event_names/0 and returns
    `{result, events}`. A raising worker yields `{{:raised, exception}, events}`.
    """
    @spec run(atom()) :: {term(), [map()]}
    def run(scenario) do
      capture = TelemetryCapture.attach(worker_event_names())

      result =
        try do
          perform(scenario)
        rescue
          exception -> {:raised, exception}
        end

      events = TelemetryCapture.collect(capture)
      TelemetryCapture.detach(capture)
      {result, events}
    end

    defp perform(:upsert_ok),
      do: UpsertWorker.perform(job(upsert_args(LoaderPost, RecordingBackend, [1, 2])))

    defp perform(:upsert_legacy), do: UpsertWorker.perform(job(legacy_args()))

    defp perform(:upsert_error),
      do: UpsertWorker.perform(job(upsert_args(LoaderPost, TransientBackend, [1])))

    defp perform(:upsert_cancel),
      do: UpsertWorker.perform(job(upsert_args(BrokenLoaderPost, RecordingBackend, [1])))

    defp perform(:upsert_raise),
      do: UpsertWorker.perform(job(upsert_args(LoaderPost, RaisingBackend, [1])))

    defp perform(:upsert_missing) do
      args = upsert_args(LoaderPost, RecordingBackend, [1, 404])
      UpsertWorker.perform(job(args, attempt: 2))
    end

    defp perform(:upsert_missing_many) do
      args = upsert_args(GoneLoaderPost, RecordingBackend, Enum.to_list(1..1500))
      UpsertWorker.perform(job(args))
    end

    defp perform(:upsert_missing_chunk_fail) do
      SecondDeleteFailsBackend.reset()
      args = upsert_args(GoneLoaderPost, SecondDeleteFailsBackend, Enum.to_list(1..1500))
      UpsertWorker.perform(job(args))
    end

    defp perform(:delete_ok),
      do: DeleteWorker.perform(job(delete_args(QueryablePost, RecordingBackend, [1, 2])))

    defp perform(:delete_error),
      do: DeleteWorker.perform(job(delete_args(QueryablePost, TransientBackend, [1])))

    defp perform(:delete_raise),
      do: DeleteWorker.perform(job(delete_args(QueryablePost, RaisingBackend, [1])))

    defp perform(:decode_failure) do
      args = upsert_args(LoaderPost, RecordingBackend, [1], %{"schema" => "MissingSchema"})
      UpsertWorker.perform(job(args))
    end
  end
end
