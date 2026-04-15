defmodule Scrypath do
  @moduledoc false

  defmacro __using__(opts) do
    quote do
      use Scrypath.Schema, unquote(opts)
    end
  end

  @spec schema_config(module()) :: map()
  def schema_config(schema_module) do
    schema_module.__scrypath__(:config)
  end

  @spec schema_fields(module()) :: [atom()]
  def schema_fields(schema_module) do
    schema_module.__scrypath__(:fields)
  end

  @spec document_source(module()) :: atom()
  def document_source(schema_module) do
    Scrypath.Projection.document_source(schema_module)
  end

  @spec document_id_field(module()) :: atom()
  def document_id_field(schema_module) do
    schema_module.__scrypath__(:document_id)
  end
end
