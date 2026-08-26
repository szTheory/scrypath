defmodule Scrypath.Meilisearch.Settings.Wire do
  @moduledoc false

  @canonical_to_camel %{
    synonyms: "synonyms",
    typo_tolerance: "typoTolerance",
    ranking_rules: "rankingRules",
    distinct_attribute: "distinctAttribute",
    stop_words: "stopWords",
    searchable_attributes: "searchableAttributes",
    sortable_attributes: "sortableAttributes",
    filterable_attributes: "filterableAttributes",
    displayed_attributes: "displayedAttributes"
  }

  @scrypath_meta_keys [:ranking_rules_strict?]

  @spec expand_synonyms(list() | map() | {list(), keyword()}) :: map()
  def expand_synonyms(groups) when is_map(groups), do: groups
  def expand_synonyms(groups) when is_list(groups), do: expand_groups(groups, false)

  def expand_synonyms({groups, opts}) when is_list(groups) and is_list(opts) do
    expand_groups(groups, Keyword.get(opts, :one_way, false))
  end

  @spec translate(map()) :: map()
  def translate(canonical) when is_map(canonical) do
    {unrecognized, recognized} = Map.pop(canonical, :__unrecognized__, %{})

    one_way = one_way_setting(recognized, unrecognized)

    recognized = Map.delete(recognized, :one_way)
    unrecognized = unrecognized |> Map.delete(:one_way) |> Map.delete("one_way")

    recognized
    |> strip_meta_keys()
    |> Enum.into(%{}, fn {key, value} ->
      translated =
        if key == :synonyms do
          if is_list(value),
            do: expand_synonyms({value, [one_way: one_way]}),
            else: expand_synonyms(value)
        else
          camelize(value)
        end

      {Map.get(@canonical_to_camel, key) || camelize_atom(key), translated}
    end)
    |> Map.merge(unrecognized)
  end

  defp expand_groups(groups, one_way) do
    Enum.reduce(groups, %{}, fn group, acc ->
      stringified = Enum.map(group, &to_string/1)

      cond do
        stringified == [] ->
          acc

        one_way ->
          [head | rest] = stringified
          Map.update(acc, head, rest, &(&1 ++ rest))

        true ->
          Enum.reduce(stringified, acc, fn term, acc2 ->
            Map.update(acc2, term, stringified -- [term], &(&1 ++ (stringified -- [term])))
          end)
      end
    end)
  end

  defp one_way_setting(recognized, unrecognized) do
    case {
      Map.get(recognized, :one_way),
      Map.get(unrecognized, :one_way),
      Map.get(unrecognized, "one_way")
    } do
      {value, _, _} when not is_nil(value) -> value
      {_, value, _} when not is_nil(value) -> value
      {_, _, value} when not is_nil(value) -> value
      _ -> false
    end
  end

  defp strip_meta_keys(map) do
    map
    |> Enum.reject(fn {key, _} ->
      key in @scrypath_meta_keys or
        (is_atom(key) and String.ends_with?(Atom.to_string(key), "_strict?"))
    end)
    |> Map.new()
  end

  defp camelize(value) when is_map(value) do
    Map.new(value, fn {key, nested} ->
      translated_key = if is_atom(key), do: camelize_atom(key), else: key
      {translated_key, camelize(nested)}
    end)
  end

  defp camelize(value) when is_list(value), do: Enum.map(value, &camelize/1)
  defp camelize(value), do: value

  defp camelize_atom(atom) do
    atom
    |> Atom.to_string()
    |> Macro.camelize()
    |> then(&(String.downcase(String.slice(&1, 0..0)) <> String.slice(&1, 1..-1//1)))
  end
end
