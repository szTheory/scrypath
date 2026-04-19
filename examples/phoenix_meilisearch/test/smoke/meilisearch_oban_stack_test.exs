defmodule ScrypathDemo.Smoke.MeilisearchObanStackTest do
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

    prefix = "phx_demo_oban_#{System.unique_integer([:positive])}"

    config = [
      index_prefix: prefix,
      meilisearch_url: url
    ]

    live_index = Scrypath.Meilisearch.index_name(Post, config)

    on_exit(fn -> delete_index(url, live_index) end)

    %{index_prefix: prefix, meilisearch_url: url, live_index: live_index}
  end

  test "postgres row + oban enqueue + worker upsert + hydrated search", %{
    index_prefix: prefix,
    meilisearch_url: url
  } do
    {:ok, post} =
      %Post{}
      |> Post.changeset(%{title: "Oban smoke title", body: "Queued body", status: "published"})
      |> Repo.insert()

    assert {:ok, %{mode: :oban, status: :accepted, job: %{worker: "Scrypath.Oban.UpsertWorker"}}} =
             Scrypath.sync_record(Post, post,
               backend: Scrypath.Meilisearch,
               sync_mode: :oban,
               oban: ScrypathDemo.Oban,
               oban_queue: :scrypath,
               index_prefix: prefix,
               meilisearch_url: url
             )

    assert {:ok, result} = await_search(Post, "Oban smoke", prefix, url)
    assert [%Post{id: id, title: "Oban smoke title"}] = result.records
    assert id == post.id
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
          flunk("search stayed empty after Oban upsert (Meilisearch visibility lag?)")
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
