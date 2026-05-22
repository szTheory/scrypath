defmodule Scrypath.QueryParams.Error do
  @moduledoc """
  Structured request-edge issue for `Scrypath.QueryParams.normalize/1`.

  Errors stay plain and field-scoped so host applications can render or project
  them without depending on Phoenix or Ecto changeset semantics.
  """

  @enforce_keys [:code, :message, :path, :meta]
  defstruct [:field, :code, :message, :path, :meta]

  @type t :: %__MODULE__{
          field: atom() | nil,
          code: atom(),
          message: String.t(),
          path: [atom() | String.t()],
          meta: map()
        }
end
