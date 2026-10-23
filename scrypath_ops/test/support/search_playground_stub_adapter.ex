# Test-only `ScrypathOps.SearchPlayground.Adapter` implementation (no network).
defmodule ScrypathOps.Test.SearchPlaygroundStubAdapter do
  @behaviour ScrypathOps.SearchPlayground.Adapter

  alias Scrypath.FacetSearchResult
  alias Scrypath.MultiSearchResult
  alias Scrypath.Query
  alias Scrypath.SearchResult

  @impl true
  def search(_schema, text, opts) do
    wait_if_configured()
    raise_on_invalid_filter!(opts)
    q = Query.new(text, opts)

    raw =
      case Application.get_env(:scrypath_ops, :search_stub_variant, :ok) do
        :nested_hit ->
          %{
            "hits" => [%{"id" => %{"source" => "fixture"}, "title" => %{"nested" => ["value"]}}],
            "estimatedTotalHits" => 1
          }

        _ ->
          %{"hits" => [], "estimatedTotalHits" => 0}
      end

    {:ok, SearchResult.new(q, raw, [], [])}
  end

  @impl true
  def search_many(entries, opts) when is_list(entries) do
    case Application.get_env(:scrypath_ops, :search_stub_variant, :ok) do
      :slow_ok ->
        wait_if_configured()
        ok_result(entries, opts)

      :paused ->
        wait_if_configured()
        ok_result(entries, opts)

      :partial ->
        partial_result(entries, opts)

      :reverse_merge ->
        {:ok, result} = merge_result(entries, opts)
        {:ok, %{result | merge_hit_order: Enum.reverse(result.merge_hit_order)}}

      :merge ->
        merge_result(entries, opts)

      :hard_error ->
        {:error, :stub_hard_failure}

      _ ->
        ok_result(entries, opts)
    end
  end

  @impl true
  def search_facet_values(_schema, _facet_name, facet_query, _opts) do
    raw = %{"facetQuery" => facet_query, "facetHits" => []}
    {:ok, FacetSearchResult.new(raw)}
  end

  # `Scrypath.search/3` raises `ArgumentError` for options it rejects; mirror that for filters.
  defp raise_on_invalid_filter!(opts) do
    with {:ok, filter} <- Keyword.fetch(opts, :filter),
         {:error, message} <- Scrypath.Options.validate_search_filter(filter) do
      raise ArgumentError, message
    end
  end

  defp wait_if_configured do
    case Application.get_env(:scrypath_ops, :search_stub_variant, :ok) do
      :slow_ok ->
        Process.sleep(75)

      :paused ->
        waiter = Application.fetch_env!(:scrypath_ops, :search_stub_waiter)
        send(waiter, {:saved_search_run_adapter_started, self()})

        receive do
          :continue_saved_search_run -> :ok
        end

      _ ->
        :ok
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
    [{failed_schema, _failed_result} | successful] = ms.ordered

    ordered =
      successful
      |> Enum.with_index()
      |> Enum.map(fn
        {{schema, result}, 0} ->
          raw = %{
            "hits" => [%{"id" => "partial-hit", "title" => "Partial result"}],
            "estimatedTotalHits" => 1
          }

          {schema, SearchResult.new(result.query, raw, [], [])}

        {entry, _index} ->
          entry
      end)

    {:ok,
     MultiSearchResult.new(
       ordered: ordered,
       by_schema: Map.new(ordered),
       failures: [%{schema: failed_schema, reason: :stub}]
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
