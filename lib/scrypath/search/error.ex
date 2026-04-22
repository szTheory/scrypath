defmodule Scrypath.Search.Error do
  @moduledoc "Raised by bang search helpers when the matching non-bang API would return `{:error, reason}`."
  defexception [:reason]

  @impl true
  def message(%__MODULE__{reason: reason}) do
    classification = classify(reason)
    hint = guide_hint(reason)

    case hint do
      nil -> classification
      _ -> classification <> " " <> hint
    end
  end

  defp classify({:transport_failed, _}), do: "Search transport to the configured backend failed."

  defp classify({:invalid_options, _}),
    do: "Search options were rejected during multi-search setup (before any backend call)."

  defp classify({:validation_failed, _, _}),
    do: "One multi-search entry failed option validation before dispatch."

  defp classify({:all_failed, _}), do: "Every schema in the multi-search batch failed."

  defp classify(_), do: "Search failed."

  defp guide_hint({:transport_failed, _}),
    do: "See guides/meilisearch-operations.md for operator-facing Meilisearch checks."

  defp guide_hint({:invalid_options, _}),
    do:
      "See guides/multi-index-search.md for federation, :all expansion, and native search_many requirements."

  defp guide_hint(_), do: nil
end
