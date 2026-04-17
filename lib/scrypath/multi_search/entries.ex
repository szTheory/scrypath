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

  @doc """
  Normalizes `entries` with `shared_opts`, returning `{:ok, list}` of
  `{schema, text, merged_opts}` in declaration order.
  """
  @spec normalize(list(), keyword()) ::
          {:ok, [{module(), String.t(), keyword()}]}
          | {:error, term()}
  def normalize(entries, shared_opts) when is_list(entries) and is_list(shared_opts) do
    cond do
      entries == [] ->
        {:error, :empty_schema_list}

      true ->
        shared = Keyword.merge(@default_rails, shared_opts)

        with :ok <- check_schema_count(entries, shared),
             {:ok, normalized} <- normalize_entries(entries, shared) do
          {:ok, normalized}
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
        {:ok, triple} -> {:cont, {:ok, acc ++ [triple]}}
        {:error, _} = err -> {:halt, err}
      end
    end)
  end

  defp normalize_one({schema, text}, shared) when is_atom(schema) and is_binary(text) do
    normalize_one({schema, text, []}, shared)
  end

  defp normalize_one({schema, text, entry_opts}, shared)
       when is_atom(schema) and is_binary(text) and is_list(entry_opts) do
    with :ok <- reject_shared_only_in_entry(entry_opts),
         merged <- Keyword.merge(shared, entry_opts, fn _k, _s, e -> e end),
         :ok <- validate_page_size(merged) do
      {:ok, {schema, text, merged}}
    end
  end

  defp normalize_one(_, _shared) do
    {:error, {:invalid_options, :malformed_entry}}
  end

  defp reject_shared_only_in_entry(entry_opts) do
    case Enum.find(entry_opts, fn {k, _} -> MapSet.member?(@shared_only_federation_keys, k) end) do
      nil -> :ok
      {k, _} -> {:error, {:invalid_options, {:federation_key_in_entry, k}}}
    end
  end

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
