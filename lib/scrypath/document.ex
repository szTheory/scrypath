defmodule Scrypath.Document do
  @moduledoc """
  Internal projected search document used between Scrypath orchestration layers.

  This struct is part of the library's implementation boundary rather than the
  primary public API, but it is documented because the architecture guide and
  type specifications refer to it directly.
  """

  @enforce_keys [:id, :data, :source]
  defstruct [:id, :data, :source]

  @typedoc "Internal projected search document."
  @type t :: %__MODULE__{
          id: term(),
          data: map(),
          source: :fields | :custom
        }
end
