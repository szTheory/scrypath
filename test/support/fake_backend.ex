defmodule Scrypath.TestSupport.FakeBackend do
  @behaviour Scrypath.Backend

  alias Scrypath.Document

  @impl true
  def name, do: :fake

  @impl true
  def index_name(schema_module, config) do
    prefix = Keyword.get(config, :index_prefix, "scrypath")
    schema_name = schema_module |> Module.split() |> List.last() |> Macro.underscore()

    "#{prefix}_#{schema_name}"
  end

  @impl true
  def upsert_documents(_schema_module, documents, _config) do
    {:ok, Enum.map(documents, &document_id/1)}
  end

  @impl true
  def delete_documents(_schema_module, document_ids, _config) do
    {:ok, document_ids}
  end

  @impl true
  def search(_schema_module, query, _config) do
    {:ok, %{query: query, hits: []}}
  end

  defp document_id(%Document{id: id}), do: id
end
