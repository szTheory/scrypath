defmodule ScrypathDemo.Smoke.MeilisearchRelatedObanStackTest do
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

    prefix = "phx_demo_oban_#{System.unique_integer([:positive])}"

    config = [
      index_prefix: prefix,
      meilisearch_url: url
    ]

    live_index = Scrypath.Meilisearch.index_name(Post, config)

    on_exit(fn -> delete_index(url, live_index) end)

    %{index_prefix: prefix, meilisearch_url: url, live_index: live_index}
  end

  test "author rename + oban fan-out re-syncs Post author_name in search doc", %{
    index_prefix: prefix,
    meilisearch_url: url
  } do
    # Insert an Author and a Post owned by it.
    {:ok, author} =
      %Author{}
      |> Author.changeset(%{name: "Original Author"})
      |> Repo.insert()

    {:ok, post} =
      %Post{}
      |> Post.changeset(%{
        title: "Fan-out oban test post",
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

    # Rename the author via the Blog context (oban fan-out path).
    # fan-out :oban enqueues Scrypath.Sync.RelatedWorker (not the UpsertWorker used
    # by sync_record). Under `config :scrypath_demo, Oban, testing: :inline` the
    # RelatedWorker job runs in-process.
    sync_opts = [
      backend: Scrypath.Meilisearch,
      sync_mode: :oban,
      oban: ScrypathDemo.Oban,
      oban_queue: :scrypath,
      index_prefix: prefix,
      meilisearch_url: url
    ]

    assert {:ok, %{mode: :oban, status: :accepted}, _updated_author} =
             Blog.update_author(author, %{name: "Oban Renamed Author"}, sync_opts)

    # Verify the EFFECT: under testing: :inline the RelatedWorker runs in-process,
    # so await_search finds the Post with the updated author_name.
    assert {:ok, result} = await_search(Post, "Oban Renamed Author", prefix, url)
    assert [%Post{id: post_id, author_name: "Oban Renamed Author"}] = result.records
    assert post_id == post.id
  end

  defp await_search(schema, q, prefix, url, attempts \\ 60) do
    case Scrypath.search(schema, q,
           backend: Scrypath.Meilisearch,
           repo: Repo,
           index_prefix: prefix,
           meilisearch_url: url
         ) do
      {:ok, %{records: [_ | _]} = result} ->
        {:ok, result}

      {:ok, %{records: []}} ->
        if attempts <= 1 do
          flunk("search stayed empty after Oban fan-out (Meilisearch visibility lag?)")
        else
          Process.sleep(50)
          await_search(schema, q, prefix, url, attempts - 1)
        end

      other ->
        other
    end
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
