defmodule Scrypath.QueryParams.Caster do
  @moduledoc false

  alias Scrypath.Options
  alias Scrypath.QueryParams.Error

  @default %{
    text: "",
    filter: [],
    sort: [],
    page: [],
    facets: [],
    facet_filter: [],
    per_query: %{}
  }

  @page_keys ~w(number size)a
  @sort_keys ~w(field dir)a
  @sort_dirs %{"asc" => :asc, "desc" => :desc}

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

  @spec normalize(map()) :: {:ok, Scrypath.QueryParams.t()} | {:error, map()}
  def normalize(params) when is_map(params) do
    text =
      params
      |> fetch_text()
      |> normalize_text()

    {query_params, errors} =
      {@default |> Map.put(:text, text), []}
      |> normalize_filter(params)
      |> normalize_sort(params)
      |> normalize_page(params)
      |> normalize_facets(params)
      |> normalize_facet_filter(params)
      |> normalize_per_query(params)

    if errors == [] do
      {:ok, query_params}
    else
      {:error, group_errors(errors)}
    end
  end

  defp normalize_filter({query_params, errors}, params) do
    case fetch_value(params, :filter, "filter", :missing) do
      :missing ->
        {query_params, errors}

      value ->
        put_normalized_field({query_params, errors}, :filter, value, &normalize_field_map/2)
    end
  end

  defp normalize_sort({query_params, errors}, params) do
    case fetch_value(params, :sort, "sort", :missing) do
      :missing ->
        {query_params, errors}

      value ->
        case normalize_sort_value(value) do
          {:ok, sort} ->
            validate_and_put({query_params, errors}, :sort, sort, &Options.validate_search_sort/1)

          {:error, sort_errors} ->
            {query_params, errors ++ sort_errors}
        end
    end
  end

  defp normalize_page({query_params, errors}, params) do
    case fetch_value(params, :page, "page", :missing) do
      :missing ->
        {query_params, errors}

      value ->
        case normalize_page_value(value) do
          {:ok, page} ->
            validate_and_put({query_params, errors}, :page, page, &Options.validate_search_page/1)

          {:error, page_errors} ->
            {query_params, errors ++ page_errors}
        end
    end
  end

  defp normalize_facets({query_params, errors}, params) do
    case fetch_value(params, :facets, "facets", :missing) do
      :missing ->
        {query_params, errors}

      value ->
        case normalize_facets_value(value) do
          {:ok, facets} ->
            {Map.put(query_params, :facets, facets), errors}

          {:error, facet_errors} ->
            {query_params, errors ++ facet_errors}
        end
    end
  end

  defp normalize_facet_filter({query_params, errors}, params) do
    case fetch_value(params, :facet_filter, "facet_filter", :missing) do
      :missing ->
        {query_params, errors}

      value ->
        put_normalized_field(
          {query_params, errors},
          :facet_filter,
          value,
          &normalize_field_map/2
        )
    end
  end

  defp normalize_per_query({query_params, errors}, params) do
    case fetch_value(params, :per_query, "per_query", :missing) do
      :missing ->
        {query_params, errors}

      nil ->
        {query_params, errors}

      %{} = value when map_size(value) == 0 ->
        {query_params, errors}

      [] ->
        {query_params, errors}

      _value ->
        error =
          issue(
            :per_query,
            :unsupported_param,
            [:per_query],
            "per_query is not part of the browser param grammar",
            %{namespace: :per_query}
          )

        {query_params, errors ++ [error]}
    end
  end

  defp put_normalized_field({query_params, errors}, field, value, normalizer) do
    case normalizer.(field, value) do
      {:ok, normalized} ->
        validator =
          case field do
            :filter -> &Options.validate_search_filter/1
            :facet_filter -> &Options.validate_search_filter/1
          end

        validate_and_put({query_params, errors}, field, normalized, validator)

      {:error, field_errors} ->
        {query_params, errors ++ field_errors}
    end
  end

  defp validate_and_put({query_params, errors}, field, value, validator) do
    case validator.(value) do
      {:ok, normalized} ->
        normalized =
          case field do
            :page when is_map(normalized) -> canonical_page_keyword(normalized)
            _ -> normalized
          end

        {Map.put(query_params, field, normalized), errors}

      {:error, message} ->
        error = issue(field, :invalid_value, [field], message, %{validator: inspect(validator)})
        {query_params, errors ++ [error]}
    end
  end

  defp normalize_field_map(_field, value) when value == [] or value == %{}, do: {:ok, []}

  defp normalize_field_map(field, value) when is_list(value) do
    case ensure_keyword(value) do
      {:ok, keyword} ->
        {:ok, keyword}

      :error ->
        {:error,
         [
           issue(field, :invalid_shape, [field], "#{field} must be a keyword list or map", %{
             expected: "keyword list or map"
           })
         ]}
    end
  end

  defp normalize_field_map(field, value) when is_map(value) do
    {pairs, errors} =
      Enum.reduce(value, {[], []}, fn {raw_key, raw_value}, {pairs, errors} ->
        path = [field, key_segment(raw_key)]

        case safe_existing_atom(raw_key) do
          nil ->
            {pairs,
             errors ++
               [
                 issue(
                   field,
                   :unknown_field,
                   path,
                   "field is not recognized as an existing atom",
                   %{field: raw_key}
                 )
               ]}

          key ->
            case normalize_scalar_or_list(field, key, raw_value) do
              {:ok, normalized} -> {[{key, normalized} | pairs], errors}
              {:error, error} -> {pairs, errors ++ [error]}
            end
        end
      end)

    if errors == [] do
      {:ok, sort_keyword_pairs(pairs)}
    else
      {:error, errors}
    end
  end

  defp normalize_field_map(field, _value) do
    {:error,
     [
       issue(field, :invalid_shape, [field], "#{field} must be a keyword list or map", %{
         expected: "keyword list or map"
       })
     ]}
  end

  defp normalize_scalar_or_list(field, key, value) when is_map(value) do
    {:error,
     issue(field, :invalid_shape, [field, key], "expected a scalar or list value", %{
       expected: "scalar or list"
     })}
  end

  defp normalize_scalar_or_list(field, key, value) when is_list(value) do
    if Enum.all?(value, &scalar?/1) do
      {:ok, value}
    else
      {:error,
       issue(field, :invalid_shape, [field, key], "expected a scalar or list value", %{
         expected: "scalar or list"
       })}
    end
  end

  defp normalize_scalar_or_list(field, key, value) do
    if scalar?(value) do
      {:ok, value}
    else
      {:error,
       issue(field, :invalid_shape, [field, key], "expected a scalar or list value", %{
         expected: "scalar or list"
       })}
    end
  end

  defp normalize_sort_value(value) when value == %{} or value == [], do: {:ok, []}

  defp normalize_sort_value(value) when is_list(value) do
    case ensure_keyword(value) do
      {:ok, keyword} ->
        {:ok, keyword}

      :error ->
        {:error,
         [
           issue(:sort, :invalid_shape, [:sort], "sort must be a keyword list or map", %{
             expected: "keyword list or map"
           })
         ]}
    end
  end

  defp normalize_sort_value(value) when is_map(value) do
    errors = unknown_key_errors(:sort, Map.keys(value), @sort_keys)
    field = fetch_map_value(value, "field")
    dir = fetch_map_value(value, "dir")

    errors =
      errors
      |> maybe_add_missing(:sort, :field, field)
      |> maybe_add_missing(:sort, :dir, dir)

    {sort, errors} =
      case {normalize_sort_field(field), normalize_sort_dir(dir)} do
        {{:ok, sort_field}, {:ok, sort_dir}} ->
          {[{sort_dir, sort_field}], errors}

        {{:error, field_error}, {:ok, _dir}} ->
          {[], errors ++ [field_error]}

        {{:ok, _field}, {:error, dir_error}} ->
          {[], errors ++ [dir_error]}

        {{:error, field_error}, {:error, dir_error}} ->
          {[], errors ++ [field_error, dir_error]}
      end

    if errors == [] do
      {:ok, sort}
    else
      {:error, errors}
    end
  end

  defp normalize_sort_value(_value) do
    {:error,
     [
       issue(:sort, :invalid_shape, [:sort], "sort must be a keyword list or map", %{
         expected: "keyword list or map"
       })
     ]}
  end

  defp normalize_page_value(value) when value == %{} or value == [], do: {:ok, []}

  defp normalize_page_value(value) when is_list(value) do
    case ensure_keyword(value) do
      {:ok, keyword} ->
        {:ok, keyword}

      :error ->
        {:error,
         [
           issue(:page, :invalid_shape, [:page], "page must be a keyword list or map", %{
             expected: "keyword list or map"
           })
         ]}
    end
  end

  defp normalize_page_value(value) when is_map(value) do
    errors = unknown_key_errors(:page, Map.keys(value), @page_keys)

    {pairs, value_errors} =
      Enum.reduce(@page_keys, {[], []}, fn key, {pairs, value_errors} ->
        case fetch_map_value(value, Atom.to_string(key)) do
          nil ->
            {pairs, value_errors}

          raw ->
            case parse_positive_integer(raw) do
              {:ok, parsed} ->
                {[{key, parsed} | pairs], value_errors}

              :error ->
                error =
                  issue(
                    :page,
                    :invalid_value,
                    [:page, key],
                    "#{key} must be a positive integer",
                    %{expected: "positive integer"}
                  )

                {pairs, value_errors ++ [error]}
            end
        end
      end)

    page = canonical_page_keyword(pairs)
    errors = errors ++ value_errors

    if errors == [] do
      {:ok, page}
    else
      {:error, errors}
    end
  end

  defp normalize_page_value(_value) do
    {:error,
     [
       issue(:page, :invalid_shape, [:page], "page must be a keyword list or map", %{
         expected: "keyword list or map"
       })
     ]}
  end

  defp normalize_facets_value(value) when value == [] or value == nil, do: {:ok, []}

  defp normalize_facets_value(value) when is_list(value) do
    {facets, errors} =
      Enum.reduce(value, {[], []}, fn raw_facet, {facets, errors} ->
        case safe_existing_atom(raw_facet) do
          nil ->
            error =
              issue(:facets, :unknown_field, [:facets], "facet must be an existing atom name", %{
                facet: raw_facet
              })

            {facets, errors ++ [error]}

          facet ->
            {[facet | facets], errors}
        end
      end)

    if errors == [] do
      {:ok, Enum.reverse(facets)}
    else
      {:error, errors}
    end
  end

  defp normalize_facets_value(_value) do
    {:error,
     [issue(:facets, :invalid_shape, [:facets], "facets must be a list", %{expected: "list"})]}
  end

  defp ensure_keyword(value) do
    if Keyword.keyword?(value), do: {:ok, value}, else: :error
  end

  defp unknown_key_errors(field, keys, allowed_keys) do
    allowed = MapSet.new(Enum.map(allowed_keys, &Atom.to_string/1))

    keys
    |> Enum.reject(fn key -> key_allowed?(key, allowed) end)
    |> Enum.map(fn key ->
      issue(field, :unknown_key, [field, key_segment(key)], "unknown key", %{
        allowed: allowed_keys
      })
    end)
  end

  defp maybe_add_missing(errors, _field, _key, value) when not is_nil(value), do: errors

  defp maybe_add_missing(errors, field, key, nil) do
    errors ++ [issue(field, :missing_key, [field, key], "missing required key", %{})]
  end

  defp normalize_sort_field(value) when is_binary(value) or is_atom(value) do
    case safe_existing_atom(value) do
      nil ->
        {:error,
         issue(
           :sort,
           :unknown_field,
           [:sort, :field],
           "sort field must be an existing atom name",
           %{field: value}
         )}

      field ->
        {:ok, field}
    end
  end

  defp normalize_sort_field(_value) do
    {:error,
     issue(:sort, :invalid_value, [:sort, :field], "sort field must be a string or atom", %{
       expected: "string or atom"
     })}
  end

  defp normalize_sort_dir(value) when is_atom(value),
    do: normalize_sort_dir(Atom.to_string(value))

  defp normalize_sort_dir(value) when is_binary(value) do
    case Map.fetch(@sort_dirs, String.downcase(value)) do
      {:ok, dir} ->
        {:ok, dir}

      :error ->
        {:error,
         issue(:sort, :invalid_value, [:sort, :dir], "sort dir must be asc or desc", %{
           allowed: Map.keys(@sort_dirs)
         })}
    end
  end

  defp normalize_sort_dir(_value) do
    {:error,
     issue(:sort, :invalid_value, [:sort, :dir], "sort dir must be asc or desc", %{
       allowed: Map.keys(@sort_dirs)
     })}
  end

  defp group_errors(errors) do
    sorted_errors = Enum.sort_by(errors, &error_sort_key/1)

    field_errors =
      sorted_errors
      |> Enum.reject(&is_nil(&1.field))
      |> Enum.group_by(& &1.field)

    %{
      form_errors: Enum.filter(sorted_errors, &is_nil(&1.field)),
      field_errors: field_errors,
      errors: sorted_errors
    }
  end

  defp error_sort_key(%Error{path: path, code: code}) do
    {code_priority(code), Enum.map(path, &to_string/1)}
  end

  defp code_priority(:invalid_shape), do: 0
  defp code_priority(:invalid_value), do: 1
  defp code_priority(:missing_key), do: 2
  defp code_priority(:unknown_key), do: 3
  defp code_priority(:unknown_field), do: 4
  defp code_priority(:unsupported_param), do: 5
  defp code_priority(_code), do: 6

  defp issue(field, code, path, message, meta) do
    %Error{field: field, code: code, message: message, path: path, meta: meta}
  end

  defp scalar?(value),
    do: is_binary(value) or is_number(value) or is_boolean(value) or is_nil(value)

  defp fetch_text(params) do
    cond do
      is_binary(Map.get(params, :q)) ->
        Map.get(params, :q)

      is_binary(Map.get(params, "q")) ->
        Map.get(params, "q")

      is_binary(Map.get(params, :text)) ->
        Map.get(params, :text)

      is_binary(Map.get(params, "text")) ->
        Map.get(params, "text")

      true ->
        Map.get(params, :q) || Map.get(params, "q") || Map.get(params, :text) ||
          Map.get(params, "text")
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

  defp fetch_map_value(map, key) when is_map(map),
    do: Map.get(map, key) || Map.get(map, safe_existing_atom(key))

  defp safe_existing_atom(value) when is_atom(value), do: value

  defp safe_existing_atom(value) when is_binary(value) do
    String.to_existing_atom(value)
  rescue
    ArgumentError -> nil
  end

  defp safe_existing_atom(_value), do: nil

  defp parse_positive_integer(value) when is_integer(value) and value > 0, do: {:ok, value}

  defp parse_positive_integer(value) when is_binary(value) do
    case Integer.parse(value) do
      {int, ""} when int > 0 -> {:ok, int}
      _ -> :error
    end
  end

  defp parse_positive_integer(_value), do: :error

  defp key_allowed?(key, allowed) when is_atom(key),
    do: MapSet.member?(allowed, Atom.to_string(key))

  defp key_allowed?(key, allowed) when is_binary(key), do: MapSet.member?(allowed, key)
  defp key_allowed?(_key, _allowed), do: false

  defp key_segment(key) when is_atom(key), do: key

  defp key_segment(key) when is_binary(key) do
    safe_existing_atom(key) || key
  end

  defp key_segment(key), do: key

  defp canonical_page_keyword(page) when is_map(page) do
    @page_keys
    |> Enum.reduce([], fn key, pairs ->
      case Map.fetch(page, key) do
        {:ok, value} -> pairs ++ [{key, value}]
        :error -> pairs
      end
    end)
  end

  defp canonical_page_keyword(page) when is_list(page) do
    @page_keys
    |> Enum.reduce([], fn key, pairs ->
      case Keyword.fetch(page, key) do
        {:ok, value} -> pairs ++ [{key, value}]
        :error -> pairs
      end
    end)
  end

  defp sort_keyword_pairs(pairs) do
    Enum.sort_by(pairs, fn {key, _value} -> Atom.to_string(key) end)
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
