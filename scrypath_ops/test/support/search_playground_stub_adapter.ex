# Test-only `ScrypathOps.SearchPlayground.Adapter` implementation (no network).
defmodule ScrypathOps.Test.SearchPlaygroundStubAdapter do
  @behaviour ScrypathOps.SearchPlayground.Adapter

  alias Scrypath.MultiSearchResult
  alias Scrypath.Query
  alias Scrypath.SearchResult

  @impl true
  def search(_schema, text, opts) do
    q = Query.new(text, opts)
    raw = %{"hits" => [], "estimatedTotalHits" => 0}
    {:ok, SearchResult.new(q, raw, [], [])}
  end

  @impl true
  def search_many(entries, opts) when is_list(entries) do
    case Application.get_env(:scrypath_ops, :search_stub_variant, :ok) do
      :partial ->
        partial_result(entries, opts)

      :merge ->
        merge_result(entries, opts)

      :hard_error ->
        {:error, :stub_hard_failure}

      _ ->
        ok_result(entries, opts)
    end
  end

  defp ok_result(entries, opts) do
    ordered =
      Enum.map(entries, fn
        {mod, text, eopts} ->
          merged = Keyword.merge(opts, eopts)
          q = Query.new(text, merged)
          raw = %{"hits" => [], "estimatedTotalHits" => 0}
          {mod, SearchResult.new(q, raw, [], [])}

        {mod, text} ->
          q = Query.new(text, opts)
          raw = %{"hits" => [], "estimatedTotalHits" => 0}
          {mod, SearchResult.new(q, raw, [], [])}
      end)

    by_schema = Map.new(ordered, fn {m, r} -> {m, r} end)
    {:ok, MultiSearchResult.new(ordered: ordered, by_schema: by_schema, failures: [])}
  end

  defp partial_result(entries, opts) do
    {:ok, ms} = ok_result(entries, opts)
    [first | _] = ms.ordered
    {mod, _} = first

    {:ok,
     MultiSearchResult.new(
       ordered: ms.ordered,
       by_schema: ms.by_schema,
       failures: [%{schema: mod, reason: :stub}]
     )}
  end

  defp merge_result(entries, opts) do
    {:ok, base} = ok_result(entries, opts)

    ordered =
      Enum.map(base.ordered, fn {mod, res} ->
        q = res.query

        raw = %{
          "hits" => [%{"id" => 1, "title" => "stub"}],
          "estimatedTotalHits" => 1
        }

        {mod, SearchResult.new(q, raw, [], [])}
      end)

    by_schema = Map.new(ordered, fn {m, r} -> {m, r} end)
    merge_hit_order = Enum.map(ordered, fn {mod, _} -> {mod, 1} end)

    {:ok,
     MultiSearchResult.new(
       ordered: ordered,
       by_schema: by_schema,
       failures: [],
       merge_hit_order: merge_hit_order
     )}
  end
end
