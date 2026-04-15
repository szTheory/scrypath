defmodule Scrypath do
  @moduledoc """
  Runtime reflection helpers for searchable schemas declared with `use Scrypath`.

  Phase 1 keeps the public runtime surface small:

  - `schema_config/1`
  - `schema_fields/1`
  - `document_source/1`
  - `document_id_field/1`

  These functions keep reflection under `Scrypath.*` modules instead of generating
  schema-specific runtime verbs.

  ## Examples

      iex> config = Scrypath.schema_config(SearchablePost)
      iex> config.fields
      [:title, :body]
  """

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
