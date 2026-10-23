defmodule ScrypathOps.SavedSearches.DocResolver do
  @moduledoc """
  Resolves operator-facing documentation URLs for saved search run outcomes.
  """

  @default_base "https://github.com/szTheory/scrypath/blob/main/"

  @doc_paths %{
    saved_search_schema: %{
      primary: "scrypath_ops/docs/saved-search-schema-v1.md",
      related: ["scrypath_ops/docs/team-saved-search-persistence.md"]
    },
    saved_search_schema_no_schema: %{
      primary: "scrypath_ops/docs/saved-search-schema-v1.md#no_schema",
      related: [
        "scrypath_ops/docs/team-saved-search-persistence.md",
        "guides/multi-index-search.md"
      ]
    },
    saved_search_schema_invalid_query: %{
      primary: "scrypath_ops/docs/saved-search-schema-v1.md#invalid_query",
      related: ["guides/multi-index-search.md"]
    },
    saved_search_schema_invalid_entries: %{
      primary: "scrypath_ops/docs/saved-search-schema-v1.md#invalid_entries",
      related: ["guides/multi-index-search.md"]
    },
    saved_search_schema_invalid_entry_shape: %{
      primary: "scrypath_ops/docs/saved-search-schema-v1.md#invalid_entry_shape",
      related: ["guides/multi-index-search.md"]
    },
    saved_search_schema_page_size: %{
      primary: "scrypath_ops/docs/saved-search-schema-v1.md#page_size_out_of_range",
      related: [
        "guides/multi-index-search.md",
        "scrypath_ops/docs/team-saved-search-persistence.md"
      ]
    },
    saved_search_troubleshooting: %{
      primary: "scrypath_ops/docs/saved-search-schema-v1.md#troubleshooting",
      related: [
        "scrypath_ops/docs/team-saved-search-persistence.md",
        "guides/multi-index-search.md"
      ]
    },
    saved_search_operator_config: %{
      primary: "scrypath_ops/README.md",
      related: [
        "scrypath_ops/docs/team-saved-search-persistence.md",
        "guides/multi-index-search.md"
      ]
    }
  }

  @type doc_ref :: atom()

  @spec resolve(doc_ref()) :: %{primary: String.t(), related: [String.t()]}
  def resolve(doc_ref) when is_atom(doc_ref) do
    %{primary: primary, related: related} =
      Map.get(@doc_paths, doc_ref, Map.fetch!(@doc_paths, :saved_search_troubleshooting))

    %{
      primary: absolute_url(primary),
      related:
        related
        |> Enum.take(2)
        |> Enum.map(&absolute_url/1)
    }
  end

  def url(doc_ref), do: resolve(doc_ref)

  defp absolute_url(path) do
    base =
      Application.get_env(:scrypath_ops, :saved_search_doc_base, @default_base)
      |> to_string()
      |> ensure_trailing_slash()

    base <> path
  end

  defp ensure_trailing_slash(base) do
    if String.ends_with?(base, "/"), do: base, else: base <> "/"
  end
end
