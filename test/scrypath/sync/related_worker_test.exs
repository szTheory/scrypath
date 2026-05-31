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

    defmodule DummySchema do
      defstruct [:id]

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

      def resolve_comments([_ | _] = ids, :extra_arg) do
        Enum.map(ids, &%DummyTarget{id: &1, title: "Comment for #{&1}"})
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

      def resolve_comments([_ | _] = ids, :extra_arg) do
        Enum.map(ids, &%DummyTarget{id: &1, title: "Ordinary worker comment #{&1}"})
      end
    end

    test "perform/1 runs the resolver and calls sync_records" do
      args = %{
        "schema" => to_string(DummySchema),
        "document_ids" => [1, 2],
        "fan_out" => "comments",
        "opts" => %{
          "backend" => to_string(RecordingBackend),
          "index_prefix" => "test"
        }
      }

      assert :ok = RelatedWorker.perform(%Oban.Job{args: args})

      assert_received {:upsert_documents, DummyTarget, documents, config}
      assert length(documents) == 2
      assert Enum.map(documents, & &1.id) == [1, 2]
      assert config[:backend] == RecordingBackend
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

      assert_received {:upsert_documents, DummyTarget, documents, _config}
      assert Enum.map(documents, & &1.id) == [4, 5]

      assert Enum.map(documents, & &1.data[:title]) == [
               "Ordinary worker comment 4",
               "Ordinary worker comment 5"
             ]
    end

    test "perform/1 cancels job on invalid schema" do
      args = %{
        "schema" => "Elixir.NonExistentSchema",
        "document_ids" => [1, 2],
        "fan_out" => "comments",
        "opts" => %{}
      }

      assert {:cancel, {:invalid_job, :invalid_schema}} =
               RelatedWorker.perform(%Oban.Job{args: args})
    end

    test "perform/1 cancels job on invalid fan_out" do
      args = %{
        "schema" => to_string(DummySchema),
        "document_ids" => [1, 2],
        "fan_out" => "non_existent_fan_out",
        "opts" => %{}
      }

      assert {:cancel, {:invalid_job, :invalid_fan_out}} =
               RelatedWorker.perform(%Oban.Job{args: args})
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

    defmodule ErrorSchema do
      defstruct [:id]

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

      def resolve_errors([type | _] = ids) do
        Enum.map(ids, fn _ -> %ErrorTarget{id: 1, title: type} end)
      end
    end

    test "perform/1 cancels job on 4xx http error" do
      args = %{
        "schema" => to_string(ErrorSchema),
        "document_ids" => ["400 Error"],
        "fan_out" => "error_fan_out",
        "opts" => %{
          "backend" => to_string(ErrorBackend),
          "index_prefix" => "test"
        }
      }

      assert {:cancel, "HTTP 400: \"Bad Request\""} = RelatedWorker.perform(%Oban.Job{args: args})
    end

    test "perform/1 returns error on 5xx http error" do
      args = %{
        "schema" => to_string(ErrorSchema),
        "document_ids" => ["500 Error"],
        "fan_out" => "error_fan_out",
        "opts" => %{
          "backend" => to_string(ErrorBackend),
          "index_prefix" => "test"
        }
      }

      assert {:error, {:http_error, 500, "Internal Server Error"}} =
               RelatedWorker.perform(%Oban.Job{args: args})
    end

    test "perform/1 returns error on generic error" do
      args = %{
        "schema" => to_string(ErrorSchema),
        "document_ids" => ["Generic Error"],
        "fan_out" => "error_fan_out",
        "opts" => %{
          "backend" => to_string(ErrorBackend),
          "index_prefix" => "test"
        }
      }

      assert {:error, :some_generic_error} = RelatedWorker.perform(%Oban.Job{args: args})
    end
  else
    test "Oban.Worker is required for related worker contract tests" do
      flunk("Oban.Worker not loaded; related worker contract tests were skipped")
    end
  end
end
