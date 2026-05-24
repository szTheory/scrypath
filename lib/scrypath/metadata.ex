defmodule Scrypath.Metadata do
  @moduledoc """
  Public plain-data reflection helpers for search capabilities and resolved state.

  `Scrypath.Metadata` does not execute search and does not expose `%Scrypath.Query{}`.
  It reflects two things:

  - declaration-backed capabilities derived from the same schema metadata and validators
    that already drive runtime behavior
  - resolved `applied`, `defaulted`, `fixed`, and `unsupported` state for one call or
    one multi-search entry

  The output is intended for honest host rendering. Tenant policy, authorization, and
  related-data behavior stay explicitly `host_owned`.
  """

  alias Scrypath.Composition.Multi
  alias Scrypath.Metadata.Capabilities
  alias Scrypath.Metadata.Resolve

  @spec schema_capabilities(module()) :: map()
  def schema_capabilities(schema_module) when is_atom(schema_module) do
    Capabilities.schema_capabilities(schema_module)
  end

  @spec reflect_search(module(), map()) :: map()
  def reflect_search(schema_module, criteria_or_composition)
      when is_atom(schema_module) and is_map(criteria_or_composition) do
    Resolve.reflect_search(
      schema_module,
      schema_capabilities(schema_module),
      criteria_or_composition
    )
  end

  @spec reflect_search_many(map() | list(), keyword()) :: map()
  def reflect_search_many(%{entries: _entries} = composition, _shared_opts) do
    entries =
      Enum.map(composition.entries, fn entry ->
        entry_reflection(entry.schema, entry)
      end)

    %{
      entries: entries,
      shared: Map.get(composition, :shared, %{}),
      host_owned: Resolve.host_owned()
    }
  end

  def reflect_search_many(entries, shared_opts) when is_list(entries) and is_list(shared_opts) do
    shared_criteria = Multi.shared_criteria_from_runtime_opts(shared_opts)

    reflected =
      Enum.map(entries, fn entry ->
        runtime_entry = Multi.entry_from_runtime_tuple(entry)
        composed = Multi.compose_runtime_entry(runtime_entry, shared_criteria)
        entry_reflection(runtime_entry.schema, composed)
      end)

    %{
      entries: reflected,
      shared: %{applied: shared_criteria},
      host_owned: Resolve.host_owned()
    }
  end

  defp entry_reflection(:all, entry) do
    %{
      entry: %{schema: :all, text: entry.text},
      capabilities: %{status: :deferred, reason: :all_expands_at_runtime},
      resolved: %{
        applied: Multi.criteria_from_entry(entry) |> Scrypath.Metadata.ResultLike.compact_visibility(),
        defaulted: Map.get(entry, :defaulted, %{}),
        fixed: Map.get(entry, :fixed, %{}),
        unsupported: %{}
      }
    }
  end

  defp entry_reflection(schema, entry) do
    reflect_search(schema, entry)
    |> Map.put(:entry, %{schema: schema, text: entry.text})
  end

  defmodule ResultLike do
    @moduledoc false

    @criteria_keys [:text, :filter, :sort, :page, :facets, :facet_filter, :per_query]

    def compact_visibility(criteria) when is_map(criteria) do
      Enum.reduce(@criteria_keys, %{}, fn key, acc ->
        value = Map.get(criteria, key, default_value(key))

        if present?(key, value) do
          Map.put(acc, key, value)
        else
          acc
        end
      end)
    end

    defp default_value(:text), do: ""
    defp default_value(:per_query), do: %{}
    defp default_value(_key), do: []

    defp present?(:text, value), do: is_binary(value) and String.trim(value) != ""
    defp present?(:per_query, value), do: value != %{}
    defp present?(_key, value), do: value != []
  end
end
