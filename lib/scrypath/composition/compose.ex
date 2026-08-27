defmodule Scrypath.Composition.Compose do
  @moduledoc false

  alias Scrypath.Composition.Merge
  alias Scrypath.Composition.Normalize

  @search_option_keys [:filter, :sort, :page, :facets, :facet_filter, :per_query]

  @spec compose(map() | [map()], map()) :: {:ok, map()} | {:error, term()}
  def compose(fragments, criteria) do
    with {:ok, normalized_fragments} <- Normalize.normalize_fragments(fragments),
         {:ok, normalized_criteria} <- Normalize.normalize_criteria(criteria) do
      Merge.merge(normalized_fragments, normalized_criteria)
    end
  end

  @spec to_search_args(map()) :: {String.t(), keyword()}
  def to_search_args(%{} = composition) do
    text = Map.get(composition, :text, "")

    opts =
      Enum.map(@search_option_keys, fn key ->
        {key, Map.get(composition, key, default_value(key))}
      end)

    {text, opts}
  end

  defp default_value(:per_query), do: %{}
  defp default_value(_key), do: []
end
