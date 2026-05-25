defmodule Scrypath.Composition.Multi do
  @moduledoc false

  alias Scrypath.Composition

  @criteria_keys [:filter, :sort, :page, :facets, :facet_filter, :per_query]

  @type entry_spec :: %{
          required(:schema) => module() | :all,
          required(:text) => String.t(),
          optional(:fragments) => Composition.fragment() | [Composition.fragment()],
          optional(:criteria) => Composition.criteria()
        }

  @type many_result :: %{
          required(:shared) => map(),
          required(:entries) => [map()]
        }

  @spec compose_many([entry_spec() | tuple()], keyword()) ::
          {:ok, many_result()} | {:error, term()}
  def compose_many(entries, opts \\ []) when is_list(entries) and is_list(opts) do
    with {:ok, shared} <- normalize_shared(Keyword.get(opts, :shared, %{})),
         {:ok, shared_result} <- Composition.compose(shared, %{}),
         {:ok, normalized_entries} <- normalize_entries(entries) do
      normalized_entries
      |> Enum.reduce_while({:ok, []}, fn entry, {:ok, acc} ->
        case compose_entry(entry, shared) do
          {:ok, composed} -> {:cont, {:ok, acc ++ [composed]}}
          {:error, _} = error -> {:halt, error}
        end
      end)
      |> case do
        {:ok, composed_entries} -> {:ok, %{shared: shared_result, entries: composed_entries}}
        {:error, _} = error -> error
      end
    end
  end

  @spec compose_many!([entry_spec() | tuple()], keyword()) :: many_result()
  def compose_many!(entries, opts \\ []) do
    case compose_many(entries, opts) do
      {:ok, result} ->
        result

      {:error, reason} ->
        raise ArgumentError, "multi-search composition failed: #{inspect(reason)}"
    end
  end

  @spec to_search_many_args(many_result()) :: {list(), keyword()}
  def to_search_many_args(%{entries: entries, shared: shared}) do
    shared_opts = criteria_to_opts(shared)

    tuples =
      Enum.map(entries, fn entry ->
        entry_opts =
          entry
          |> entry_specific_opts(shared)
          |> criteria_to_keyword()

        case entry_opts do
          [] -> {entry.schema, entry.text}
          opts -> {entry.schema, entry.text, opts}
        end
      end)

    {tuples, shared_opts}
  end

  @spec shared_criteria_from_runtime_opts(keyword()) :: map()
  def shared_criteria_from_runtime_opts(shared_opts) when is_list(shared_opts) do
    Enum.reduce(@criteria_keys, %{}, fn key, acc ->
      Map.put(acc, key, Keyword.get(shared_opts, key, default_value(key)))
    end)
  end

  @spec entry_from_runtime_tuple(tuple()) :: map()
  def entry_from_runtime_tuple({schema, text}) when is_binary(text) do
    %{schema: schema, text: text, criteria: %{}, fragments: []}
  end

  def entry_from_runtime_tuple({schema, text, opts}) when is_binary(text) and is_list(opts) do
    %{
      schema: schema,
      text: text,
      criteria: shared_criteria_from_runtime_opts(opts),
      fragments: []
    }
  end

  @spec compose_runtime_entry(map(), map()) :: map()
  def compose_runtime_entry(entry, shared_criteria) do
    shared_fragment = %{defaults: Map.drop(shared_criteria, [:text])}
    {:ok, composed} = compose_entry(entry, shared_fragment)
    composed
  end

  @spec criteria_from_entry(map()) :: map()
  def criteria_from_entry(entry) do
    Enum.reduce([:text | @criteria_keys], %{}, fn key, acc ->
      Map.put(acc, key, Map.get(entry, key, default_value(key)))
    end)
  end

  defp normalize_shared(shared) do
    shared
    |> List.wrap()
    |> Enum.reduce_while({:ok, []}, fn fragment, {:ok, acc} ->
      cond do
        not is_map(fragment) ->
          {:halt, {:error, {:invalid_shared_fragment, :expected_map}}}

        Map.get(fragment, :fixed, %{}) not in [%{}, nil] ->
          {:halt, {:error, {:invalid_shared_fixed, :fixed_not_supported}}}

        shared_text?(fragment) ->
          {:halt, {:error, {:invalid_shared_field, :text}}}

        true ->
          {:cont, {:ok, acc ++ [Map.put(fragment, :fixed, %{})]}}
      end
    end)
  end

  defp normalize_entries(entries) do
    Enum.reduce_while(entries, {:ok, []}, fn entry, {:ok, acc} ->
      case normalize_entry(entry) do
        {:ok, normalized} -> {:cont, {:ok, acc ++ [normalized]}}
        {:error, _} = error -> {:halt, error}
      end
    end)
  end

  defp normalize_entry(%{schema: schema, text: text} = entry)
       when (is_atom(schema) or schema == :all) and is_binary(text) do
    {:ok,
     %{
       schema: schema,
       text: text,
       fragments: List.wrap(Map.get(entry, :fragments, [])),
       criteria: Map.get(entry, :criteria, %{})
     }}
  end

  defp normalize_entry({schema, text})
       when (is_atom(schema) or schema == :all) and is_binary(text) do
    {:ok, %{schema: schema, text: text, fragments: [], criteria: %{}}}
  end

  defp normalize_entry({schema, text, opts})
       when (is_atom(schema) or schema == :all) and is_binary(text) and is_list(opts) do
    {:ok,
     %{
       schema: schema,
       text: text,
       fragments: [],
       criteria: shared_criteria_from_runtime_opts(opts)
     }}
  end

  defp normalize_entry(_), do: {:error, {:invalid_many_entry, :expected_entry_spec}}

  defp compose_entry(entry, shared) do
    shared_fragment = List.wrap(shared)
    entry_fragments = List.wrap(entry.fragments)

    case Composition.compose(
           shared_fragment ++ entry_fragments,
           Map.put(entry.criteria, :text, entry.text)
         ) do
      {:ok, composition} ->
        {:ok, Map.merge(%{schema: entry.schema}, composition)}

      {:error, _} = error ->
        error
    end
  end

  defp criteria_to_opts(shared) do
    shared
    |> Map.take(@criteria_keys)
    |> criteria_to_keyword()
  end

  defp entry_specific_opts(entry, shared) do
    shared_applied = Map.get(shared, :applied, %{})
    defaulted = Map.get(entry, :defaulted, %{})

    Enum.reduce(@criteria_keys, %{}, fn key, acc ->
      value = Map.get(entry, key, default_value(key))
      shared_value = Map.get(shared_applied, key, default_value(key))

      cond do
        not present?(key, value) ->
          acc

        inherited_from_shared?(key, value, shared_applied, defaulted) ->
          acc

        key == :per_query and present?(key, shared_value) ->
          Map.put(acc, key, per_query_delta(shared_value, value))

        true ->
          Map.put(acc, key, value)
      end
    end)
  end

  defp inherited_from_shared?(key, value, shared_applied, defaulted) do
    Map.has_key?(shared_applied, key) and Map.get(defaulted, key) == value
  end

  defp per_query_delta(shared_value, value) do
    Enum.reduce(value, %{}, fn {key, candidate}, acc ->
      if Map.get(shared_value, key) == candidate do
        acc
      else
        Map.put(acc, key, candidate)
      end
    end)
  end

  defp criteria_to_keyword(criteria) do
    Enum.reduce(@criteria_keys, [], fn key, acc ->
      value = Map.get(criteria, key, default_value(key))

      if present?(key, value) do
        acc ++ [{key, value}]
      else
        acc
      end
    end)
  end

  defp shared_text?(fragment) do
    fragment
    |> Map.get(:defaults, %{})
    |> Map.get(:text, "")
    |> case do
      value when is_binary(value) -> String.trim(value) != ""
      _ -> true
    end
  end

  defp default_value(:text), do: ""
  defp default_value(:per_query), do: %{}
  defp default_value(_key), do: []

  defp present?(:text, value), do: is_binary(value) and String.trim(value) != ""
  defp present?(:per_query, value), do: value != %{}
  defp present?(_key, value), do: value != []
end
