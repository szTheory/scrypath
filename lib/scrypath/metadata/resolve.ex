defmodule Scrypath.Metadata.Resolve do
  @moduledoc false

  alias Scrypath.Composition.Normalize
  alias Scrypath.Composition.Result

  @criteria_keys Result.criteria_keys()
  @host_owned %{
    tenant_policy: :host_owned,
    authorization: :host_owned,
    related_data: :host_owned
  }

  @spec reflect_search(module(), map(), map()) :: map()
  def reflect_search(_schema_module, capabilities, criteria_or_composition)
      when is_map(capabilities) and is_map(criteria_or_composition) do
    %{criteria: criteria, resolved: existing_resolved} = normalize_input(criteria_or_composition)
    unsupported = unsupported(criteria, capabilities)

    %{
      capabilities: capabilities,
      resolved: %{
        applied: applied(criteria, unsupported),
        defaulted: Map.get(existing_resolved, :defaulted, %{}),
        fixed: Map.get(existing_resolved, :fixed, %{}),
        unsupported: unsupported
      },
      host_owned: @host_owned
    }
  end

  @spec host_owned() :: map()
  def host_owned, do: @host_owned

  defp normalize_input(%{applied: _applied} = composition) do
    criteria =
      Enum.reduce(@criteria_keys, %{}, fn key, acc ->
        Map.put(acc, key, Map.get(composition, key, default_value(key)))
      end)

    %{
      criteria: criteria,
      resolved: %{
        applied: Map.get(composition, :applied, %{}),
        defaulted: Map.get(composition, :defaulted, %{}),
        fixed: Map.get(composition, :fixed, %{})
      }
    }
  end

  defp normalize_input(criteria) do
    {:ok, normalized} = Normalize.normalize_criteria(criteria)
    %{criteria: normalized, resolved: %{applied: %{}, defaulted: %{}, fixed: %{}}}
  end

  defp applied(criteria, unsupported) do
    criteria
    |> Enum.reduce(%{}, fn {field, value}, acc ->
      cleaned = subtract_unsupported(field, value, Map.get(unsupported, field))

      if present?(field, cleaned) do
        Map.put(acc, field, cleaned)
      else
        acc
      end
    end)
  end

  defp unsupported(criteria, capabilities) do
    filter_fields = capabilities.filters.fields |> MapSet.new()
    sort_fields = capabilities.sorts.fields |> MapSet.new()
    facet_fields = capabilities.facets.fields |> MapSet.new()

    %{}
    |> maybe_put(:filter, reject_keyword(criteria.filter, filter_fields))
    |> maybe_put(:facet_filter, reject_keyword(criteria.facet_filter, facet_fields))
    |> maybe_put(:sort, reject_sort(criteria.sort, sort_fields))
    |> maybe_put(:facets, reject_list(criteria.facets, facet_fields))
  end

  defp reject_keyword(keyword, allowed) do
    keyword
    |> Enum.reject(fn {field, _value} -> MapSet.member?(allowed, field) end)
    |> case do
      [] -> nil
      unsupported -> unsupported
    end
  end

  defp reject_sort(sort, allowed) do
    sort
    |> Enum.reject(fn {_dir, field} -> MapSet.member?(allowed, field) end)
    |> case do
      [] -> nil
      unsupported -> unsupported
    end
  end

  defp reject_list(list, allowed) do
    list
    |> Enum.reject(&MapSet.member?(allowed, &1))
    |> case do
      [] -> nil
      unsupported -> unsupported
    end
  end

  defp subtract_unsupported(:filter, value, unsupported), do: subtract_keyword(value, unsupported)

  defp subtract_unsupported(:facet_filter, value, unsupported),
    do: subtract_keyword(value, unsupported)

  defp subtract_unsupported(:sort, value, unsupported), do: subtract_sort(value, unsupported)
  defp subtract_unsupported(:facets, value, unsupported), do: subtract_list(value, unsupported)
  defp subtract_unsupported(_field, value, _unsupported), do: value

  defp subtract_keyword(value, nil), do: value

  defp subtract_keyword(value, unsupported) do
    unsupported_fields = unsupported |> Keyword.keys() |> MapSet.new()
    Enum.reject(value, fn {field, _val} -> MapSet.member?(unsupported_fields, field) end)
  end

  defp subtract_sort(value, nil), do: value

  defp subtract_sort(value, unsupported) do
    unsupported_fields =
      unsupported
      |> Enum.map(fn {_dir, field} -> field end)
      |> MapSet.new()

    Enum.reject(value, fn {_dir, field} -> MapSet.member?(unsupported_fields, field) end)
  end

  defp subtract_list(value, nil), do: value
  defp subtract_list(value, unsupported), do: Enum.reject(value, &(&1 in unsupported))

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp default_value(:text), do: ""
  defp default_value(:per_query), do: %{}
  defp default_value(_field), do: []

  defp present?(:text, value), do: is_binary(value) and String.trim(value) != ""
  defp present?(:per_query, value), do: value != %{}
  defp present?(_field, value), do: value != []
end
