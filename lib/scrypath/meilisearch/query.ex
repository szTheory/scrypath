defmodule Scrypath.Meilisearch.Query do
  @moduledoc false

  alias Scrypath.Query

  @spec to_payload(Query.t()) :: map()
  def to_payload(%Query{} = query) do
    %{q: query.text}
    |> maybe_put(:filter, translate_filter(query.filter))
    |> maybe_put(:sort, translate_sort(query.sort))
    |> maybe_put(:page, query.page[:number])
    |> maybe_put(:hitsPerPage, query.page[:size])
  end

  defp translate_filter([]), do: nil

  defp translate_filter(filters) do
    Enum.flat_map(filters, fn
      {field, value} when is_list(value) ->
        Enum.map(value, fn {operator, operand} ->
          "#{field} #{translate_operator(operator)} #{format_value(operand)}"
        end)

      {field, value} ->
        ["#{field} = #{format_value(value)}"]
    end)
  end

  defp translate_sort([]), do: nil

  defp translate_sort(sort) do
    Enum.map(sort, fn {direction, field} ->
      "#{field}:#{direction}"
    end)
  end

  defp translate_operator(:eq), do: "="
  defp translate_operator(:gt), do: ">"
  defp translate_operator(:gte), do: ">="
  defp translate_operator(:lt), do: "<"
  defp translate_operator(:lte), do: "<="

  defp format_value(value) when is_atom(value), do: Jason.encode!(Atom.to_string(value))
  defp format_value(value), do: Jason.encode!(value)

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
