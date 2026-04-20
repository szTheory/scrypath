defmodule Scrypath.Backend do
  @moduledoc """
  Internal backend behavior for Scrypath runtime adapters.

  This behavior is documented so architecture references remain valid, but it is
  still considered an internal seam for v1 rather than a stable extension API.
  """

  alias Scrypath.Document
  alias Scrypath.Query

  @callback name() :: atom()
  @callback index_name(module(), keyword()) :: String.t()
  @callback upsert_documents(module(), [Document.t()], keyword()) ::
              {:ok, term()} | {:error, term()}
  @callback delete_documents(module(), [term()], keyword()) ::
              {:ok, term()} | {:error, term()}
  @callback search(module(), Query.t(), keyword()) :: {:ok, map()} | {:error, term()}

  @doc """
  Optional federated multi-search over multiple schemas in one HTTP round-trip.

  Each row is `{schema_module, %Scrypath.Query{}, fed_opts}` where `fed_opts` is a
  keyword list that is usually `[]`. In v1.8 only `:federation_weight` is
  defined (a finite float) for per-query merge weights on federated backends.

  Implementations return **raw** Meilisearch JSON maps (string keys) before
  the search layer decorates them into structs.
  """
  @callback search_many([{module(), Query.t(), keyword()}], keyword()) ::
              {:ok, map()} | {:error, term()}

  @optional_callbacks [search_many: 2]
end
