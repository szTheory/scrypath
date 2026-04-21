# Test-only searchable schemas for OPSUI LiveView tests.
defmodule ScrypathOps.Test.OpsPostA do
  use Ecto.Schema

  use Scrypath,
    fields: [:title],
    filterable: [],
    sortable: []

  embedded_schema do
    field(:title, :string)
  end
end

defmodule ScrypathOps.Test.OpsPostB do
  use Ecto.Schema

  use Scrypath,
    fields: [:title],
    filterable: [],
    sortable: []

  embedded_schema do
    field(:title, :string)
  end
end
