defmodule Scrypath.MultiSearchResult do
  @moduledoc false

  alias Scrypath.MultiSearchResult.Federation
  alias Scrypath.SearchResult

  @enforce_keys [:ordered, :by_schema, :failures]
  defstruct [:ordered, :by_schema, :failures, :federation]

  @type failure :: %{schema: module(), reason: term()}

  @type t :: %__MODULE__{
          ordered: [{module(), SearchResult.t()}],
          by_schema: %{optional(module()) => SearchResult.t()},
          failures: [failure()],
          federation: Federation.t() | nil
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
      federation: federation
    )
  end
end
