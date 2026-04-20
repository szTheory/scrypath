defmodule Scrypath.MultiSearchResult do
  @moduledoc false

  alias Scrypath.MultiSearchResult.Federation
  alias Scrypath.SearchResult

  @enforce_keys [:ordered, :by_schema, :failures]
  defstruct [:ordered, :by_schema, :failures, :federation, :merge_hit_order]

  @type failure :: %{schema: module(), reason: term()}

  @type t :: %__MODULE__{
          ordered: [{module(), SearchResult.t()}],
          by_schema: %{optional(module()) => SearchResult.t()},
          failures: [failure()],
          federation: Federation.t() | nil,
          merge_hit_order: [{module(), term()}] | nil
        }

  @doc """
  Builds a `%MultiSearchResult{}` from attributes, normalizing `federation` from
  `nil`, a map, or a `%Federation{}` struct.
  """
  @spec new(keyword() | map()) :: t()
  def new(attrs) when is_list(attrs), do: new(Map.new(attrs))

  def new(attrs) when is_map(attrs) do
    federation =
      case Map.get(attrs, :federation) do
        nil -> nil
        %Federation{} = f -> f
        other -> Federation.new(other)
      end

    struct!(__MODULE__,
      ordered: Map.fetch!(attrs, :ordered),
      by_schema: Map.fetch!(attrs, :by_schema),
      failures: Map.fetch!(attrs, :failures),
      federation: federation,
      merge_hit_order: Map.get(attrs, :merge_hit_order)
    )
  end

  @doc """
  Projects federated **merge order** into `{schema, hit_map}` pairs.

  Uses `merge_hit_order` (when present) together with per-schema `SearchResult.hits`
  to emit one row per merge position, reusing existing hit maps only.

  Returns `[]` when `merge_hit_order` is `nil` (for example sequential `search_many`
  fallback or non-federated responses).
  """
  @spec merge_projection(t()) :: [{module(), map()}]
  def merge_projection(%__MODULE__{merge_hit_order: nil}), do: []

  def merge_projection(%__MODULE__{merge_hit_order: order} = ms) when is_list(order) do
    Enum.flat_map(order, fn {schema, id} ->
      case Map.get(ms.by_schema, schema) do
        %SearchResult{hits: hits} ->
          case Enum.find(hits, &hit_matches_id?(&1, schema, id)) do
            nil -> []
            hit -> [{schema, hit}]
          end

        _ ->
          []
      end
    end)
  end

  defp hit_matches_id?(hit, schema, id) when is_map(hit) do
    doc_key = schema.__scrypath__(:document_id) |> Atom.to_string()
    hit_id = Map.get(hit, "id") || Map.get(hit, doc_key)
    ids_equivalent?(hit_id, id)
  end

  defp ids_equivalent?(a, b) when a == b, do: true

  defp ids_equivalent?(a, b) when is_integer(a) and is_binary(b) do
    case Integer.parse(b) do
      {^a, ""} -> true
      _ -> false
    end
  end

  defp ids_equivalent?(a, b) when is_binary(a) and is_integer(b) do
    case Integer.parse(a) do
      {^b, ""} -> true
      _ -> false
    end
  end

  defp ids_equivalent?(a, b) when is_binary(a) and is_binary(b) do
    case {Integer.parse(a), Integer.parse(b)} do
      {{ia, ""}, {ib, ""}} -> ia == ib
      _ -> a == b
    end
  end

  defp ids_equivalent?(_, _), do: false
end
