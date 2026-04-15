defmodule Scrypath.Backend do
  @moduledoc false

  alias Scrypath.Document

  @callback name() :: atom()
  @callback index_name(module(), keyword()) :: String.t()
  @callback upsert_documents(module(), [Document.t()], keyword()) ::
              {:ok, term()} | {:error, term()}
  @callback delete_documents(module(), [term()], keyword()) ::
              {:ok, term()} | {:error, term()}
  @callback search(module(), term(), keyword()) :: {:ok, term()} | {:error, term()}
end
