defmodule Scrypath.Phoenix do
  @moduledoc """
  Optional request-edge helpers for Phoenix controllers and LiveView.

  This module stays pure and data-only. It delegates browser-param normalization to
  `Scrypath.QueryParams`, projects attempted values plus issues for rendering, and
  round-trips normalized state back into Plug-friendly query params.

  It does not execute searches, call application contexts, or own socket lifecycle.
  """

  alias Scrypath.QueryParams
  alias Scrypath.QueryParams.Error

  @type form_error :: %{
          optional(:field) => String.t(),
          code: atom(),
          message: String.t(),
          path: [String.t()],
          meta: map()
        }

  @type form_data :: %{
          values: map(),
          params: map(),
          form_errors: [form_error()],
          field_errors: %{optional(String.t()) => [form_error()]},
          errors: [form_error()]
        }

  @doc """
  Delegates request-edge normalization to `Scrypath.QueryParams.normalize/1`.
  """
  @spec from_params(map()) :: {:ok, QueryParams.t()} | {:error, QueryParams.normalize_error_map()}
  def from_params(params) when is_map(params) do
    QueryParams.normalize(params)
  end

  @doc """
  Converts normalized query params back into canonical Plug-friendly params.

  This helper supports only the browser grammar accepted by
  `Scrypath.QueryParams.normalize/1`.
  """
  @spec to_query_params(QueryParams.t()) :: map()
  def to_query_params(%{text: _text} = query_params) do
    if Map.get(query_params, :per_query, %{}) != %{} do
      raise ArgumentError, "per_query is not part of the Phoenix query param grammar"
    end

    %{}
    |> maybe_put("q", blank_to_nil(Map.get(query_params, :text, "")))
    |> maybe_put("page", page_to_params(Map.get(query_params, :page, [])))
    |> maybe_put("facets", facets_to_params(Map.get(query_params, :facets, [])))
    |> maybe_put("filter", field_map_to_params(Map.get(query_params, :filter, [])))
    |> maybe_put("facet_filter", field_map_to_params(Map.get(query_params, :facet_filter, [])))
    |> maybe_put("sort", sort_to_params(Map.get(query_params, :sort, [])))
  end

  @doc """
  Projects normalized query params into attempted values plus renderable issues.
  """
  @spec to_form_data(QueryParams.t()) :: form_data()
  def to_form_data(%{text: _text} = query_params) do
    values = canonicalize_values(to_query_params(query_params))

    %{
      values: values,
      params: values,
      form_errors: [],
      field_errors: %{},
      errors: []
    }
  end

  @doc """
  Projects attempted request params plus structured request-edge issues.
  """
  @spec to_form_data(map(), QueryParams.normalize_error_map()) :: form_data()
  def to_form_data(params, %{form_errors: form_errors, field_errors: field_errors, errors: errors})
      when is_map(params) do
    values = canonicalize_values(params)

    %{
      values: values,
      params: values,
      form_errors: Enum.map(form_errors, &project_error/1),
      field_errors:
        Map.new(field_errors, fn {field, issues} ->
          {Atom.to_string(field), Enum.map(issues, &project_error/1)}
        end),
      errors: Enum.map(errors, &project_error/1)
    }
  end

  defp page_to_params([]), do: nil

  defp page_to_params(page) when is_list(page) do
    page
    |> Enum.into(%{}, fn {key, value} -> {Atom.to_string(key), stringify_scalar(value)} end)
    |> empty_map_to_nil()
  end

  defp facets_to_params([]), do: nil
  defp facets_to_params(facets) when is_list(facets), do: Enum.map(facets, &stringify_scalar/1)

  defp field_map_to_params([]), do: nil

  defp field_map_to_params(fields) when is_list(fields) do
    fields
    |> Enum.into(%{}, fn {key, value} -> {Atom.to_string(key), stringify_value(value)} end)
    |> empty_map_to_nil()
  end

  defp sort_to_params([]), do: nil

  defp sort_to_params([{dir, field}]) when dir in [:asc, :desc] do
    %{"field" => stringify_scalar(field), "dir" => Atom.to_string(dir)}
  end

  defp sort_to_params(sort) when is_list(sort) do
    raise ArgumentError,
          "sort must contain at most one entry for Phoenix query params: #{inspect(sort)}"
  end

  defp canonicalize_values(params) when is_map(params) do
    %{}
    |> Map.put("q", fetch_attempted_query(params))
    |> maybe_put("page", nested_owned_value(params, :page))
    |> maybe_put("facets", list_owned_value(params, :facets))
    |> maybe_put("filter", nested_owned_value(params, :filter))
    |> maybe_put("facet_filter", nested_owned_value(params, :facet_filter))
    |> maybe_put("sort", nested_owned_value(params, :sort))
  end

  defp fetch_attempted_query(params) do
    params
    |> fetch_value(:q, "q", fetch_value(params, :text, "text", ""))
    |> normalize_attempted_scalar()
  end

  defp nested_owned_value(params, atom_key) do
    string_key = Atom.to_string(atom_key)

    case fetch_value(params, atom_key, string_key, nil) do
      nil -> nil
      value -> stringify_nested(value)
    end
  end

  defp list_owned_value(params, atom_key) do
    string_key = Atom.to_string(atom_key)

    case fetch_value(params, atom_key, string_key, nil) do
      nil -> nil
      value -> stringify_nested(value)
    end
  end

  defp stringify_nested(value) when is_map(value) do
    Map.new(value, fn {key, nested} -> {to_string(key), stringify_nested(nested)} end)
  end

  defp stringify_nested(value) when is_list(value), do: Enum.map(value, &stringify_nested/1)
  defp stringify_nested(value), do: normalize_attempted_scalar(value)

  defp normalize_attempted_scalar(nil), do: ""
  defp normalize_attempted_scalar(value) when is_binary(value), do: value
  defp normalize_attempted_scalar(value), do: to_string(value)

  defp stringify_value(value) when is_list(value), do: Enum.map(value, &stringify_scalar/1)
  defp stringify_value(value), do: stringify_scalar(value)

  defp stringify_scalar(value) when is_atom(value), do: Atom.to_string(value)
  defp stringify_scalar(value) when is_binary(value), do: value
  defp stringify_scalar(value), do: to_string(value)

  defp blank_to_nil(""), do: nil
  defp blank_to_nil(value), do: value

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp empty_map_to_nil(map) when map == %{}, do: nil
  defp empty_map_to_nil(map), do: map

  defp fetch_value(params, atom_key, string_key, default) do
    cond do
      Map.has_key?(params, atom_key) -> Map.get(params, atom_key)
      Map.has_key?(params, string_key) -> Map.get(params, string_key)
      true -> default
    end
  end

  defp project_error(%Error{} = error) do
    base = %{
      code: error.code,
      message: error.message,
      path: Enum.map(error.path, &to_string/1),
      meta: error.meta
    }

    case error.field do
      nil -> base
      field -> Map.put(base, :field, Atom.to_string(field))
    end
  end
end
