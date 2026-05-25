defmodule ScrypathDemo.Blog.Post do
  @moduledoc false
  use Ecto.Schema

  use Scrypath,
    fields: [:title, :body, :author_name],
    filterable: [:status],
    sortable: [:inserted_at]

  schema "posts" do
    field(:title, :string)
    field(:body, :string)
    field(:status, :string)
    field(:author_name, :string)
    belongs_to(:author, ScrypathDemo.Blog.Author)
    timestamps()
  end

  def changeset(post, attrs) do
    post
    |> Ecto.Changeset.cast(attrs, [:title, :body, :status, :author_id, :author_name])
    |> Ecto.Changeset.validate_required([:title, :body, :status])
  end
end
