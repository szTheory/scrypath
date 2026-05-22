defmodule Scrypath.QueryParams do
  @moduledoc """
  Public request-edge toolkit for turning browser-shaped params into one stable plain-data
  Scrypath search-args shape.

  `%Scrypath.Query{}` remains **internal normalized query state** owned by the common
  `Scrypath.search/3` runtime. Host applications should use this module when they want a
  framework-light contract that can be cast from request params and then converted into
  `{text, keyword_opts}` for a context-owned `Scrypath.search/3` call.

  This module is data-only: it does not validate schema-specific search semantics and it
  does not execute searches.
  """

  alias Scrypath.QueryParams.Caster

  @typedoc "Stable public plain-data contract for `Scrypath.search/3` args."
  @type t :: %{
          text: String.t(),
          filter: keyword(),
          sort: keyword(),
          page: keyword(),
          facets: [atom()],
          facet_filter: keyword(),
          per_query: map()
        }

  @search_option_keys [:filter, :sort, :page, :facets, :facet_filter, :per_query]

  @doc """
  Casts string-keyed or atom-keyed request-shaped input into the public Scrypath query-param
  contract.
  """
  @spec cast(map()) :: t()
  def cast(params) when is_map(params) do
    Caster.cast(params)
  end

  @doc """
  Converts the public plain-data contract into `{text, keyword_opts}` for a context-owned
  `Scrypath.search/3` call.
  """
  @spec to_search_args(t()) :: {String.t(), keyword()}
  def to_search_args(%{} = query_params) do
    text = Map.get(query_params, :text, "")

    opts =
      Enum.map(@search_option_keys, fn key ->
        {key, Map.get(query_params, key, default_value(key))}
      end)

    {text, opts}
  end

  defp default_value(:per_query), do: %{}
  defp default_value(_key), do: []
end
