defmodule SearchablePost do
  use Ecto.Schema

  use Scrypath,
    fields: [:title, :body],
    filterable: [:status],
    sortable: [:inserted_at]

  embedded_schema do
    field(:title, :string)
    field(:body, :string)
    field(:status, :string)
    field(:inserted_at, :utc_datetime)
  end
end

defmodule ConfiguredSearchablePost do
  use Ecto.Schema

  use Scrypath,
    fields: [:title, :body],
    settings: %{
      searchableAttributes: ["title", "body"],
      typoTolerance: [enabled: true]
    }

  embedded_schema do
    field(:title, :string)
    field(:body, :string)
  end
end
