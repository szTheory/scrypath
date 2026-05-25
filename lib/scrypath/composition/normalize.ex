defmodule Scrypath.Composition.Normalize do
  @moduledoc false

  alias Scrypath.Composition.Result
  alias Scrypath.Options

  @criteria_keys MapSet.new(Result.criteria_keys())
  @fixed_keys MapSet.new([:filter, :facet_filter])

  @type normalized_fragment :: %{
          defaults: map(),
          fixed: map(),
          sources: map() | nil,
          warnings: map() | nil
        }

  @spec normalize_fragments(map() | [map()]) :: {:ok, [normalized_fragment()]} | {:error, term()}
  def normalize_fragments(fragments) when is_map(fragments) do
    normalize_fragments([fragments])
  end

  def normalize_fragments(fragments) when is_list(fragments) do
    Enum.reduce_while(fragments, {:ok, []}, fn fragment, {:ok, acc} ->
      case normalize_fragment(fragment) do
        {:ok, normalized} -> {:cont, {:ok, acc ++ [normalized]}}
        {:error, _} = error -> {:halt, error}
      end
    end)
  end

  def normalize_fragments(_), do: {:error, {:invalid_fragment, :expected_map_or_list}}

  @spec normalize_criteria(map() | nil) :: {:ok, map()} | {:error, term()}
  def normalize_criteria(nil), do: {:ok, Result.empty_criteria()}

  def normalize_criteria(criteria) when is_map(criteria) do
    normalize_field_map(criteria, :caller)
  end

  def normalize_criteria(_), do: {:error, {:invalid_criteria, :expected_map}}

  defp normalize_fragment(fragment) when is_map(fragment) do
    with {:ok, defaults} <- normalize_defaults(Map.get(fragment, :defaults, %{})),
         {:ok, fixed} <- normalize_fixed(Map.get(fragment, :fixed, %{})),
         {:ok, sources} <- normalize_optional_map(Map.get(fragment, :sources)),
         {:ok, warnings} <- normalize_optional_map(Map.get(fragment, :warnings)) do
      {:ok, %{defaults: defaults, fixed: fixed, sources: sources, warnings: warnings}}
    end
  end

  defp normalize_fragment(_), do: {:error, {:invalid_fragment, :expected_map}}

  defp normalize_defaults(defaults) when defaults == %{} or defaults == nil, do: {:ok, %{}}

  defp normalize_defaults(defaults) when is_map(defaults) do
    normalize_field_map(defaults, :defaults)
  end

  defp normalize_defaults(_), do: {:error, {:invalid_fragment, {:defaults, :expected_map}}}

  defp normalize_fixed(fixed) when fixed == %{} or fixed == nil, do: {:ok, %{}}

  defp normalize_fixed(fixed) when is_map(fixed) do
    Enum.reduce_while(fixed, {:ok, %{}}, fn {field, value}, {:ok, acc} ->
      if MapSet.member?(@fixed_keys, field) do
        case normalize_field(field, value) do
          {:ok, normalized} -> {:cont, {:ok, Map.put(acc, field, normalized)}}
          {:error, _} = error -> {:halt, error}
        end
      else
        {:halt, {:error, {:invalid_fixed_field, field}}}
      end
    end)
  end

  defp normalize_fixed(_), do: {:error, {:invalid_fragment, {:fixed, :expected_map}}}

  defp normalize_field_map(fields, kind) do
    Enum.reduce_while(fields, {:ok, %{}}, fn {field, value}, {:ok, acc} ->
      if MapSet.member?(@criteria_keys, field) do
        case normalize_field(field, value) do
          {:ok, normalized} -> {:cont, {:ok, Map.put(acc, field, normalized)}}
          {:error, _} = error -> {:halt, error}
        end
      else
        error =
          case kind do
            :defaults -> {:invalid_defaults_field, field}
            :caller -> {:invalid_criteria_field, field}
          end

        {:halt, {:error, error}}
      end
    end)
  end

  defp normalize_optional_map(nil), do: {:ok, nil}
  defp normalize_optional_map(map) when is_map(map), do: {:ok, map}
  defp normalize_optional_map(_), do: {:error, {:invalid_fragment, :expected_optional_map}}

  defp normalize_field(:text, value) when is_binary(value), do: {:ok, value}
  defp normalize_field(:text, nil), do: {:ok, ""}
  defp normalize_field(:text, value), do: {:error, {:invalid_fragment, {:text, value}}}

  defp normalize_field(:filter, value), do: normalize_keyword_field(:filter, value)
  defp normalize_field(:facet_filter, value), do: normalize_keyword_field(:facet_filter, value)

  defp normalize_field(:sort, value) when value == [] or value == nil, do: {:ok, []}

  defp normalize_field(:sort, value) do
    case Options.validate_search_sort(value) do
      {:ok, sort} -> {:ok, unique_keyword(sort)}
      {:error, _reason} -> {:error, {:invalid_fragment, {:sort, value}}}
    end
  end

  defp normalize_field(:page, value) when value == [] or value == nil, do: {:ok, []}

  defp normalize_field(:page, value) do
    try do
      case Options.validate_search_page(value) do
        {:ok, page} -> {:ok, canonical_page(page)}
        {:error, _reason} -> {:error, {:invalid_fragment, {:page, value}}}
      end
    rescue
      ArgumentError -> {:error, {:invalid_fragment, {:page, value}}}
    end
  end

  defp normalize_field(:facets, value) when value == [] or value == nil, do: {:ok, []}

  defp normalize_field(:facets, value) when is_list(value) do
    if Enum.all?(value, &is_atom/1) do
      {:ok, value}
    else
      {:error, {:invalid_fragment, {:facets, value}}}
    end
  end

  defp normalize_field(:facets, value), do: {:error, {:invalid_fragment, {:facets, value}}}

  defp normalize_field(:per_query, value) do
    case Options.validate_per_query_map(value) do
      {:ok, per_query} -> {:ok, Map.new(per_query)}
      {:error, _reason} -> {:error, {:invalid_fragment, {:per_query, value}}}
    end
  end

  defp normalize_keyword_field(_field, value) when value == [] or value == nil, do: {:ok, []}

  defp normalize_keyword_field(field, value) do
    case Options.validate_search_filter(value) do
      {:ok, keyword} -> {:ok, canonical_keyword(keyword)}
      {:error, _reason} -> {:error, {:invalid_fragment, {field, value}}}
    end
  end

  defp canonical_keyword(keyword) do
    keyword
    |> unique_keyword()
    |> Enum.sort_by(fn {key, _value} -> key end)
  end

  defp canonical_page(page) when is_map(page) do
    page
    |> Map.to_list()
    |> Enum.sort_by(fn {key, _value} -> key end)
  end

  defp unique_keyword(keyword) do
    reversed =
      Enum.reduce(keyword, [], fn {key, value}, acc ->
        acc
        |> Keyword.delete(key)
        |> Kernel.++([{key, value}])
      end)

    reversed
  end
end
