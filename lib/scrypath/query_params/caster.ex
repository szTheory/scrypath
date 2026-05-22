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

    query_params =
      Map.merge(@default, %{
        text: text,
        filter: fetch_value(params, :filter, "filter", []),
        sort: fetch_value(params, :sort, "sort", []),
        page: fetch_value(params, :page, "page", []),
        facets: fetch_value(params, :facets, "facets", []),
        facet_filter: fetch_value(params, :facet_filter, "facet_filter", []),
        per_query: fetch_value(params, :per_query, "per_query", %{})
      })

    validate_runtime_compatible_nested_values!(query_params)
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

  defp validate_runtime_compatible_nested_values!(query_params) do
    query_params
    |> validate_keyword_value!(:filter)
    |> validate_keyword_value!(:sort)
    |> validate_keyword_value!(:page)
    |> validate_keyword_value!(:facet_filter)
    |> validate_atom_list!(:facets)
    |> validate_atom_key_map!(:per_query)
  end

  defp validate_keyword_value!(query_params, key) do
    value = Map.fetch!(query_params, key)

    if value == [] or Keyword.keyword?(value) do
      query_params
    else
      raise ArgumentError, unsupported_nested_shape_message(key, "a keyword list")
    end
  end

  defp validate_atom_list!(query_params, key) do
    value = Map.fetch!(query_params, key)

    if value == [] or Enum.all?(value, &is_atom/1) do
      query_params
    else
      raise ArgumentError, unsupported_nested_shape_message(key, "a list of atoms")
    end
  end

  defp validate_atom_key_map!(query_params, key) do
    value = Map.fetch!(query_params, key)

    if value == %{} or Enum.all?(value, fn {nested_key, _value} -> is_atom(nested_key) end) do
      query_params
    else
      raise ArgumentError, unsupported_nested_shape_message(key, "an atom-keyed map")
    end
  end

  defp unsupported_nested_shape_message(key, expected_shape) do
    "Scrypath.QueryParams.cast/1 expects runtime-compatible nested values for #{inspect(key)} " <>
      "during phase 80. Use #{expected_shape} instead of request-style nested params."
  end
end
