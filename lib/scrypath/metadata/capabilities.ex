defmodule Scrypath.Metadata.Capabilities do
  @moduledoc false

  alias Scrypath.Options

  @paging_fields [:number, :size]

  @spec schema_capabilities(module()) :: map()
  def schema_capabilities(schema_module) when is_atom(schema_module) do
    faceting = Scrypath.Schema.Metadata.faceting(schema_module)
    facet_attributes = Keyword.get(faceting, :attributes, [])

    %{
      tenant: Scrypath.Schema.Metadata.tenant_field(schema_module),
      filters: %{
        supported: Scrypath.Schema.Metadata.filterable(schema_module) != [],
        fields: Scrypath.Schema.Metadata.filterable(schema_module)
      },
      sorts: %{
        supported: Scrypath.Schema.Metadata.sortable(schema_module) != [],
        fields: Scrypath.Schema.Metadata.sortable(schema_module)
      },
      facets: %{
        supported: facet_attributes != [],
        fields: facet_attributes,
        max_values_per_facet: Keyword.get(faceting, :max_values_per_facet),
        sort_facet_values_by:
          normalize_sort_facet_values_by(Keyword.get(faceting, :sort_facet_values_by, []))
      },
      paging: %{
        supported: true,
        fields: @paging_fields
      },
      limits: %{
        per_query_keys: Options.per_query_allowlist(),
        max_values_per_facet: Keyword.get(faceting, :max_values_per_facet)
      }
    }
  end

  defp normalize_sort_facet_values_by(value) when value == %{}, do: []
  defp normalize_sort_facet_values_by(value), do: value
end
