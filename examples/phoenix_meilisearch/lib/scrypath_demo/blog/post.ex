defmodule ScrypathDemo.Blog.Post do
  @moduledoc false
  use Ecto.Schema

  use Scrypath,
    fields: [:title, :body, :author_name, :status, :tenant_id, :category],
    filterable: [:status, :tenant_id, :category],
    faceting: [attributes: [:category], max_values_per_facet: 100],
    tenant_field: :tenant_id,
    sortable: [:inserted_at]

  schema "posts" do
    field(:title, :string)
    field(:body, :string)
    field(:status, :string)
    field(:author_name, :string)
    field(:tenant_id, :integer)
    field(:category, :string)
    belongs_to(:author, ScrypathDemo.Blog.Author)
    timestamps()
  end

  def changeset(post, attrs) do
    post
    |> Ecto.Changeset.cast(attrs, [
      :title,
      :body,
      :status,
      :author_id,
      :author_name,
      :category
    ])
    |> Ecto.Changeset.validate_required([:title, :body, :status])
  end
end
