defmodule Scrypath do
  @moduledoc """
  Runtime reflection helpers for searchable schemas declared with `use Scrypath`.

  Phase 1 keeps the public runtime surface small:

  - `schema_config/1`
  - `schema_fields/1`
  - `schema_settings/1`
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

  @spec schema_settings(module()) :: map()
  def schema_settings(schema_module) do
    schema_module.__scrypath__(:settings)
  end

  @spec document_source(module()) :: atom()
  def document_source(schema_module) do
    Scrypath.Projection.document_source(schema_module)
  end

  @spec document_id_field(module()) :: atom()
  def document_id_field(schema_module) do
    schema_module.__scrypath__(:document_id)
  end

  @spec sync_record(module(), struct() | map(), keyword()) :: {:ok, term()} | {:error, term()}
  def sync_record(schema_module, record, opts \\ []) do
    Scrypath.Sync.sync_record(schema_module, record, opts)
  end

  @spec sync_records(module(), [struct() | map()], keyword()) :: {:ok, term()} | {:error, term()}
  def sync_records(schema_module, records, opts \\ []) do
    Scrypath.Sync.sync_records(schema_module, records, opts)
  end

  @spec delete_record(module(), struct() | map(), keyword()) :: {:ok, term()} | {:error, term()}
  def delete_record(schema_module, record, opts \\ []) do
    Scrypath.Sync.delete_record(schema_module, record, opts)
  end

  @spec delete_document(module(), term(), keyword()) :: {:ok, term()} | {:error, term()}
  def delete_document(schema_module, document_id, opts \\ []) do
    Scrypath.Sync.delete_document(schema_module, document_id, opts)
  end

  @spec delete_documents(module(), [term()], keyword()) :: {:ok, term()} | {:error, term()}
  def delete_documents(schema_module, document_ids, opts \\ []) do
    Scrypath.Sync.delete_documents(schema_module, document_ids, opts)
  end

  @spec search(module(), String.t(), keyword()) :: {:ok, term()} | {:error, term()}
  def search(schema_module, text, opts \\ []) do
    Scrypath.Search.search(schema_module, text, opts)
  end

  @spec search!(module(), String.t(), keyword()) :: term()
  def search!(schema_module, text, opts \\ []) do
    Scrypath.Search.search!(schema_module, text, opts)
  end
end
