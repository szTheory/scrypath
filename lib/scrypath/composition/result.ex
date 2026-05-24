defmodule Scrypath.Composition.Result do
  @moduledoc """
  Typed helpers for the public composition result envelope.

  The result stays plain data so host apps can inspect or log what composition
  applied before they hand the final `{text, keyword_opts}` into
  `Scrypath.search/3`.
  """

  @criteria_keys [:text, :filter, :sort, :page, :facets, :facet_filter, :per_query]

  @typedoc "Stable public plain-data result returned by `Scrypath.Composition.compose/2`."
  @type t :: %{
          required(:text) => String.t(),
          required(:filter) => keyword(),
          required(:sort) => keyword(),
          required(:page) => keyword(),
          required(:facets) => [atom()],
          required(:facet_filter) => keyword(),
          required(:per_query) => map(),
          required(:applied) => visibility(),
          required(:defaulted) => visibility(),
          required(:fixed) => visibility(),
          optional(:sources) => map(),
          optional(:warnings) => map()
        }

  @typedoc "Criteria vocabulary keyed the same way as `Scrypath.search/3` options."
  @type visibility :: %{
          optional(:text) => String.t(),
          optional(:filter) => keyword(),
          optional(:sort) => keyword(),
          optional(:page) => keyword(),
          optional(:facets) => [atom()],
          optional(:facet_filter) => keyword(),
          optional(:per_query) => map()
        }

  @spec criteria_keys() :: [atom()]
  def criteria_keys, do: @criteria_keys

  @spec new(map()) :: t()
  def new(attrs) when is_map(attrs) do
    base = %{
      text: Map.fetch!(attrs, :text),
      filter: Map.fetch!(attrs, :filter),
      sort: Map.fetch!(attrs, :sort),
      page: Map.fetch!(attrs, :page),
      facets: Map.fetch!(attrs, :facets),
      facet_filter: Map.fetch!(attrs, :facet_filter),
      per_query: Map.fetch!(attrs, :per_query),
      applied: Map.fetch!(attrs, :applied),
      defaulted: Map.fetch!(attrs, :defaulted),
      fixed: Map.fetch!(attrs, :fixed)
    }

    base
    |> maybe_put_optional(:sources, Map.get(attrs, :sources))
    |> maybe_put_optional(:warnings, Map.get(attrs, :warnings))
  end

  @spec empty_criteria() :: visibility()
  def empty_criteria do
    %{text: "", filter: [], sort: [], page: [], facets: [], facet_filter: [], per_query: %{}}
  end

  @spec compact_visibility(map()) :: visibility()
  def compact_visibility(criteria) when is_map(criteria) do
    Enum.reduce(@criteria_keys, %{}, fn key, acc ->
      value = Map.get(criteria, key, default_value(key))

      if present?(key, value) do
        Map.put(acc, key, value)
      else
        acc
      end
    end)
  end

  defp maybe_put_optional(acc, _key, nil), do: acc
  defp maybe_put_optional(acc, _key, value) when value == %{}, do: acc
  defp maybe_put_optional(acc, _key, value) when value == [], do: acc
  defp maybe_put_optional(acc, key, value), do: Map.put(acc, key, value)

  defp default_value(:text), do: ""
  defp default_value(:per_query), do: %{}
  defp default_value(_key), do: []

  defp present?(:text, value), do: is_binary(value) and String.trim(value) != ""
  defp present?(:per_query, value), do: value != %{}
  defp present?(_key, value), do: value != []
end
