defmodule Scrypath.Operator.IndexContractDrift do
  @moduledoc false

  alias Scrypath.Config
  alias Scrypath.Meilisearch.Client
  alias Scrypath.Meilisearch.Settings
  alias Scrypath.Operator.IndexContractDrift.Report
  alias Scrypath.Operator.IndexContractDrift.Report.Dimension

  @list_compare_cap 50

  @spec build(module(), keyword()) :: {:ok, Report.t()} | {:error, term()}
  def build(schema_module, config) when is_list(config) do
    case Config.fetch_backend!(config) do
      Scrypath.Meilisearch ->
        build_meilisearch(schema_module, config)

      _other ->
        {:error, :unsupported_backend}
    end
  end

  defp build_meilisearch(schema_module, config) do
    index = Scrypath.Meilisearch.index_name(schema_module, config)
    client = client_mod(config)

    case client.get_settings(index, config) do
      {:error, {:http_error, 404, _body}} ->
        {:error, :index_not_found}

      {:error, _} = err ->
        err

      {:ok, applied_wire} ->
        {:ok, assemble_report(schema_module, index, config, applied_wire)}
    end
  end

  defp client_mod(config), do: Keyword.get(config, :meilisearch_client) || Client

  defp assemble_report(schema_module, index, config, applied_wire) do
    declared_wire =
      schema_module
      |> Settings.resolve(config)
      |> Settings.translate_settings()

    %Report{
      version: 1,
      schema: schema_module,
      index: index,
      dimensions: %{
        fields: compare_fields(schema_module, declared_wire, applied_wire),
        filterable_attributes: compare_filterable(schema_module, applied_wire),
        sortable_attributes: compare_sortable(schema_module, applied_wire),
        faceting: compare_faceting(schema_module, applied_wire),
        settings: compare_settings(declared_wire, applied_wire)
      }
    }
  end

  defp compare_fields(schema_module, declared_wire, applied_wire) do
    searchable = Map.get(declared_wire, "searchableAttributes")

    declared =
      (searchable || Scrypath.Schema.Metadata.fields(schema_module))
      |> Enum.map(&to_string/1)
      |> MapSet.new()

    applied =
      applied_wire
      |> Map.get("searchableAttributes", [])
      |> List.wrap()
      |> Enum.map(&to_string/1)
      |> MapSet.new()

    # The backend default searches every projected field. Explicit restrictions
    # still compare literally; their ranking order is checked by the settings axis.
    if is_nil(searchable) and MapSet.equal?(applied, MapSet.new(["*"])) do
      Dimension.new(true, [])
    else
      set_dimension(declared, applied)
    end
  end

  defp compare_filterable(schema_module, applied_wire) do
    declared =
      schema_module
      |> schema_call(:filterable)
      |> List.wrap()
      |> filterable_declared_names()
      |> MapSet.new()

    applied =
      applied_wire
      |> Map.get("filterableAttributes", [])
      |> List.wrap()
      |> filterable_applied_names()
      |> MapSet.new()

    set_dimension(declared, applied)
  end

  defp compare_sortable(schema_module, applied_wire) do
    declared =
      schema_module
      |> schema_call(:sortable)
      |> List.wrap()
      |> Enum.map(&Atom.to_string/1)
      |> MapSet.new()

    applied =
      applied_wire
      |> Map.get("sortableAttributes", [])
      |> List.wrap()
      |> Enum.map(&to_string/1)
      |> MapSet.new()

    set_dimension(declared, applied)
  end

  defp compare_faceting(schema_module, applied_wire) do
    declared = faceting_declared_wire(Scrypath.Schema.Metadata.faceting(schema_module))

    # Facet membership is part of filterableAttributes, not the faceting object.
    # Other filterables (for example tenant IDs) need not be declared facets.
    applied_attributes =
      applied_wire
      |> Map.get("filterableAttributes", [])
      |> List.wrap()
      |> filterable_applied_names()
      |> Enum.filter(&(&1 in declared["attributes"]))
      |> Enum.uniq()
      |> Enum.sort()

    applied =
      applied_wire
      |> Map.get("faceting")
      |> faceting_applied_wire()
      |> Map.put("attributes", applied_attributes)

    if declared == applied do
      Dimension.new(true, [])
    else
      Dimension.new(false, [%{declared: declared, applied: applied}])
    end
  end

  defp compare_settings(declared_wire, applied_wire) do
    case Settings.compute_drift(declared_wire, applied_wire) do
      [] ->
        Dimension.new(true, [])

      tuples when is_list(tuples) ->
        details =
          Enum.map(tuples, fn {key, declared, applied} ->
            %{key: key, declared: declared, applied: applied}
          end)

        Dimension.new(false, details)
    end
  end

  defp schema_call(schema_module, key), do: Scrypath.Schema.Metadata.fetch!(schema_module, key)

  defp filterable_declared_names(list) do
    Enum.map(list, fn
      a when is_atom(a) -> Atom.to_string(a)
      b when is_binary(b) -> b
    end)
  end

  defp filterable_applied_names(list) do
    Enum.flat_map(list, fn
      s when is_binary(s) ->
        [s]

      a when is_atom(a) ->
        [Atom.to_string(a)]

      %{} = m ->
        patterns = Map.get(m, "attributePatterns") || Map.get(m, :attribute_patterns)

        cond do
          is_list(patterns) ->
            Enum.filter(patterns, &is_binary/1)

          is_binary(Map.get(m, "attribute")) ->
            [Map.get(m, "attribute")]

          is_binary(Map.get(m, :attribute)) ->
            [Map.get(m, :attribute)]

          is_atom(Map.get(m, :attribute)) ->
            [Atom.to_string(Map.get(m, :attribute))]

          true ->
            []
        end

      _ ->
        []
    end)
  end

  defp faceting_declared_wire(kw) when is_list(kw) do
    attrs =
      kw
      |> Keyword.get(:attributes, [])
      |> Enum.map(&Atom.to_string/1)
      |> Enum.sort()

    maxv = Keyword.get(kw, :max_values_per_facet, 100)
    sort_by = Keyword.get(kw, :sort_facet_values_by, %{})

    %{
      "attributes" => attrs,
      "maxValuesPerFacet" => maxv,
      "sortFacetValuesBy" => normalize_facet_sort(sort_by)
    }
  end

  defp faceting_applied_wire(nil), do: faceting_applied_wire(%{})

  defp faceting_applied_wire(%{} = m) do
    %{
      "maxValuesPerFacet" => Map.get(m, "maxValuesPerFacet", 100),
      "sortFacetValuesBy" => normalize_facet_sort(Map.get(m, "sortFacetValuesBy") || %{})
    }
  end

  defp normalize_facet_sort(sort_by) do
    sort_by
    |> Map.new(fn {k, v} -> {to_string(k), facet_sort_applied(v)} end)
    |> Map.put_new("*", "alpha")
  end

  defp facet_sort_applied(v) when v in ["alpha", "count"], do: v

  defp facet_sort_applied(v) when is_atom(v) do
    case v do
      :alpha -> "alpha"
      :count -> "count"
      _ -> Atom.to_string(v)
    end
  end

  defp facet_sort_applied(v), do: to_string(v)

  defp set_dimension(declared_ms, applied_ms) do
    if MapSet.equal?(declared_ms, applied_ms) do
      Dimension.new(true, [])
    else
      details = symmetric_diff_details(declared_ms, applied_ms, @list_compare_cap)
      Dimension.new(false, details)
    end
  end

  defp symmetric_diff_details(declared_ms, applied_ms, cap) do
    only_d = MapSet.difference(declared_ms, applied_ms)
    only_a = MapSet.difference(applied_ms, declared_ms)

    d_entries = Enum.map(only_d, &{:only_declared, &1})
    a_entries = Enum.map(only_a, &{:only_applied, &1})
    combined = d_entries ++ a_entries

    if length(combined) > cap do
      combined
      |> Enum.take(cap)
      |> Kernel.++([{:truncated, true}])
    else
      combined
    end
  end
end
