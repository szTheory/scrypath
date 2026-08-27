defmodule Scrypath.Schema.Metadata do
  @moduledoc false

  @type key ::
          :config
          | :fields
          | :filterable
          | :faceting
          | :sortable
          | :settings
          | :document_id
          | :document_source
          | :backend
          | :tenant_field
          | :fan_outs

  @spec fetch!(module(), key()) :: term()
  def fetch!(schema_module, key) when is_atom(schema_module) and is_atom(key) do
    schema_module.__scrypath__(key)
  end

  @spec config(module()) :: map()
  def config(schema_module), do: fetch!(schema_module, :config)

  @spec fields(module()) :: [atom()]
  def fields(schema_module), do: fetch!(schema_module, :fields)

  @spec filterable(module()) :: [atom()]
  def filterable(schema_module), do: fetch!(schema_module, :filterable)

  @spec faceting(module()) :: keyword()
  def faceting(schema_module), do: fetch!(schema_module, :faceting)

  @spec sortable(module()) :: [atom()]
  def sortable(schema_module), do: fetch!(schema_module, :sortable)

  @spec settings(module()) :: map()
  def settings(schema_module), do: fetch!(schema_module, :settings)

  @spec document_id(module()) :: atom()
  def document_id(schema_module), do: fetch!(schema_module, :document_id)

  @spec tenant_field(module()) :: atom() | nil
  def tenant_field(schema_module), do: fetch!(schema_module, :tenant_field)

  @spec fan_outs(module()) :: list()
  def fan_outs(schema_module), do: fetch!(schema_module, :fan_outs)
end
