defmodule Scrypath.TestSupport.FakeBackend do
  @moduledoc false

  @behaviour Scrypath.Backend

  alias Scrypath.Document
  alias Scrypath.Query

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
    base = %{
      query: query,
      hits: [],
      page: 1,
      hitsPerPage: 20,
      totalHits: 0,
      normalized_query?: match?(%Query{}, query)
    }

    {:ok, maybe_put_facet_wires(query, base)}
  end

  defp maybe_put_facet_wires(%Query{facets: []}, m), do: m

  defp maybe_put_facet_wires(%Query{facets: fs}, m) when is_list(fs) do
    dist =
      Map.new(fs, fn f ->
        {Atom.to_string(f), %{"a" => 2, "b" => 1}}
      end)

    stats =
      Map.new(fs, fn f ->
        {Atom.to_string(f), %{"min" => 1, "max" => 10}}
      end)

    m
    |> Map.put("facetDistribution", dist)
    |> Map.put("facetStats", stats)
  end

  defp document_id(%Document{id: id}), do: id
end
