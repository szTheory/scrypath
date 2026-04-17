defmodule Scrypath do
  @moduledoc """
  Runtime reflection helpers for searchable schemas declared with `use Scrypath`.

  Phase 1 keeps the public runtime surface small:

  - `schema_config/1`
  - `schema_fields/1`
  - `schema_settings/1`
  - `schema_faceting/1`
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

  @doc """
  Returns normalized `faceting:` options for the schema, or `[]` when faceting is disabled.

  Shape when enabled is a keyword list with `:attributes`, `:max_values_per_facet`, and
  `:sort_facet_values_by`.
  """
  @spec schema_faceting(module()) :: keyword()
  def schema_faceting(schema_module) do
    schema_module.__scrypath__(:faceting)
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

  @doc """
  Federated search across multiple schemas.

  Returns an ok tuple whose success value is the library's federated multi-search
  result struct, or an error tuple on validation, transport, or complete failure.
  """
  @spec search_many(list(), keyword()) :: {:ok, term()} | {:error, term()}
  def search_many(entries, opts \\ []) do
    Scrypath.Search.search_many(entries, opts)
  end

  @spec search_many!(list(), keyword()) :: term()
  def search_many!(entries, opts \\ []) do
    Scrypath.Search.search_many!(entries, opts)
  end

  @spec backfill(module(), keyword()) :: {:ok, map()} | {:error, term()}
  def backfill(schema_module, opts \\ []) do
    Scrypath.Backfill.run(schema_module, opts)
  end

  @spec reindex(module(), keyword()) :: {:ok, map()} | {:error, term()}
  def reindex(schema_module, opts \\ []) do
    Scrypath.Reindex.run(schema_module, opts)
  end

  @spec sync_status(module(), keyword()) ::
          {:ok, Scrypath.Operator.Status.t()} | {:error, term()}
  def sync_status(schema_module, opts \\ []) do
    Scrypath.Operator.sync_status(schema_module, opts)
  end

  @doc """
  Returns failed or retrying sync work rows for a schema.

  ## Reason class rollups

  Pass **`reason_class_counts: true`** in operator options (alongside runtime
  config) to receive **`{:ok, %Scrypath.Operator.FailedSyncWorkInspection{}}`**
  with **`entries`** (the row list) and **`counts`** — a
  **`%Scrypath.Operator.ReasonClassCounts{}`** with dense per-class frequencies.
  The default remains **`{:ok, [FailedWork.t()]}`** when this option is omitted.
  """
  @spec failed_sync_work(module(), keyword()) ::
          {:ok, [Scrypath.Operator.FailedWork.t()]}
          | {:ok, Scrypath.Operator.FailedSyncWorkInspection.t()}
          | {:error, term()}
  def failed_sync_work(schema_module, opts \\ []) do
    Scrypath.Operator.failed_sync_work(schema_module, opts)
  end

  @spec retry_sync_work(
          Scrypath.Operator.FailedWork.t() | Scrypath.Operator.RecoveryAction.t(),
          keyword()
        ) ::
          {:ok, map()} | {:error, term()}
  def retry_sync_work(work_or_action, opts \\ []) do
    Scrypath.Operator.retry_sync_work(work_or_action, opts)
  end

  @spec reconcile_sync(module(), keyword()) ::
          {:ok, Scrypath.Operator.Reconcile.t()} | {:error, term()} | {:ok, map()}
  def reconcile_sync(schema_module, opts \\ []) do
    Scrypath.Operator.reconcile_sync(schema_module, opts)
  end
end
