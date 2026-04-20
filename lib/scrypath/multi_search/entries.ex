defmodule Scrypath.MultiSearch.Entries do
  @moduledoc """
  Normalizes `search_many/2` entry tuples and shared runtime options.

  Shared and per-entry keyword options merge with **per-key right bias**: when both
  sides define the same top-level key, the entry value wins (same as
  `Keyword.merge/3` with a conflict function returning the entry side).
  """

  @default_rails [
    max_schemas: 10,
    federation_limit: 200,
    federation_offset: 0,
    hydration_timeout: 5_000,
    federation_timeout: 7_500
  ]

  @shared_only_federation_keys MapSet.new([
                                 :federation_limit,
                                 :federation_offset,
                                 :hydration_timeout,
                                 :federation_timeout,
                                 :max_schemas
                               ])

  @max_page_size 50

  # Largest finite IEEE-754 binary64 (approx); used instead of :math.classify_float/1
  # for portability across OTP releases.
  @max_finite_double 1.7976931348623157e308

  @doc """
  Normalizes `entries` with `shared_opts`, returning `{:ok, list}` of
  `{schema, text, merged_opts, fed_opts}` in declaration order.

  `fed_opts` is `[]` or `[federation_weight: float]` (per-entry merge weight for
  federated multi-search). `:federation_weight` is never present on `merged_opts`.
  """
  @spec normalize(list(), keyword()) ::
          {:ok, [{module(), String.t(), keyword(), keyword()}]}
          | {:error, term()}
  def normalize(entries, shared_opts) when is_list(entries) and is_list(shared_opts) do
    cond do
      entries == [] ->
        {:error, :empty_schema_list}

      true ->
        shared = Keyword.merge(@default_rails, shared_opts)

        case check_schema_count(entries, shared) do
          :ok -> normalize_entries(entries, shared)
          {:error, _} = err -> err
        end
    end
  end

  defp check_schema_count(entries, shared) do
    max = Keyword.fetch!(shared, :max_schemas)

    if length(entries) > max do
      {:error, {:too_many_schemas, length(entries), max}}
    else
      :ok
    end
  end

  defp normalize_entries(entries, shared) do
    Enum.reduce_while(entries, {:ok, []}, fn entry, {:ok, acc} ->
      case normalize_one(entry, shared) do
        {:ok, quad} -> {:cont, {:ok, acc ++ [quad]}}
        {:error, _} = err -> {:halt, err}
      end
    end)
  end

  defp normalize_one({schema, text}, shared) when is_atom(schema) and is_binary(text) do
    normalize_one({schema, text, []}, shared)
  end

  defp normalize_one({schema, text, entry_opts}, shared)
       when is_atom(schema) and is_binary(text) and is_list(entry_opts) do
    {raw_weight, entry_core} = Keyword.pop(entry_opts, :federation_weight)

    with {:ok, fed_opts} <- federation_weight_opts(raw_weight),
         :ok <- reject_shared_only_in_entry(entry_core),
         merged <- Keyword.merge(shared, entry_core, fn _k, _s, e -> e end),
         merged <- merge_per_query_shallow(shared, entry_core, merged),
         :ok <- validate_page_size(merged) do
      {:ok, {schema, text, merged, fed_opts}}
    end
  end

  defp normalize_one(_, _shared) do
    {:error, {:invalid_options, :malformed_entry}}
  end

  defp federation_weight_opts(nil), do: {:ok, []}

  defp federation_weight_opts(w) when is_integer(w) do
    {:ok, [federation_weight: w * 1.0]}
  end

  defp federation_weight_opts(w) when is_float(w) do
    if finite_float?(w) do
      {:ok, [federation_weight: w]}
    else
      {:error, {:invalid_options, {:federation_weight, :non_finite}}}
    end
  end

  defp federation_weight_opts(_),
    do: {:error, {:invalid_options, {:federation_weight, :invalid_type}}}

  defp finite_float?(w) when is_float(w) do
    w == w and abs(w) <= @max_finite_double
  end

  defp reject_shared_only_in_entry(entry_opts) do
    case Enum.find(entry_opts, fn {k, _} -> MapSet.member?(@shared_only_federation_keys, k) end) do
      nil -> :ok
      {k, _} -> {:error, {:invalid_options, {:federation_key_in_entry, k}}}
    end
  end

  # D-11 (Phase 43): top-level entry wins on duplicate keys, but when *both* sides
  # supply `:per_query`, inner keys shallow-merge with entry bias on conflicts.
  defp merge_per_query_shallow(shared, entry_core, merged) do
    case {Keyword.get(shared, :per_query), Keyword.get(entry_core, :per_query)} do
      {nil, nil} ->
        merged

      {s, nil} ->
        Keyword.put(merged, :per_query, per_query_as_map(s))

      {nil, e} ->
        Keyword.put(merged, :per_query, per_query_as_map(e))

      {s, e} ->
        Keyword.put(
          merged,
          :per_query,
          Map.merge(per_query_as_map(s), per_query_as_map(e))
        )
    end
  end

  defp per_query_as_map(v) when is_map(v), do: Map.new(v)

  defp per_query_as_map(v) when is_list(v) do
    if Keyword.keyword?(v), do: Map.new(v), else: %{}
  end

  defp per_query_as_map(_), do: %{}

  defp validate_page_size(merged_opts) do
    page = Keyword.get(merged_opts, :page, [])
    page_kw = if is_map(page), do: Map.to_list(page), else: page

    case Keyword.get(page_kw, :size) do
      nil ->
        :ok

      n when is_integer(n) and n > @max_page_size ->
        {:error, {:invalid_options, {:page_size, n, @max_page_size}}}

      _ ->
        :ok
    end
  end
end
