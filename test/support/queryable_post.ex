defmodule QueryableAuthor do
  use Ecto.Schema

  schema "authors" do
    field(:name, :string)
  end
end

defmodule QueryablePost do
  use Ecto.Schema

  use Scrypath,
    fields: [:title, :body],
    filterable: [:status],
    sortable: [:inserted_at]

  schema "posts" do
    field(:title, :string)
    field(:body, :string)
    field(:status, :string)
    field(:inserted_at, :utc_datetime)
    belongs_to(:author, QueryableAuthor)
  end
end

defmodule QueryableExternalPost do
  use Ecto.Schema

  @primary_key {:external_id, :string, autogenerate: false}

  use Scrypath,
    fields: [:title],
    document_id: :external_id

  schema "external_posts" do
    field(:title, :string)
  end
end
