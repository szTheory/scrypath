defmodule Scrypath.Composition.Merge do
  @moduledoc false

  alias Scrypath.Composition.Result

  @spec merge([map()], map()) :: {:ok, Result.t()} | {:error, term()}
  def merge(fragments, caller) when is_list(fragments) and is_map(caller) do
    with {:ok, merged} <- merge_fragments(fragments),
         {:ok, defaults_applied} <- apply_defaults(merged.defaults, caller),
         {:ok, final_criteria, fixed_visibility} <- apply_fixed(merged.fixed, defaults_applied) do
      {:ok,
       Result.new(%{
         text: final_criteria.text,
         filter: final_criteria.filter,
         sort: final_criteria.sort,
         page: final_criteria.page,
         facets: final_criteria.facets,
         facet_filter: final_criteria.facet_filter,
         per_query: final_criteria.per_query,
         applied: Result.compact_visibility(final_criteria),
         defaulted: Result.compact_visibility(visibility_from_defaults(merged.defaults, caller)),
         fixed: Result.compact_visibility(fixed_visibility),
         sources: merged.sources,
         warnings: merged.warnings
       })}
    end
  end

  defp merge_fragments(fragments) do
    empty = %{defaults: %{}, fixed: %{}, sources: %{}, warnings: %{}}

    Enum.reduce_while(fragments, {:ok, empty}, fn fragment, {:ok, acc} ->
      case merge_defaults(acc.defaults, fragment.defaults) do
        {:ok, defaults} ->
          case merge_fixed(acc.fixed, fragment.fixed) do
            {:ok, fixed} ->
              {:cont,
               {:ok,
                %{
                  defaults: defaults,
                  fixed: fixed,
                  sources: merge_optional_maps(acc.sources, fragment.sources),
                  warnings: merge_optional_maps(acc.warnings, fragment.warnings)
                }}}

            {:error, _} = error ->
              {:halt, error}
          end
      end
    end)
  end

  defp merge_defaults(existing, incoming) do
    merged =
      Enum.reduce(incoming, existing, fn {field, value}, acc ->
        Map.put(acc, field, merge_default_field(field, Map.get(acc, field), value))
      end)

    {:ok, merged}
  end

  defp merge_default_field(:filter, nil, value), do: value
  defp merge_default_field(:facet_filter, nil, value), do: value
  defp merge_default_field(:per_query, nil, value), do: value

  defp merge_default_field(:filter, left, right), do: merge_keyword_right(left, right)
  defp merge_default_field(:facet_filter, left, right), do: merge_keyword_right(left, right)
  defp merge_default_field(:per_query, left, right), do: Map.merge(left, right)
  defp merge_default_field(_field, _left, right), do: right

  defp merge_fixed(existing, incoming) do
    Enum.reduce_while(incoming, {:ok, existing}, fn {field, value}, {:ok, acc} ->
      case Map.get(acc, field) do
        nil ->
          {:cont, {:ok, Map.put(acc, field, value)}}

        current when current == value ->
          {:cont, {:ok, acc}}

        current ->
          case conflicting_key(current, value) do
            nil ->
              {:cont, {:ok, Map.put(acc, field, merge_keyword_right(current, value))}}

            key ->
              {:halt,
               {:error,
                {:composition_conflict, field, key,
                 %{
                   left: keyword_value(current, key),
                   right: keyword_value(value, key),
                   source: :fixed
                 }}}}
          end
      end
    end)
  end

  defp apply_defaults(defaults, caller) do
    criteria =
      Enum.reduce(Result.criteria_keys(), Result.empty_criteria(), fn field, acc ->
        caller_value = Map.get(caller, field, default_value(field))
        default_value_for_field = Map.get(defaults, field, default_value(field))
        Map.put(acc, field, choose_value(field, default_value_for_field, caller_value))
      end)

    {:ok, criteria}
  end

  defp apply_fixed(fixed, criteria) do
    Enum.reduce_while(fixed, {:ok, criteria, %{}}, fn {field, constraints}, {:ok, acc, vis} ->
      case apply_fixed_field(field, Map.get(acc, field), constraints) do
        {:ok, final_value, fixed_value} ->
          {:cont, {:ok, Map.put(acc, field, final_value), Map.put(vis, field, fixed_value)}}

        {:error, _} = error ->
          {:halt, error}
      end
    end)
  end

  defp apply_fixed_field(field, current, constraints) do
    case conflicting_key(current, constraints) do
      nil ->
        merged = merge_keyword_right(current, constraints)
        {:ok, merged, constraints}

      key ->
        {:error,
         {:composition_conflict, field, key,
          %{
            caller: keyword_value(current, key),
            fixed: keyword_value(constraints, key),
            source: :caller
          }}}
    end
  end

  defp choose_value(:text, default_text, caller_text) do
    if blank_text?(caller_text), do: default_text, else: caller_text
  end

  defp choose_value(:filter, defaults, caller), do: merge_keyword_right(defaults, caller)
  defp choose_value(:facet_filter, defaults, caller), do: merge_keyword_right(defaults, caller)
  defp choose_value(:per_query, defaults, caller), do: Map.merge(defaults, caller)

  defp choose_value(_field, defaults, caller) do
    if empty_value?(caller), do: defaults, else: caller
  end

  defp visibility_from_defaults(defaults, caller) do
    Enum.reduce(defaults, %{}, fn {field, value}, acc ->
      case defaulted_value(field, value, caller) do
        nil -> acc
        defaulted -> Map.put(acc, field, defaulted)
      end
    end)
  end

  defp default_applied?(:text, value, caller),
    do: blank_text?(Map.get(caller, :text, "")) and value != ""

  defp default_applied?(:filter, value, caller),
    do: has_defaulted_keyword_keys?(value, Map.get(caller, :filter, []))

  defp default_applied?(:facet_filter, value, caller),
    do: has_defaulted_keyword_keys?(value, Map.get(caller, :facet_filter, []))

  defp default_applied?(:per_query, value, caller),
    do: has_defaulted_map_keys?(value, Map.get(caller, :per_query, %{}))

  defp default_applied?(field, value, caller),
    do: empty_value?(Map.get(caller, field, default_value(field))) and not empty_value?(value)

  defp has_defaulted_keyword_keys?(defaults, caller) do
    caller_keys = caller |> Keyword.keys() |> MapSet.new()

    defaults
    |> Enum.reject(fn {key, _value} -> MapSet.member?(caller_keys, key) end)
    |> Enum.empty?()
    |> Kernel.not()
  end

  defp has_defaulted_map_keys?(defaults, caller) do
    defaults
    |> Enum.reject(fn {key, _value} -> Map.has_key?(caller, key) end)
    |> Enum.empty?()
    |> Kernel.not()
  end

  defp defaulted_value(:text, value, caller) do
    if default_applied?(:text, value, caller), do: value, else: nil
  end

  defp defaulted_value(:filter, value, caller) do
    caller_keys = caller |> Map.get(:filter, []) |> Keyword.keys() |> MapSet.new()
    subset = Enum.reject(value, fn {key, _value} -> MapSet.member?(caller_keys, key) end)
    if subset == [], do: nil, else: subset
  end

  defp defaulted_value(:facet_filter, value, caller) do
    caller_keys = caller |> Map.get(:facet_filter, []) |> Keyword.keys() |> MapSet.new()
    subset = Enum.reject(value, fn {key, _value} -> MapSet.member?(caller_keys, key) end)
    if subset == [], do: nil, else: subset
  end

  defp defaulted_value(:per_query, value, caller) do
    subset =
      Enum.reject(value, fn {key, _value} ->
        caller
        |> Map.get(:per_query, %{})
        |> Map.has_key?(key)
      end)
      |> Map.new()

    if subset == %{}, do: nil, else: subset
  end

  defp defaulted_value(field, value, caller) do
    if default_applied?(field, value, caller), do: value, else: nil
  end

  defp conflicting_key(left, right) do
    left_map = Map.new(left)
    right_map = Map.new(right)

    Enum.find_value(Map.keys(left_map), fn key ->
      if Map.has_key?(right_map, key) and Map.fetch!(left_map, key) != Map.fetch!(right_map, key) do
        key
      end
    end)
  end

  defp keyword_value(keyword, key), do: Keyword.get(keyword, key)

  defp merge_keyword_right(left, right) do
    left
    |> Map.new()
    |> Map.merge(Map.new(right))
    |> Map.to_list()
    |> Enum.sort_by(fn {key, _value} -> key end)
  end

  defp merge_optional_maps(left, nil), do: left
  defp merge_optional_maps(left, right), do: Map.merge(left, right)

  defp default_value(:text), do: ""
  defp default_value(:per_query), do: %{}
  defp default_value(_field), do: []

  defp blank_text?(value), do: not is_binary(value) or String.trim(value) == ""

  defp empty_value?(value) when value == [] or value == %{}, do: true
  defp empty_value?(value) when is_binary(value), do: String.trim(value) == ""
  defp empty_value?(_value), do: false
end
