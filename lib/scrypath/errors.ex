defmodule Scrypath.Errors do
  @moduledoc false

  @doc false
  @spec format_reason(term()) :: String.t()
  def format_reason(reason) do
    case reason do
      {:transport_failed, _} ->
        "Search transport to the configured backend failed. See guides/meilisearch-operations.md for operator-facing checks; for sync vs search visibility see guides/sync-modes-and-visibility.md and guides/common-mistakes.md."

      {:invalid_options, field, message}
      when is_atom(field) and is_binary(message) ->
        "Invalid options (#{field}): #{message} See guides/multi-index-search.md for search_many composition; sync semantics live in guides/sync-modes-and-visibility.md and pitfalls in guides/common-mistakes.md."

      {:invalid_options, inner} ->
        "Invalid options: #{inspect(inner)} See guides/multi-index-search.md for federation, :all expansion, and native search_many requirements; sync semantics live in guides/sync-modes-and-visibility.md; pitfalls in guides/common-mistakes.md."

      {:validation_failed, schema, inner} ->
        "Multi-search entry failed validation for #{inspect(schema)}: #{inspect(inner)} See guides/multi-index-search.md."

      {:all_failed, _} ->
        "Every schema in the multi-search batch failed. See guides/multi-index-search.md."

      {:timeout, _} ->
        "Inline sync stopped waiting for a Meilisearch task before it reached a terminal state (inline timeout). The task may still complete in the background. Read guides/sync-modes-and-visibility.md and guides/common-mistakes.md — accepted work is not the same thing as search visibility."

      {:task_failed, _} ->
        "Meilisearch reported a failed task during inline sync. Inspect the task payload and operator guide guides/meilisearch-operations.md; visibility semantics are in guides/sync-modes-and-visibility.md and guides/common-mistakes.md."

      {:cancelled, _} ->
        "Meilisearch cancelled the task while inline sync was waiting. See guides/sync-modes-and-visibility.md and guides/common-mistakes.md."

      {:invalid_task_payload, _} ->
        "Meilisearch returned an unexpected task payload while waiting. See guides/meilisearch-operations.md and guides/sync-modes-and-visibility.md."

      {:validation, message} when is_binary(message) ->
        message <>
          " See guides/sync-modes-and-visibility.md and guides/common-mistakes.md for sync vs search visibility."

      other ->
        "Search or sync failed: #{inspect(other)}"
    end
  end
end
