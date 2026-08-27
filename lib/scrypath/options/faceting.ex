defmodule Scrypath.Options.Faceting do
  @moduledoc false

  @allowed [
    :attributes,
    :max_values_per_facet,
    :sort_facet_values_by,
    :nested_facet_paths,
    :hierarchy
  ]

  @spec validate_declaration(term()) :: {:ok, keyword()} | {:error, String.t()}
  def validate_declaration([]), do: {:ok, []}

  def validate_declaration(value) when is_list(value) do
    case coerce_keyword(value) do
      :invalid -> {:error, "faceting must be a keyword list or []"}
      [] -> {:ok, []}
      keyword -> validate_shape(keyword)
    end
  end

  def validate_declaration(_), do: {:error, "faceting must be a keyword list or []"}

  @spec validate_rules!(map()) :: map()
  def validate_rules!(%{faceting: []} = options), do: options

  def validate_rules!(%{faceting: faceting} = options) when is_list(faceting) do
    attributes = Keyword.fetch!(faceting, :attributes)
    filterable = options |> Map.fetch!(:filterable) |> MapSet.new()
    nested? = Keyword.get(faceting, :nested_facet_paths, false)

    if :* in attributes do
      raise ArgumentError, "faceting wildcard :* in attributes is not supported"
    end

    Enum.each(attributes, &validate_nested_attribute!(&1, nested?))

    Enum.each(attributes, fn attribute ->
      unless MapSet.member?(filterable, attribute) do
        raise ArgumentError, "facet attribute #{Atom.to_string(attribute)} is not in filterable"
      end
    end)

    options
  end

  defp coerce_keyword(value) do
    cond do
      Keyword.keyword?(value) -> value
      Macro.quoted_literal?(value) -> coerce_literal(value)
      true -> :invalid
    end
  end

  defp coerce_literal(value) do
    case Code.eval_quoted(value) do
      {evaluated, _} when evaluated == [] ->
        []

      {evaluated, _} when is_list(evaluated) ->
        if Keyword.keyword?(evaluated), do: evaluated, else: :invalid

      _ ->
        :invalid
    end
  end

  defp validate_shape(keyword) do
    case Keyword.keys(keyword) -- @allowed do
      [] -> keyword |> preprocess() |> then(&validate_preprocessed/1)
      keys -> {:error, "unknown faceting options: #{inspect(keys)}"}
    end
  end

  defp validate_preprocessed({:ok, keyword}), do: validate_attributes(keyword)
  defp validate_preprocessed({:error, _} = error), do: error

  defp preprocess(keyword) do
    if is_boolean(Keyword.get(keyword, :nested_facet_paths, false)) do
      keyword
      |> expand_hierarchy()
      |> case do
        {:ok, expanded} -> {:ok, Keyword.delete(expanded, :hierarchy)}
        {:error, _} = error -> error
      end
    else
      {:error, "faceting :nested_facet_paths must be a boolean"}
    end
  end

  defp expand_hierarchy(keyword) do
    case Keyword.fetch(keyword, :hierarchy) do
      :error ->
        {:ok, keyword}

      {:ok, hierarchy} ->
        with {:ok, base, depth} <- parse_hierarchy(hierarchy) do
          attributes = hierarchy_attributes(base, depth) ++ Keyword.get(keyword, :attributes, [])

          {:ok,
           keyword
           |> Keyword.put(:attributes, dedupe(attributes))
           |> Keyword.delete(:hierarchy)
           |> Keyword.put(:nested_facet_paths, true)}
        end
    end
  end

  defp parse_hierarchy(hierarchy) when is_list(hierarchy) and hierarchy != [] do
    if Keyword.keyword?(hierarchy) do
      with {:ok, base} <- fetch_hierarchy_atom(hierarchy),
           {:ok, depth} <- fetch_hierarchy_depth(hierarchy) do
        {:ok, base, depth}
      end
    else
      {:error, "faceting :hierarchy must be a keyword list"}
    end
  end

  defp parse_hierarchy(_), do: {:error, "faceting :hierarchy must be a keyword list"}

  defp fetch_hierarchy_atom(keyword) do
    case Keyword.fetch(keyword, :base) do
      {:ok, base} when is_atom(base) ->
        {:ok, base}

      {:ok, other} ->
        {:error, "faceting :hierarchy :base must be an atom, got: #{inspect(other)}"}

      :error ->
        {:error, "faceting :hierarchy requires :base field atom"}
    end
  end

  defp fetch_hierarchy_depth(keyword) do
    case Keyword.fetch(keyword, :depth) do
      {:ok, depth} when is_integer(depth) and depth > 0 ->
        {:ok, depth}

      {:ok, other} ->
        {:error, "faceting :hierarchy :depth must be a positive integer, got: #{inspect(other)}"}

      :error ->
        {:error, "faceting :hierarchy requires :depth positive integer"}
    end
  end

  defp hierarchy_attributes(base, depth) do
    prefix = Atom.to_string(base)
    for level <- 0..(depth - 1), do: String.to_atom("#{prefix}.lvl#{level}")
  end

  defp dedupe(values) do
    {reversed, _seen} =
      Enum.reduce(values, {[], MapSet.new()}, fn value, {acc, seen} ->
        if MapSet.member?(seen, value),
          do: {acc, seen},
          else: {[value | acc], MapSet.put(seen, value)}
      end)

    Enum.reverse(reversed)
  end

  defp validate_attributes(keyword) do
    case Keyword.fetch(keyword, :attributes) do
      :error -> {:error, "faceting requires :attributes when faceting options are given"}
      {:ok, []} -> {:error, "faceting :attributes must be a non-empty list of atoms"}
      {:ok, attributes} when is_list(attributes) -> validate_attribute_list(keyword, attributes)
      {:ok, _} -> {:error, "faceting :attributes must be a non-empty list of atoms"}
    end
  end

  defp validate_attribute_list(keyword, attributes) do
    if Enum.all?(attributes, &is_atom/1) do
      max_values = Keyword.get(keyword, :max_values_per_facet, 100)

      with :ok <- validate_max_values(max_values),
           {:ok, sort_map} <- normalize_sort(Keyword.get(keyword, :sort_facet_values_by, %{})) do
        {:ok,
         [
           attributes: attributes,
           max_values_per_facet: max_values,
           sort_facet_values_by: sort_map,
           nested_facet_paths: Keyword.get(keyword, :nested_facet_paths, false)
         ]}
      end
    else
      {:error, "faceting :attributes must be a non-empty list of atoms"}
    end
  end

  defp validate_max_values(value) when is_integer(value) and value > 0, do: :ok

  defp validate_max_values(_),
    do: {:error, "faceting :max_values_per_facet must be a positive integer"}

  defp normalize_sort(value) when is_map(value) do
    Enum.reduce_while(value, {:ok, %{}}, fn {key, order}, {:ok, acc} ->
      cond do
        not is_atom(key) ->
          {:halt, {:error, "faceting :sort_facet_values_by keys must be atoms"}}

        order in [:alpha, :count] ->
          {:cont, {:ok, Map.put(acc, key, order)}}

        true ->
          {:halt, {:error, "faceting :sort_facet_values_by values must be :alpha or :count"}}
      end
    end)
  end

  defp normalize_sort(value) when is_list(value) do
    if Keyword.keyword?(value),
      do: normalize_sort(Map.new(value)),
      else: {:error, "faceting :sort_facet_values_by must be a map or keyword"}
  end

  defp normalize_sort(_), do: {:error, "faceting :sort_facet_values_by must be a map or keyword"}

  defp validate_nested_attribute!(attribute, nested?) do
    if is_atom(attribute) and String.contains?(Atom.to_string(attribute), ".") do
      cond do
        not nested? ->
          raise ArgumentError,
                "hierarchical facet attribute #{inspect(attribute)} is not supported (set faceting nested_facet_paths: true for Meilisearch-style dotted paths)"

        not valid_nested_attribute?(attribute) ->
          raise ArgumentError,
                "hierarchical facet attribute #{inspect(attribute)} is not supported (dotted names must use a single dot with an lvlN suffix such as :\"categories.lvl0\")"

        true ->
          :ok
      end
    end
  end

  defp valid_nested_attribute?(attribute) do
    case String.split(Atom.to_string(attribute), ".", parts: 2) do
      [_plain] ->
        true

      [_prefix, suffix] ->
        not String.contains?(suffix, ".") and String.match?(suffix, ~r/^lvl[0-9]+$/)
    end
  end
end
