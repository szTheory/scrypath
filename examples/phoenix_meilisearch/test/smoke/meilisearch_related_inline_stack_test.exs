defmodule ScrypathDemo.Smoke.MeilisearchRelatedInlineStackTest do
  @moduledoc false
  use ScrypathDemo.DataCase, async: false

  @moduletag :integration

  alias ScrypathDemo.Blog
  alias ScrypathDemo.Blog.Author
  alias ScrypathDemo.Blog.Post
  alias ScrypathDemo.Repo

  setup do
    url = System.get_env("SCRYPATH_MEILISEARCH_URL")

    unless url do
      raise "SCRYPATH_MEILISEARCH_URL must be set for integration smoke (see scripts/smoke.sh)"
    end

    prefix = "phx_demo_#{System.unique_integer([:positive])}"

    config = [
      index_prefix: prefix,
      meilisearch_url: url
    ]

    live_index = Scrypath.Meilisearch.index_name(Post, config)

    on_exit(fn -> delete_index(url, live_index) end)

    %{index_prefix: prefix, meilisearch_url: url, live_index: live_index}
  end

  test "author rename + inline fan-out re-syncs Post author_name in search doc", %{
    index_prefix: prefix,
    meilisearch_url: url
  } do
    # Insert an Author and a Post owned by it.
    {:ok, author} =
      %Author{}
      |> Author.changeset(%{name: "Original Name"})
      |> Repo.insert()

    {:ok, post} =
      %Post{}
      |> Post.changeset(%{
        title: "Fan-out inline test post",
        body: "Body content",
        status: "published",
        author_id: author.id,
        author_name: author.name
      })
      |> Repo.insert()

    # Sync the initial Post so it is indexed before we test the fan-out.
    assert {:ok, %{mode: :inline, status: :completed}} =
             Scrypath.sync_record(Post, post,
               backend: Scrypath.Meilisearch,
               sync_mode: :inline,
               index_prefix: prefix,
               meilisearch_url: url,
               inline_poll_interval: 50
             )

    # Rename the author via the Blog context (inline fan-out path).
    sync_opts = [
      backend: Scrypath.Meilisearch,
      sync_mode: :inline,
      index_prefix: prefix,
      meilisearch_url: url,
      inline_poll_interval: 50
    ]

    assert {:ok, %{mode: :inline, status: :completed}, _updated_author} =
             Blog.update_author(author, %{name: "Renamed Author"}, sync_opts)

    # Search for the new name — the Post doc must reflect the renamed author_name.
    assert {:ok, result} =
             Scrypath.search(Post, "Renamed Author",
               backend: Scrypath.Meilisearch,
               repo: Repo,
               index_prefix: prefix,
               meilisearch_url: url
             )

    assert [%Post{id: post_id, author_name: "Renamed Author"}] = result.records
    assert post_id == post.id
  end

  defp delete_index(url, uid) when is_binary(url) and is_binary(uid) do
    req = Req.new(base_url: url)

    case Req.request(req, method: :delete, url: "/indexes/#{uid}") do
      {:ok, _} -> :ok
      {:error, _} -> :ok
    end
  rescue
    _ -> :ok
  end
end
