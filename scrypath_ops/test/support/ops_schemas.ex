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

  # Oban sync jobs load current records by id; tests return a fixed current row.
  def search_records(ids, _context), do: Enum.map(ids, &%__MODULE__{id: &1, title: "Prepared"})
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

  # Oban sync jobs load current records by id; tests return a fixed current row.
  def search_records(ids, _context), do: Enum.map(ids, &%__MODULE__{id: &1, title: "Prepared"})
end

defmodule ScrypathOps.Test.OpsPostC do
  use Ecto.Schema

  use Scrypath,
    fields: [:title],
    filterable: [],
    sortable: []

  embedded_schema do
    field(:title, :string)
  end
end
