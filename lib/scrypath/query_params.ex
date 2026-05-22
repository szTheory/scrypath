defmodule Scrypath.QueryParams do
  @moduledoc """
  Public request-edge toolkit for turning top-level request params into one stable
  plain-data Scrypath search-args shape.

  `%Scrypath.Query{}` remains **internal normalized query state** owned by the common
  `Scrypath.search/3` runtime. Host applications should use this module when they want a
  framework-light contract that can be cast from request params and then converted into
  `{text, keyword_opts}` for a context-owned `Scrypath.search/3` call.

  Use `normalize/1` at the request edge when handling Plug-decoded browser params.
  It returns either `{:ok, query_params}` or `{:error, error_map}` for owned Scrypath
  namespaces. `cast/1` remains available for already-runtime-compatible nested values.

  This module is data-only: it does not validate schema-specific search semantics and it
  does not execute searches.
  """

  alias Scrypath.QueryParams.Caster
  alias Scrypath.QueryParams.Error

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

  @type normalize_error_map :: %{
          form_errors: [Error.t()],
          field_errors: %{optional(atom()) => [Error.t()]},
          errors: [Error.t()]
        }

  @search_option_keys [:filter, :sort, :page, :facets, :facet_filter, :per_query]

  @doc """
  Normalizes Plug-decoded request params into the public Scrypath query-param contract.

  Unknown top-level params are ignored, while malformed values inside owned namespaces
  return aggregate structured issues.
  """
  @spec normalize(map()) :: {:ok, t()} | {:error, normalize_error_map()}
  def normalize(params) when is_map(params) do
    Caster.normalize(params)
  end

  @doc """
  Casts string-keyed or atom-keyed top-level request input into the public Scrypath
  query-param contract.
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
