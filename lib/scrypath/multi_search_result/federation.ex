defmodule Scrypath.MultiSearchResult.Federation do
  @moduledoc """
  Federated multi-search metadata mirrored from Meilisearch's federation object.

  All fields use snake_case; `nil` means the backend omitted the value.
  """

  defstruct [
    :estimated_total_hits,
    :processing_time_ms,
    :limit,
    :offset
  ]

  @type t :: %__MODULE__{
          estimated_total_hits: non_neg_integer() | nil,
          processing_time_ms: non_neg_integer() | nil,
          limit: non_neg_integer() | nil,
          offset: non_neg_integer() | nil
        }

  @doc false
  @spec new(map() | keyword()) :: t()
  def new(attrs) when is_list(attrs), do: new(Map.new(attrs))

  def new(attrs) when is_map(attrs) do
    %__MODULE__{
      estimated_total_hits: int_or_nil(attrs, :estimated_total_hits, "estimatedTotalHits"),
      processing_time_ms: int_or_nil(attrs, :processing_time_ms, "processingTimeMs"),
      limit: int_or_nil(attrs, :limit, "limit"),
      offset: int_or_nil(attrs, :offset, "offset")
    }
  end

  defp int_or_nil(map, atom, string) do
    case Map.get(map, atom) || Map.get(map, string) do
      n when is_integer(n) and n >= 0 -> n
      _ -> nil
    end
  end
end
