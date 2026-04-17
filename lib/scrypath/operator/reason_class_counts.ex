defmodule Scrypath.Operator.ReasonClassCounts do
  @moduledoc """
  Dense per-class counts for failed sync work rows.

  `by_class` always includes exactly these keys, in this order when encoded to
  JSON: `:transport`, `:validation`, `:backend_rejected`, `:queue_exhausted`,
  `:unknown`. Each value is a non-negative integer.

  When rollups are computed over a **filtered** row list, `total` reflects that
  list only — do not compare it to an unfiltered source length without
  recomputing counts on the same list you display.
  """

  @enforce_keys [:version, :total, :by_class]
  defstruct [:version, :total, :by_class]

  @typedoc "Rollup map keyed by every `FailedWork.reason_class/0` atom."
  @type by_class :: %{
          transport: non_neg_integer(),
          validation: non_neg_integer(),
          backend_rejected: non_neg_integer(),
          queue_exhausted: non_neg_integer(),
          unknown: non_neg_integer()
        }

  @type t :: %__MODULE__{
          version: pos_integer(),
          total: non_neg_integer(),
          by_class: by_class()
        }
end

defimpl Jason.Encoder, for: Scrypath.Operator.ReasonClassCounts do
  @order [:transport, :validation, :backend_rejected, :queue_exhausted, :unknown]

  def encode(%{version: version, total: total, by_class: by_class}, opts) do
    inner =
      Jason.OrderedObject.new(
        for k <- @order do
          {Atom.to_string(k), Map.fetch!(by_class, k)}
        end
      )

    Jason.OrderedObject.new([
      {"version", version},
      {"total", total},
      {"by_class", inner}
    ])
    |> Jason.Encode.value(opts)
  end
end
