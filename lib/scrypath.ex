defmodule Scrypath do
  @moduledoc """
  Runtime reflection helpers for searchable schemas declared with `use Scrypath`.

  The initial public reflection surface is intentionally small:

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

  See also **`search_within_facet/4`** in **`guides/faceted-search-with-phoenix-liveview.md`**
  for searching inside a facet bucket alongside `filter:` / `facet_filter:` composition.
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

  @doc """
  Primary hydrated search entry: validates options, resolves runtime config, and
  returns `{:ok, %Scrypath.SearchResult{}}` or tagged `{:error, _}` failures from
  the configured backend. Work is wrapped in a Telemetry span **`[:scrypath, :search]`**
  with metadata from `Scrypath.Telemetry.common_metadata/3`.

  Full pipeline: see [guides/per-query-tuning-pipeline.md](guides/per-query-tuning-pipeline.md).

  Optional **`:per_query`** is an allowlisted keyword for Plane B Meilisearch search
  parameters on the v1.9 slice (for example `ranking_score_threshold`,
  `show_ranking_score`, and `show_ranking_score_details`); semantics and telemetry
  expectations are defined in
  [guides/per-query-tuning-pipeline.md](guides/per-query-tuning-pipeline.md).

  ## Errors vs raises

  * **`ArgumentError`** — some invalid shapes are rejected synchronously (mirrors
    `Scrypath.Search.search/3`).
  * **`{:error, reason}`** — operational failures, including backend errors and
    tuples such as `{:transport_failed, _}`, for callers that want to branch.

  `search!/3` raises `Scrypath.Search.Error` with the same `reason` instead of returning
  `{:error, _}`.
  """
  @spec search(module(), String.t(), keyword()) :: {:ok, term()} | {:error, term()}
  def search(schema_module, text, opts \\ []) do
    Scrypath.Search.search(schema_module, text, opts)
  end

  @doc """
  Like `search/3`, but returns a `%Scrypath.SearchResult{}` or raises `Scrypath.Search.Error`
  when the non-bang API would return `{:error, _}`.
  """
  @spec search!(module(), String.t(), keyword()) :: term()
  def search!(schema_module, text, opts \\ []) do
    Scrypath.Search.search!(schema_module, text, opts)
  end

  @doc """
  Full-text search scoped to a single facet bucket, **AND**-combined with any other
  `filter:`, `facet_filter:`, sort, and pagination options.

  `facet_bucket` is `{facet_attribute, value}` where `value` is either a scalar
  (one bucket) or a list interpreted as **OR** within that attribute, matching
  `facet_filter:` encoding. Passing the same attribute again under `facet_filter:`
  is rejected with `ArgumentError` — use `search/3` or keep only one source of truth.

  ## Errors vs raises

  * **`ArgumentError`** — structural misuse of the facet bucket or duplicate facet locks.
  * **`{:error, reason}`** — same operational `{:error, _}` family as `search/3`.

  `search_within_facet!/4` raises `Scrypath.Search.Error` when the non-bang call would
  return `{:error, _}`.
  """
  @spec search_within_facet(module(), String.t(), {atom(), term() | list()}, keyword()) ::
          {:ok, term()} | {:error, term()}
  def search_within_facet(schema_module, text, facet_bucket, opts \\ []) do
    Scrypath.Search.search_within_facet(schema_module, text, facet_bucket, opts)
  end

  @spec search_within_facet!(module(), String.t(), {atom(), term() | list()}, keyword()) ::
          term()
  def search_within_facet!(schema_module, text, facet_bucket, opts \\ []) do
    Scrypath.Search.search_within_facet!(schema_module, text, facet_bucket, opts)
  end

  @doc """
  Full pipeline: see [guides/per-query-tuning-pipeline.md](guides/per-query-tuning-pipeline.md).

  **`search_many/2`** merge rules for shared vs per-entry options, `:all` expansion,
  and federation payloads remain canonical in **`guides/multi-index-search.md`**.

  **`:per_query`** may appear on **shared** keywords and on each per-entry tuple; when
  both sides supply it, inner keys shallow-merge with entry bias — see
  [guides/per-query-tuning-pipeline.md](guides/per-query-tuning-pipeline.md).

  Federated search across multiple schemas.

  Entries mirror `search/3` tuples; optional **`federation_weight:`** tunes
  Meilisearch merge ordering for that row and requires a backend that implements
  `search_many/2`. Invalid weights use `{:invalid_options, {:federation_weight, _}}`;
  backends without native multi-search return
  `{:invalid_options, {:federation_merge_requires_native_search_many, %{backend: _}}}`.

  Successful responses are `{:ok, %Scrypath.MultiSearchResult{}}` with
  per-schema `Scrypath.SearchResult` structs. When the backend returns a flat
  federated `hits` list, `merge_hit_order` may be populated and
  `Scrypath.MultiSearchResult.merge_projection/1` exposes `{schema, hit_map}` pairs
  in merge order; otherwise `merge_hit_order` is `nil`.

  See also **`guides/multi-index-search.md`** § **Federation weights**.

  ## Errors vs raises

  * **`{:error, reason}`** — preflight and transport failures you should branch on
    (`{:invalid_options, _}`, `{:validation_failed, _, _}`, `{:transport_failed, _}`, …).
  * **`search_many!/2`** raises `Scrypath.Search.Error` with the same `reason` instead of
    returning `{:error, _}`.
  """
  @spec search_many(list(), keyword()) :: {:ok, term()} | {:error, term()}
  def search_many(entries, opts \\ []) do
    Scrypath.Search.search_many(entries, opts)
  end

  @doc """
  Like `search_many/2`, but returns `%Scrypath.MultiSearchResult{}` or raises
  `Scrypath.Search.Error` when the non-bang API would return `{:error, _}`.
  """
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

  @doc """
  Report-first reconciliation for a schema (sync visibility, failed work, drift
  signals, and suggested recovery actions).

  ## Index contract drift

  Pass **`include_index_contract_drift: true`** alongside runtime options to
  attach a read-only `%Scrypath.Operator.IndexContractDrift.Report{}` on
  **`index_contract_drift`**. This performs an extra Meilisearch **`get_settings`**
  read using the same builder as `index_contract_drift/2`. Omit the flag (default)
  to avoid that latency and live dependency.
  """
  @spec reconcile_sync(module(), keyword()) ::
          {:ok, Scrypath.Operator.Reconcile.t()} | {:error, term()} | {:ok, map()}
  def reconcile_sync(schema_module, opts \\ []) do
    Scrypath.Operator.reconcile_sync(schema_module, opts)
  end

  @doc """
  Read-only **index contract drift** report for a searchable schema.

  Compares declared schema metadata and resolved settings against a single live
  Meilisearch `GET /indexes/{uid}/settings` snapshot. This is a **report-first**
  operator surface: it does not enqueue work, mutate indexes, or imply recovery
  actions. It is **not** the same signal family as `reconcile_sync/2`'s
  `drift_signals`, which reflects sync queue and reindex posture.

  See `include_index_contract_drift: true` on `reconcile_sync/2` when you want the
  same report attached to a reconcile tuple (adds one `get_settings` read).
  """
  @spec index_contract_drift(module(), keyword()) ::
          {:ok, Scrypath.Operator.IndexContractDrift.Report.t()} | {:error, term()}
  def index_contract_drift(schema_module, opts \\ []) do
    Scrypath.Operator.index_contract_drift(schema_module, opts)
  end
end
