defmodule ScrypathDemo.EctoCompatibilityTest do
  use ScrypathDemo.DataCase, async: true

  alias ScrypathDemo.Blog.Author
  alias ScrypathDemo.Blog.Post

  test "changesets validate and persist the existing author and post model" do
    refute Author.changeset(%Author{}, %{}).valid?
    assert %{name: ["can't be blank"]} = errors_on(Author.changeset(%Author{}, %{}))

    refute Post.changeset(%Post{}, %{}).valid?

    assert %{body: ["can't be blank"], status: ["can't be blank"], title: ["can't be blank"]} =
             errors_on(Post.changeset(%Post{}, %{}))

    author = author_fixture()
    post = post_fixture(author)

    persisted_post =
      Post
      |> Repo.get!(post.id)
      |> Repo.preload(:author)

    assert persisted_post.title == "Compatibility title"
    assert persisted_post.body == "Compatibility body"
    assert persisted_post.status == "published"
    assert persisted_post.author_name == author.name
    assert persisted_post.author.id == author.id
    assert persisted_post.author.name == author.name
    assert persisted_post.inserted_at
    assert persisted_post.updated_at
  end

  defp author_fixture(attrs \\ %{}) do
    %{name: "Compatibility author"}
    |> Map.merge(attrs)
    |> then(&Author.changeset(%Author{}, &1))
    |> Repo.insert!()
  end

  defp post_fixture(author, attrs \\ %{}) do
    %{
      title: "Compatibility title",
      body: "Compatibility body",
      status: "published",
      author_id: author.id,
      author_name: author.name
    }
    |> Map.merge(attrs)
    |> then(&Post.changeset(%Post{}, &1))
    |> Repo.insert!()
  end
end
