defmodule Scrypath.Facets.Disjunctive do
  @moduledoc """
  Merge helpers for Meilisearch **`facetDistribution`** JSON maps when building **disjunctive facet counts**.

  A **single search** returns `facetDistribution` counts on the **same document set** as hits,
  after `q` and **every active filter** (including facet refinements). Buckets therefore reflect
  **conjunctive** narrowing — not "OR-group unrefined" distributions from that response alone.

  **Multi-search** is how Meilisearch documents **disjunctive facet counts** (the engine’s **multi-search** batching or separate HTTP calls): run a main query,
  then auxiliary queries that **drop** each disjunctive group's refinements for that group's
  distribution (often `limit: 0`), then **merge** the returned maps. This module only performs
  that merge on wire-level maps; it does **not** call HTTP or assemble auxiliary payloads.
  """

  @typedoc "Inner `value => count` map as decoded from Meilisearch JSON (counts are integers)."
  @type facet_inner_distribution :: %{optional(String.t()) => non_neg_integer()}

  @typedoc "Outer `facet_attribute => inner_distribution` map (`facetDistribution` JSON shape)."
  @type facet_distribution_json :: %{optional(String.t()) => facet_inner_distribution()}

  @doc """
  Returns a deep copy of `main` where each outer key `to_string(k)` from `overrides` is
  **replaced** (or **inserted** if missing) by a normalized copy of the inner map `overrides[k]`.

  Parameters are **wire-level maps** (string keys on `main`), not `%Scrypath.SearchResult.Facets{}`.
  Override keys may be atoms or strings; inner maps use string keys and integer counts as in JSON.
  """
  @spec merge_distributions(facet_distribution_json(), %{optional(atom() | String.t()) => map()}) ::
          facet_distribution_json()
  def merge_distributions(main, overrides) when is_map(main) and is_map(overrides) do
    base = copy_distribution(main)

    Enum.reduce(overrides, base, fn {key, inner}, acc ->
      outer_key = to_string(key)
      Map.put(acc, outer_key, normalize_inner(inner))
    end)
  end

  defp copy_distribution(map) when is_map(map) do
    Map.new(map, fn {k, v} -> {to_string(k), normalize_inner(v)} end)
  end

  defp normalize_inner(map) when is_map(map) do
    Map.new(map, fn {ik, count} -> {to_string(ik), normalize_count(count)} end)
  end

  defp normalize_inner(_), do: %{}

  defp normalize_count(n) when is_integer(n) and n >= 0, do: n
  defp normalize_count(n) when is_integer(n), do: 0
  defp normalize_count(n) when is_float(n), do: trunc(n)
  defp normalize_count(_), do: 0
end
