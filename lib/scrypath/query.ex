defmodule Scrypath.Query do
  @moduledoc """
  **`%Scrypath.Query{}` is internal normalized query state** produced by the common search
  path before a backend sees it. It is **not** a semver-stable pattern-match target for
  application code—callers should build options as keywords for `Scrypath.search/3` and treat
  this struct as an implementation detail behind `Scrypath.Meilisearch.Query` (or other
  adapters).
  """

  @enforce_keys [:text]
  defstruct text: nil,
            filter: [],
            sort: [],
            page: %{},
            facets: [],
            facet_filter: [],
            per_query: %{}

  @typedoc """
  Normalized pagination: `:number` is the 1-based page index, `:size` is the page size cap.
  """
  @type page_t :: %{optional(:number) => pos_integer(), optional(:size) => pos_integer()}

  @typedoc "Meilisearch filter list after normalization (keyword of attribute predicates)."
  @type filter_t :: keyword()

  @typedoc "Meilisearch sort list after normalization (`[{attribute, direction}]`)."
  @type sort_t :: keyword()

  @typedoc "Facet attribute names requested on the query."
  @type facets_t :: [atom()]

  @typedoc "Per-attribute facet bucket filters (`facet_filter:` keyword)."
  @type facet_filter_t :: keyword()

  @typedoc """
  Internal query bundle: full-text string plus normalized filter, sort, facet, and per-query
  slices. Field shapes mirror allowlisted `Scrypath.search/3` options after validation.
  """
  @type t :: %__MODULE__{
          text: String.t(),
          filter: filter_t(),
          sort: sort_t(),
          page: page_t(),
          facets: facets_t(),
          facet_filter: facet_filter_t(),
          per_query: map()
        }

  @spec new(String.t(), keyword()) :: t()
  def new(text, opts) when is_binary(text) and is_list(opts) do
    %__MODULE__{
      text: text,
      filter: Keyword.get(opts, :filter, []),
      sort: Keyword.get(opts, :sort, []),
      page: normalize_page(Keyword.get(opts, :page, %{})),
      facets: Keyword.get(opts, :facets, []),
      facet_filter: Keyword.get(opts, :facet_filter, []),
      per_query: Keyword.get(opts, :per_query, %{})
    }
  end

  defp normalize_page(page) when is_map(page), do: page
  defp normalize_page(page) when is_list(page), do: Enum.into(page, %{})
end
