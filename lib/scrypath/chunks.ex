defmodule Scrypath.Chunks do
  @moduledoc false

  # Every id list Scrypath sends to a backend or a database is split into chunks of at
  # most @max_ids. The bound is internal on purpose: it is not a public option.
  @max_ids 1000

  @doc false
  @spec max_ids() :: pos_integer()
  def max_ids, do: @max_ids

  @doc false
  # Dedupes by id_key/1 (keeping the first occurrence), then sorts so the same id set in
  # any order yields the same chunks. Sorting compares the string form first, with the
  # raw value as a tiebreak, so 1 and "1" stay distinct.
  @spec ids([term()]) :: [[term()]]
  def ids(ids) when is_list(ids) do
    ids
    |> Enum.uniq_by(&id_key/1)
    |> Enum.sort_by(&sort_key/1)
    |> Enum.chunk_every(@max_ids)
  end

  @doc false
  # One entry per id; the last occurrence of a duplicate id wins (the latest caller copy).
  @spec by_id([item], (item -> term())) :: [[item]] when item: term()
  def by_id(items, id_fun) when is_list(items) and is_function(id_fun, 1) do
    items
    |> Enum.reverse()
    |> Enum.uniq_by(&id_key(id_fun.(&1)))
    |> Enum.reverse()
    |> Enum.sort_by(&sort_key(id_fun.(&1)))
    |> Enum.chunk_every(@max_ids)
  end

  @doc false
  # How many ids remain once ids/1 dedupes them.
  @spec distinct_count([term()]) :: non_neg_integer()
  def distinct_count(ids) when is_list(ids) do
    ids |> Enum.uniq_by(&id_key/1) |> length()
  end

  @doc false
  # The dedupe key for an id: the value an Oban job stores once its args are JSON-encoded.
  # A plain atom id is stored as its name, so :a and "a" are the same id everywhere (Oban
  # jobs, inline and manual writes, span counts). 1 and "1" stay distinct: JSON keeps them
  # apart, and booleans and nil are JSON values in their own right.
  @spec id_key(term()) :: term()
  def id_key(id) when is_atom(id) and not is_boolean(id) and not is_nil(id),
    do: Atom.to_string(id)

  def id_key(id), do: id

  @doc false
  # Runs `fun` on each chunk in order and stops at the first `{:error, _}`.
  @spec reduce_ok([chunk], (chunk -> {:ok, result} | {:error, term()})) ::
          {:ok, [result]} | {:error, term()}
        when chunk: term(), result: term()
  def reduce_ok(chunks, fun) when is_list(chunks) and is_function(fun, 1) do
    chunks
    |> Enum.reduce_while({:ok, []}, fn chunk, {:ok, acc} ->
      case fun.(chunk) do
        {:ok, result} -> {:cont, {:ok, [result | acc]}}
        {:error, _reason} = error -> {:halt, error}
      end
    end)
    |> case do
      {:ok, results} -> {:ok, Enum.reverse(results)}
      {:error, _reason} = error -> error
    end
  end

  @doc false
  # Like reduce_ok/2 for callbacks that return `:ok`.
  @spec each_ok([chunk], (chunk -> :ok | {:error, term()})) :: :ok | {:error, term()}
        when chunk: term()
  def each_ok(chunks, fun) when is_list(chunks) and is_function(fun, 1) do
    Enum.reduce_while(chunks, :ok, fn chunk, :ok ->
      case fun.(chunk) do
        :ok -> {:cont, :ok}
        {:error, _reason} = error -> {:halt, error}
      end
    end)
  end

  defp sort_key(id) when is_binary(id) or is_number(id) or is_atom(id), do: {to_string(id), id}
  defp sort_key(id), do: {inspect(id), id}
end
