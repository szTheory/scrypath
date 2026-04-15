defmodule Scrypath.Document do
  @moduledoc false

  @enforce_keys [:id, :data, :source]
  defstruct [:id, :data, :source]

  @type t :: %__MODULE__{
          id: term(),
          data: map(),
          source: :fields | :custom
        }
end
