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
    end

    defmodule DummyTarget do
      use Ecto.Schema
      
      schema "dummy_targets" do
        field :title, :string
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
  end
end
