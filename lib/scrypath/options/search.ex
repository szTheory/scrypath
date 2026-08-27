defmodule Scrypath.Options.Search do
  @moduledoc false

  alias Scrypath.Schema.Metadata

  @spec validate(module(), keyword(), keyword(), [atom()]) :: {:ok, keyword()} | {:error, term()}
  def validate(schema_module, opts, option_schema, runtime_keys) do
    filterable = MapSet.new(Metadata.filterable(schema_module))
    sortable = MapSet.new(Metadata.sortable(schema_module))
    search_opts = Keyword.drop(opts, runtime_keys)

    with {:ok, validated} <- nimble_options_result(option_schema, search_opts),
         :ok <- validate_facets(schema_module, Keyword.get(validated, :facets, [])),
         :ok <- validate_facet_filter(schema_module, Keyword.get(validated, :facet_filter, [])) do
      try do
        validated
        |> inject_tenant_scope!(schema_module)
        |> validate_filterable_fields!(filterable)
        |> validate_sortable_fields!(sortable)
        |> then(&{:ok, &1})
      rescue
        error in ArgumentError -> {:error, {:validation, Exception.message(error)}}
      end
    end
  end

  defp nimble_options_result(schema, opts) do
    case NimbleOptions.validate(opts, schema) do
      {:ok, validated} ->
        {:ok, validated}

      {:error, %NimbleOptions.ValidationError{} = error} ->
        {:error, {:invalid_options, error.key, Exception.message(error)}}
    end
  end

  defp validate_facets(schema_module, facets) do
    declared = faceting_attributes(schema_module)

    cond do
      facets == [] -> :ok
      declared == [] -> {:error, {:unknown_facet, hd(facets)}}
      bad = Enum.find(facets, &(&1 not in declared)) -> {:error, {:unknown_facet, bad}}
      true -> :ok
    end
  end

  defp validate_facet_filter(schema_module, facet_filter) do
    declared = faceting_attributes(schema_module)

    cond do
      facet_filter == [] ->
        :ok

      declared == [] ->
        {:error, {:invalid_facet_filter, :faceting_not_declared}}

      bad = Enum.find(Keyword.keys(facet_filter), &(&1 not in declared)) ->
        {:error, {:invalid_facet_filter, {:unknown_facet_field, bad}}}

      true ->
        :ok
    end
  end

  defp faceting_attributes(schema_module) do
    case Metadata.faceting(schema_module) do
      [] -> []
      faceting -> Keyword.get(faceting, :attributes, [])
    end
  end

  defp inject_tenant_scope!(opts, schema_module) do
    case Keyword.fetch(opts, :tenant_scope) do
      :error ->
        opts

      {:ok, tenant_scope} ->
        tenant_field = Metadata.tenant_field(schema_module)

        if is_nil(tenant_field) do
          raise ArgumentError,
                "tenant_scope: provided but schema #{inspect(schema_module)} does not declare a tenant_field:"
        end

        existing = Keyword.get(opts, :filter, [])

        if Keyword.has_key?(existing, tenant_field) do
          raise ArgumentError,
                "tenant_scope: cannot be used because filter: already contains the tenant_field #{inspect(tenant_field)}. Remove it from filter: to allow tenant enforcement."
        end

        opts
        |> Keyword.delete(:tenant_scope)
        |> Keyword.put(:filter, Keyword.put(existing, tenant_field, tenant_scope))
    end
  end

  defp validate_filterable_fields!(opts, filterable) do
    filter = opts |> Keyword.get(:filter, []) |> Enum.map(&validate_filter_entry!(&1, filterable))
    Keyword.put(opts, :filter, filter)
  end

  defp validate_sortable_fields!(opts, sortable) do
    sort = opts |> Keyword.get(:sort, []) |> Enum.map(&validate_sort_entry!(&1, sortable))
    Keyword.put(opts, :sort, sort)
  end

  defp validate_filter_entry!({operator, _value}, _filterable)
       when operator in [:or, :and, :not] do
    raise ArgumentError, "boolean composition is not supported in common search filters"
  end

  defp validate_filter_entry!({field, value}, filterable) do
    unless MapSet.member?(filterable, field) do
      raise ArgumentError, "filter field #{inspect(field)} is not declared as filterable"
    end

    {field, validate_filter_value!(value)}
  end

  defp validate_filter_value!(value) when is_list(value) do
    unless Keyword.keyword?(value) do
      raise ArgumentError, "range filter operators must be a keyword list"
    end

    Enum.each(value, fn {operator, _operand} ->
      unless operator in [:eq, :gt, :gte, :lt, :lte] do
        raise ArgumentError, "unsupported filter operator #{inspect(operator)}"
      end
    end)

    value
  end

  defp validate_filter_value!(value), do: value

  defp validate_sort_entry!({direction, field}, sortable) when direction in [:asc, :desc] do
    unless MapSet.member?(sortable, field) do
      raise ArgumentError, "sort field #{inspect(field)} is not declared as sortable"
    end

    {direction, field}
  end

  defp validate_sort_entry!({direction, _field}, _sortable) do
    raise ArgumentError, "sort direction must be :asc or :desc, got #{inspect(direction)}"
  end
end
