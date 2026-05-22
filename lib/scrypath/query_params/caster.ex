defmodule Scrypath.QueryParams.Caster do
  @moduledoc false

  @default %{
    text: "",
    filter: [],
    sort: [],
    page: [],
    facets: [],
    facet_filter: [],
    per_query: %{}
  }

  @spec cast(map()) :: Scrypath.QueryParams.t()
  def cast(params) when is_map(params) do
    text =
      params
      |> fetch_text()
      |> normalize_text()

    Map.merge(@default, %{
      text: text,
      filter: fetch_value(params, :filter, "filter", []),
      sort: fetch_value(params, :sort, "sort", []),
      page: fetch_value(params, :page, "page", []),
      facets: fetch_value(params, :facets, "facets", []),
      facet_filter: fetch_value(params, :facet_filter, "facet_filter", []),
      per_query: fetch_value(params, :per_query, "per_query", %{})
    })
  end

  defp fetch_text(params) do
    cond do
      is_binary(Map.get(params, :q)) -> Map.get(params, :q)
      is_binary(Map.get(params, "q")) -> Map.get(params, "q")
      is_binary(Map.get(params, :text)) -> Map.get(params, :text)
      is_binary(Map.get(params, "text")) -> Map.get(params, "text")
      true -> Map.get(params, :q) || Map.get(params, "q") || Map.get(params, :text) || Map.get(params, "text")
    end
  end

  defp normalize_text(text) when is_binary(text), do: text
  defp normalize_text(_text), do: ""

  defp fetch_value(params, atom_key, string_key, default) do
    case params do
      %{^atom_key => value} -> value
      %{^string_key => value} -> value
      _ -> default
    end
  end
end
