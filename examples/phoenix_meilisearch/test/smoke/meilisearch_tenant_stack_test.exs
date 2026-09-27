defmodule ScrypathDemo.Smoke.MeilisearchTenantStackTest do
  @moduledoc false
  use ScrypathDemo.DataCase, async: false

  @moduletag :integration

  alias ScrypathDemo.Blog
  alias ScrypathDemo.Blog.Post
  alias ScrypathDemo.Repo

  @tag :host_tenant
  test "authorized tenant search and facet values" do
    url = System.get_env("SCRYPATH_MEILISEARCH_URL")

    unless url do
      raise "SCRYPATH_MEILISEARCH_URL must be set for the host tenant scenario"
    end

    prefix = "phx_tenant_#{System.unique_integer([:positive])}"

    config = [
      backend: Scrypath.Meilisearch,
      index_prefix: prefix,
      meilisearch_url: url,
      inline_poll_interval: 50
    ]

    index = Scrypath.Meilisearch.index_name(Post, config)
    on_exit(fn -> delete_index(url, index) end)

    {:ok, create_task} = Scrypath.Meilisearch.Client.create_index(index, :id, config)
    await_task!(create_task, config)

    {:ok, %{task: settings_task}} = Scrypath.Meilisearch.apply_settings(Post, index, config)
    await_task!(settings_task, config)
    assert_filterable_settings!(index, config)

    tenant_id = 166_001
    actor = insert_actor_with_membership(tenant_id)
    post = insert_post(tenant_id, "Phase166 authorized tenant post", "phone-a")

    assert {:ok, %{mode: :inline, status: :completed}} =
             Scrypath.sync_record(Post, post,
               backend: Scrypath.Meilisearch,
               sync_mode: :inline,
               index_prefix: prefix,
               meilisearch_url: url,
               inline_poll_interval: 50
             )

    assert {:ok, %{search: result, records: records}} =
             Blog.search_posts(actor, tenant_id, %{"q" => "Phase166 authorized"}, config)

    assert [%{"id" => raw_id, "title" => "Phase166 authorized tenant post"}] =
             Map.get(result.raw, "hits")

    assert to_string(raw_id) == to_string(post.id)
    assert Map.get(result.raw, "totalHits") == 1
    assert [%Post{id: hydrated_id, tenant_id: ^tenant_id}] = records
    assert hydrated_id == post.id
    assert result.records == []
  end

  defp insert_actor_with_membership(tenant_id) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    {1, [%{id: actor_id}]} =
      Repo.insert_all(
        "host_actors",
        [%{name: "synthetic-member-#{tenant_id}", inserted_at: now, updated_at: now}],
        returning: [:id]
      )

    Repo.insert_all("host_memberships", [
      %{actor_id: actor_id, tenant_id: tenant_id, inserted_at: now, updated_at: now}
    ])

    %{id: actor_id}
  end

  defp insert_post(tenant_id, title, category) do
    {:ok, post} =
      %Post{}
      |> Post.changeset(%{
        title: title,
        body: "Stable host tenant fixture",
        status: "published",
        tenant_id: tenant_id,
        category: category
      })
      |> Repo.insert()

    post
  end

  defp await_task!(task, config) do
    assert {:ok, %{id: id, state: :succeeded}} =
             Scrypath.Meilisearch.Tasks.wait_for_task(
               task,
               Keyword.put(config, :inline_timeout, 30_000)
             )

    id
  end

  defp assert_filterable_settings!(index, config) do
    assert {:ok, %{"filterableAttributes" => attributes}} =
             Scrypath.Meilisearch.Client.get_settings(index, config)

    names =
      Enum.flat_map(attributes, fn
        name when is_binary(name) -> [name]
        %{"attributePatterns" => patterns} when is_list(patterns) -> patterns
        _ -> []
      end)

    assert Enum.all?(["tenant_id", "status", "category"], &(&1 in names))
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
