defmodule ScrypathDemo.Blog.Post do
  @moduledoc false
  use Ecto.Schema

  use Scrypath,
    fields: [:title, :body],
    filterable: [:status],
    sortable: [:inserted_at]

  schema "posts" do
    field(:title, :string)
    field(:body, :string)
    field(:status, :string)
    timestamps()
  end

  def changeset(post, attrs) do
    post
    |> Ecto.Changeset.cast(attrs, [:title, :body, :status])
    |> Ecto.Changeset.validate_required([:title, :body, :status])
  end
end
