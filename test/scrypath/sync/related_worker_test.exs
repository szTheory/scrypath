defmodule Scrypath.Sync.RelatedWorkerTest do
  use ExUnit.Case, async: true

  alias Scrypath.Sync.RelatedWorker

  if Code.ensure_loaded?(Oban.Worker) do
    defmodule RecordingBackend do
      @behaviour Scrypath.Backend

      @impl true
      def name, do: :recording

      @impl true
      def index_name(_schema, _config), do: "dummy_index"

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

    defmodule DummyTarget do
      use Ecto.Schema

      schema "dummy_targets" do
        field(:title, :string)
      end

      def __scrypath__(:document_id), do: :id
      def __scrypath__(:fields), do: [:title]
      def __scrypath__(:custom_document), do: false
    end

    # Trigger rows the fixtures' search_records/2 can see. A test puts the rows that still
    # exist; a row with deleted_at set is soft-deleted and excluded like a deleted one.
    # With no rows put, every requested id loads.
    defmodule Rows do
      def put(schema, rows), do: Process.put({__MODULE__, schema}, rows)

      def load(schema, ids) do
        send(self(), {:search_records, schema, ids})

        case Process.get({__MODULE__, schema}) do
          nil ->
            Enum.map(ids, &struct(schema, id: &1))

          rows ->
            Enum.filter(rows, &(&1.id in ids and is_nil(Map.get(&1, :deleted_at))))
        end
      end
    end

    defmodule DummySchema do
      defstruct [:id, :deleted_at]

      def __scrypath__(:fan_outs) do
        [
          comments: [
            target: DummyTarget,
            resolver: {__MODULE__, :resolve_comments, [:extra_arg]}
          ]
        ]
      end

      def __scrypath__(:document_id) do
        :id
      end

      def search_records(ids, _context), do: Rows.load(__MODULE__, ids)

      def resolve_comments([%__MODULE__{} | _] = triggers, :extra_arg) do
        send(self(), {:resolved, __MODULE__, triggers})
        Enum.map(triggers, &%DummyTarget{id: &1.id, title: "Comment for #{&1.id}"})
      end
    end

    defmodule OrdinaryWorkerSource do
      use Ecto.Schema

      use Scrypath,
        fields: [:name],
        fan_outs: [
          comments: [
            target: DummyTarget,
            resolver: {__MODULE__, :resolve_comments, [:extra_arg]}
          ]
        ]

      @primary_key {:id, :id, autogenerate: true}
      schema "ordinary_worker_sources" do
        field(:name, :string)
      end

      def search_records(ids, _context), do: Rows.load(__MODULE__, ids)

      def resolve_comments([%__MODULE__{} | _] = triggers, :extra_arg) do
        send(self(), {:resolved, __MODULE__, triggers})

        Enum.map(
          triggers,
          &%DummyTarget{id: &1.id, title: "Ordinary worker comment #{&1.id}"}
        )
      end
    end

    @stop_event [:scrypath, :sync, :related, :resolve, :stop]

    setup do
      test_pid = self()
      handler_id = {__MODULE__, make_ref()}

      :ok =
        :telemetry.attach(
          handler_id,
          @stop_event,
          &__MODULE__.handle_stop/4,
          test_pid
        )

      on_exit(fn -> :telemetry.detach(handler_id) end)
      :ok
    end

    # perform/1 runs in the test process; ignore events emitted by other async tests.
    def handle_stop(_event, _measurements, metadata, test_pid) do
      if self() == test_pid, do: send(test_pid, {:related_stop, metadata})
    end

    defp dummy_args(ids, opts \\ %{}) do
      %{
        "schema" => to_string(DummySchema),
        "document_ids" => ids,
        "fan_out" => "comments",
        "opts" =>
          Map.merge(
            %{"backend" => to_string(RecordingBackend), "index_prefix" => "test"},
            opts
          )
      }
    end

    test "perform/1 loads trigger structs, runs the resolver with them and calls sync_records" do
      assert :ok = RelatedWorker.perform(%Oban.Job{args: dummy_args([1, 2])})

      assert_received {:search_records, DummySchema, [1, 2]}
      assert_received {:resolved, DummySchema, triggers}
      assert Enum.sort_by(triggers, & &1.id) == [%DummySchema{id: 1}, %DummySchema{id: 2}]

      assert_received {:upsert_documents, DummyTarget, documents, config}
      assert documents |> Enum.map(& &1.id) |> Enum.sort() == [1, 2]
      assert config[:backend] == RecordingBackend

      assert_received {:related_stop, %{missing_count: 0}}
    end

    test "perform/1 consumes generated fan_out metadata from use Scrypath schema" do
      args = %{
        "schema" => to_string(OrdinaryWorkerSource),
        "document_ids" => [4, 5],
        "fan_out" => "comments",
        "opts" => %{
          "backend" => to_string(RecordingBackend),
          "index_prefix" => "test"
        }
      }

      assert :ok = RelatedWorker.perform(%Oban.Job{args: args})

      assert_received {:resolved, OrdinaryWorkerSource, [%OrdinaryWorkerSource{} | _]}
      assert_received {:upsert_documents, DummyTarget, documents, _config}

      assert documents |> Enum.map(& &1.data[:title]) |> Enum.sort() == [
               "Ordinary worker comment 4",
               "Ordinary worker comment 5"
             ]
    end

    test "perform/1 passes only loaded triggers and reports missing_count for the rest" do
      Rows.put(DummySchema, [%DummySchema{id: 1}, %DummySchema{id: 2}])

      assert :ok = RelatedWorker.perform(%Oban.Job{args: dummy_args([1, 2, 3])})

      assert_received {:resolved, DummySchema, triggers}
      assert triggers |> Enum.map(& &1.id) |> Enum.sort() == [1, 2]
      assert_received {:related_stop, %{missing_count: 1}}
    end

    test "perform/1 skips a soft-deleted trigger excluded by search_records/2" do
      Rows.put(DummySchema, [
        %DummySchema{id: 1},
        %DummySchema{id: 2, deleted_at: ~U[2026-10-01 00:00:00Z]}
      ])

      assert :ok = RelatedWorker.perform(%Oban.Job{args: dummy_args([1, 2])})

      assert_received {:resolved, DummySchema, [%DummySchema{id: 1}]}
      assert_received {:related_stop, %{missing_count: 1}}
    end

    test "perform/1 finishes :ok without calling the resolver when every trigger is missing" do
      Rows.put(DummySchema, [%DummySchema{id: 9, deleted_at: ~U[2026-10-01 00:00:00Z]}])

      assert :ok = RelatedWorker.perform(%Oban.Job{args: dummy_args([7, 8, 9])})

      refute_received {:resolved, DummySchema, _}
      refute_received {:upsert_documents, _, _, _}

      assert_received {:related_stop, %{missing_count: 3, status: :noop, mode: :inline}}
    end

    test "perform/1 cancels job on an unknown schema" do
      args = %{dummy_args([1, 2]) | "schema" => "Elixir.NonExistentSchema"}

      assert {:cancel, {:invalid_job, {:unknown_schema, "Elixir.NonExistentSchema"}}} =
               RelatedWorker.perform(%Oban.Job{args: args})
    end

    test "perform/1 cancels job on an unknown fan_out" do
      args = %{dummy_args([1, 2]) | "fan_out" => "non_existent_fan_out"}

      assert {:cancel, {:invalid_job, {:unknown_fan_out, "non_existent_fan_out"}}} =
               RelatedWorker.perform(%Oban.Job{args: args})
    end

    describe "FAN-03: undecodable related args cancel and never raise" do
      @missing "Elixir.Scrypath.NoSuchModuleZq179"

      for {label, change, tag} <- [
            {"unknown schema", {:args, %{"schema" => @missing}}, {:unknown_schema, @missing}},
            {"unknown fan_out", {:args, %{"fan_out" => "no_such_fan_out_zq179"}},
             {:unknown_fan_out, "no_such_fan_out_zq179"}},
            {"unknown backend", {:opts, %{"backend" => @missing}}, {:unknown_backend, @missing}},
            {"unknown repo", {:opts, %{"repo" => @missing}}, {:unknown_repo, @missing}},
            {"unknown otp_app", {:opts, %{"otp_app" => "zz_not_an_app_zq179"}},
             {:unknown_otp_app, "zz_not_an_app_zq179"}},
            {"missing document_ids", {:drop, "document_ids"}, {:invalid_arg, "document_ids"}},
            {"missing opts", {:drop, "opts"}, {:invalid_arg, "opts"}}
          ] do
        test "#{label} cancels with its tag" do
          args =
            case unquote(Macro.escape(change)) do
              {:args, overrides} -> Map.merge(dummy_args([1]), overrides)
              {:opts, opts} -> dummy_args([1], opts)
              {:drop, key} -> Map.delete(dummy_args([1]), key)
            end

          result =
            try do
              RelatedWorker.perform(%Oban.Job{args: args})
            rescue
              error -> flunk("#{unquote(label)} raised #{inspect(error)}")
            end

          assert result == {:cancel, {:invalid_job, unquote(Macro.escape(tag))}}
          refute_received {:resolved, _, _}
        end
      end
    end

    test "a related job queued by 0.3.17, with nil-valued opts keys, still runs" do
      # Written exactly as 0.3.17's RelatedEnqueue.job_args/4 stored it (after JSON).
      args = %{
        "schema" => "Elixir.Scrypath.Sync.RelatedWorkerTest.DummySchema",
        "document_ids" => [1],
        "fan_out" => "comments",
        "opts" => %{
          "backend" => "Elixir.Scrypath.Sync.RelatedWorkerTest.RecordingBackend",
          "index_prefix" => nil,
          "meilisearch_url" => "http://localhost:7700",
          "otp_app" => nil,
          "repo" => nil
        }
      }

      assert :ok = RelatedWorker.perform(%Oban.Job{args: args})
      assert_received {:resolved, DummySchema, [%DummySchema{id: 1}]}
      assert_received {:upsert_documents, DummyTarget, [%Scrypath.Document{id: 1}], _config}
    end

    # An owner that 0.3.17 could fan out from under :oban: it has no search_records/2,
    # and its app configured no repo.
    defmodule RepolessOwner do
      defstruct [:id]

      def __scrypath__(:fan_outs) do
        [comments: [target: DummyTarget, resolver: {__MODULE__, :resolve_comments, []}]]
      end

      def __scrypath__(:document_id), do: :id

      def resolve_comments(triggers) do
        send(self(), {:resolved, __MODULE__, triggers})
        []
      end
    end

    test "a 0.3.17 related job that cannot reload its triggers cancels as :repo_required (WR-03)" do
      # The documented upgrade outcome (guides/related-data-and-reindexing.md): configure a
      # repo, define search_records/2, or drain these jobs before upgrading.
      args = %{
        "schema" => to_string(RepolessOwner),
        "document_ids" => [1],
        "fan_out" => "comments",
        "opts" => %{
          "backend" => to_string(RecordingBackend),
          "index_prefix" => nil,
          "meilisearch_url" => "http://localhost:7700",
          "otp_app" => nil,
          "repo" => nil
        }
      }

      assert RelatedWorker.perform(%Oban.Job{args: args}) ==
               {:cancel, {:invalid_job, :repo_required}}

      refute_received {:resolved, RepolessOwner, _}
      refute_received {:upsert_documents, _, _, _}
    end

    test "an opts key added by a newer release is ignored (rolling deploy)" do
      args = dummy_args([1], %{"future_option_zq179" => "x"})

      assert :ok = RelatedWorker.perform(%Oban.Job{args: args})
      assert_received {:resolved, DummySchema, [%DummySchema{id: 1}]}
    end

    defmodule ErrorTarget do
      use Ecto.Schema

      schema "error_targets" do
        field(:title, :string)
      end

      def __scrypath__(:document_id), do: :id
      def __scrypath__(:fields), do: [:title]
      def __scrypath__(:custom_document), do: false
    end

    defmodule ErrorBackend do
      @behaviour Scrypath.Backend

      @impl true
      def name, do: :error_backend

      @impl true
      def index_name(_schema, _config), do: "error_index"

      @impl true
      def upsert_documents(
            _schema_module,
            [%Scrypath.Document{data: %{title: "400 Error"}} | _],
            _config
          ) do
        {:error, {:http_error, 400, "Bad Request"}}
      end

      @impl true
      def upsert_documents(
            _schema_module,
            [%Scrypath.Document{data: %{title: "500 Error"}} | _],
            _config
          ) do
        {:error, {:http_error, 500, "Internal Server Error"}}
      end

      @impl true
      def upsert_documents(
            _schema_module,
            [%Scrypath.Document{data: %{title: "Generic Error"}} | _],
            _config
          ) do
        {:error, :some_generic_error}
      end

      @impl true
      def delete_documents(_schema, _ids, _config), do: {:ok, %{}}

      @impl true
      def search(_schema, _query, _config), do: {:ok, %{hits: []}}

      @impl true
      def search_facet_values(_schema, _facet, _query, _opts, _config),
        do: {:error, :not_implemented}
    end

    # The error a trigger produces lives in a struct field its loader returns.
    defmodule ErrorSchema do
      defstruct [:id, :error_type]

      def __scrypath__(:fan_outs) do
        [
          error_fan_out: [
            target: ErrorTarget,
            resolver: {__MODULE__, :resolve_errors, []}
          ]
        ]
      end

      def __scrypath__(:document_id) do
        :id
      end

      def search_records(ids, _context), do: Rows.load(__MODULE__, ids)

      def resolve_errors([%__MODULE__{error_type: type} | _] = triggers) do
        Enum.map(triggers, fn _ -> %ErrorTarget{id: 1, title: type} end)
      end
    end

    defp error_job(type) do
      Rows.put(ErrorSchema, [%ErrorSchema{id: 1, error_type: type}])

      %Oban.Job{
        args: %{
          "schema" => to_string(ErrorSchema),
          "document_ids" => [1],
          "fan_out" => "error_fan_out",
          "opts" => %{
            "backend" => to_string(ErrorBackend),
            "index_prefix" => "test"
          }
        }
      }
    end

    test "perform/1 cancels job on 4xx http error" do
      assert {:cancel, "HTTP 400: \"Bad Request\""} =
               RelatedWorker.perform(error_job("400 Error"))
    end

    test "perform/1 returns error on 5xx http error" do
      assert {:error, {:http_error, 500, "Internal Server Error"}} =
               RelatedWorker.perform(error_job("500 Error"))
    end

    test "perform/1 returns error on generic error" do
      assert {:error, :some_generic_error} = RelatedWorker.perform(error_job("Generic Error"))
    end
  else
    test "Oban.Worker is required for related worker contract tests" do
      flunk("Oban.Worker not loaded; related worker contract tests were skipped")
    end
  end
end
