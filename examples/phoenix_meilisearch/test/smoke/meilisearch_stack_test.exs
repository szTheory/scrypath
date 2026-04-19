defmodule ScrypathDemo.Smoke.MeilisearchStackTest do
  @moduledoc false
  use ScrypathDemo.DataCase, async: false

  @moduletag :integration

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

  test "postgres row + inline sync + hydrated search", %{
    index_prefix: prefix,
    meilisearch_url: url
  } do
    {:ok, post} =
      %Post{}
      |> Post.changeset(%{title: "Smoke title", body: "Body", status: "published"})
      |> Repo.insert()

    assert {:ok, %{mode: :inline, status: :completed}} =
             Scrypath.sync_record(Post, post,
               backend: Scrypath.Meilisearch,
               sync_mode: :inline,
               index_prefix: prefix,
               meilisearch_url: url,
               inline_poll_interval: 50
             )

    assert {:ok, result} =
             Scrypath.search(Post, "Smoke",
               backend: Scrypath.Meilisearch,
               repo: Repo,
               index_prefix: prefix,
               meilisearch_url: url
             )

    assert [%Post{id: id, title: "Smoke title"}] = result.records
    assert id == post.id
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
