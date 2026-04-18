defmodule Scrypath.Operator.IndexContractDrift.Report.Dimension do
  @moduledoc false

  @enforce_keys [:match]
  defstruct [:match, :details]

  @type t :: %__MODULE__{match: boolean(), details: [term()]}

  @doc false
  @spec new(boolean(), [term()]) :: t()
  def new(match, details \\ []) do
    struct!(__MODULE__, match: match, details: details)
  end
end

defimpl Jason.Encoder, for: Scrypath.Operator.IndexContractDrift.Report.Dimension do
  def encode(%{match: match, details: details}, opts) do
    Jason.OrderedObject.new([
      {"match", match},
      {"details", details}
    ])
    |> Jason.Encode.value(opts)
  end
end

defmodule Scrypath.Operator.IndexContractDrift.Report do
  @moduledoc """
  Structured comparison of a schema's **declared** index contract against **live**
  Meilisearch index settings.

  This is **index contract drift** — not `Reconcile.drift_signals`, which describes
  operational sync and reindex posture rather than declared-vs-applied settings parity.
  """

  @enforce_keys [:version, :schema, :index, :dimensions]
  defstruct [:version, :schema, :index, :dimensions]

  @typedoc """
  Per-axis contract comparison. Keys are fixed for JSON stability.

  Each axis value is `%{match: boolean(), details: [term()]}` (the internal
  `Dimension` struct shape) without referencing the hidden implementation module
  in public types — keeps `mix docs --warnings-as-errors` clean.
  """
  @type dimension :: %{match: boolean(), details: [term()]}

  @type dimensions :: %{
          fields: dimension(),
          filterable_attributes: dimension(),
          sortable_attributes: dimension(),
          faceting: dimension(),
          settings: dimension()
        }

  @type t :: %__MODULE__{
          version: pos_integer(),
          schema: module(),
          index: String.t(),
          dimensions: dimensions()
        }
end

defimpl Jason.Encoder, for: Scrypath.Operator.IndexContractDrift.Report do
  alias Scrypath.Operator.IndexContractDrift.Report.Dimension

  @dim_order [:fields, :filterable_attributes, :sortable_attributes, :faceting, :settings]

  def encode(%{version: version, schema: schema, index: index, dimensions: dimensions}, opts) do
    dim_obj =
      Jason.OrderedObject.new(
        for k <- @dim_order do
          %Dimension{} = d = Map.fetch!(dimensions, k)
          {Atom.to_string(k), d}
        end
      )

    Jason.OrderedObject.new([
      {"version", version},
      {"schema", Atom.to_string(schema)},
      {"index", index},
      {"dimensions", dim_obj}
    ])
    |> Jason.Encode.value(opts)
  end
end
