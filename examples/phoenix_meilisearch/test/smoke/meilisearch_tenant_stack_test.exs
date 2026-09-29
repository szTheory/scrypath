defmodule ScrypathDemo.Smoke.MeilisearchTenantStackTest do
  @moduledoc false
  use ScrypathDemo.DataCase, async: false

  alias ScrypathDemo.Blog
  alias ScrypathDemo.Blog.Post
  alias ScrypathDemo.Repo

  @tag :host_tenant
  @tag :integration
  test "authorized tenant search and facet values" do
    started_at = System.monotonic_time(:millisecond)
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
    create_task_id = await_task!(create_task, config)

    {:ok, %{task: settings_task}} = Scrypath.Meilisearch.apply_settings(Post, index, config)
    settings_task_id = await_task!(settings_task, config)
    assert_filterable_settings!(index, config)

    tenant_a = 166_001
    tenant_b = 166_002
    actor_a = insert_actor_with_membership(tenant_a)
    actor_b = insert_actor_with_membership(tenant_b)

    post_a =
      insert_post(
        tenant_a,
        "Phase166 shared A published",
        "Phase166 shared token for A",
        "published",
        "phone-a"
      )

    post_a_draft =
      insert_post(
        tenant_a,
        "Phase166 shared A draft",
        "Phase166 shared token for draft exclusion",
        "draft",
        "phone-draft"
      )

    post_b =
      insert_post(
        tenant_b,
        "Phase166 shared B published",
        "Phase166 shared token and phase166-b-unique-marker",
        "published",
        "phone-b-forbidden"
      )

    for post <- [post_a, post_a_draft, post_b] do
      assert {:ok, %{mode: :inline, status: :completed}} =
               Scrypath.sync_record(Post, post,
                 backend: Scrypath.Meilisearch,
                 sync_mode: :inline,
                 index_prefix: prefix,
                 meilisearch_url: url,
                 inline_poll_interval: 50
               )
    end

    assert {:ok, %{search: result_b, records: records_b}} =
             Blog.search_posts(actor_b, tenant_b, %{"q" => "Phase166 shared"}, config)

    assert raw_hit_ids(result_b) == [to_string(post_b.id)]
    assert result_b.raw["totalHits"] == 1
    post_b_id = post_b.id
    assert [%Post{id: ^post_b_id, tenant_id: ^tenant_b}] = records_b
    assert distribution(result_b) == [{"phone-b-forbidden", 1}]

    assert {:ok, %{search: marker_result, records: marker_records}} =
             Blog.search_posts(actor_b, tenant_b, %{"q" => "phase166-b-unique-marker"}, config)

    assert raw_hit_ids(marker_result) == [to_string(post_b.id)]
    assert [%Post{id: ^post_b_id}] = marker_records

    assert {:ok, %{search: result_a, records: records_a}} =
             Blog.search_posts(actor_a, tenant_a, %{"q" => "Phase166 shared"}, config)

    assert raw_hit_ids(result_a) == [to_string(post_a.id)]
    assert result_a.raw["totalHits"] == 1
    post_a_id = post_a.id
    assert [%Post{id: ^post_a_id, tenant_id: ^tenant_a}] = records_a
    assert result_a.records == []
    assert distribution(result_a) == [{"phone-a", 1}]
    refute Jason.encode!(result_a.raw) =~ "phone-b-forbidden"
    refute Jason.encode!(result_a.raw) =~ "phase166-b-unique-marker"
    refute Jason.encode!(result_a.raw) =~ "phone-draft"

    assert {:ok, facet_a} =
             Blog.search_post_categories(actor_a, tenant_a, %{"facet_query" => "pho"}, config)

    assert {:ok, facet_b} =
             Blog.search_post_categories(actor_b, tenant_b, %{"facet_query" => "pho"}, config)

    assert facet_pairs(facet_a) == [{"phone-a", 1}]
    assert facet_pairs(facet_b) == [{"phone-b-forbidden", 1}]
    refute Jason.encode!(facet_a.raw) =~ "phone-b-forbidden"
    refute Jason.encode!(facet_a.raw) =~ "phone-draft"

    assert {:ok, write_tasks} = Scrypath.Meilisearch.Tasks.list_sync_tasks(index, config)
    assert Enum.all?(write_tasks, &(&1.state == :succeeded and &1.reference.index_uid == index))
    elapsed_ms = System.monotonic_time(:millisecond) - started_at

    IO.puts(
      "SCRYPATH_PHASE166_HOST " <>
        Jason.encode!(%{
          scenario: "authorized tenant search and facet values",
          index: index,
          setup_task_ids: [create_task_id, settings_task_id],
          write_task_ids: write_tasks |> Enum.map(& &1.id) |> Enum.sort(),
          tenant_a_permitted_ids: raw_hit_ids(result_a),
          tenant_a_total_hits: result_a.raw["totalHits"],
          tenant_a_categories: Enum.map(distribution(result_a), &Tuple.to_list/1),
          tenant_a_facet_values: Enum.map(facet_pairs(facet_a), &Tuple.to_list/1),
          tenant_b_permitted_ids: raw_hit_ids(result_b),
          tenant_b_total_hits: result_b.raw["totalHits"],
          tenant_b_categories: Enum.map(distribution(result_b), &Tuple.to_list/1),
          tenant_b_facet_values: Enum.map(facet_pairs(facet_b), &Tuple.to_list/1),
          tenant_b_marker_ids: raw_hit_ids(marker_result),
          elapsed_ms: elapsed_ms
        })
    )
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

  defp insert_post(tenant_id, title, body, status, category) do
    {:ok, post} =
      %Post{}
      |> Post.changeset(%{
        title: title,
        body: body,
        status: status,
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

  defp raw_hit_ids(result) do
    result.raw["hits"]
    |> Enum.map(& &1["id"])
    |> Enum.map(&to_string/1)
    |> Enum.sort()
  end

  defp distribution(result) do
    result.facets.distribution.category
    |> Enum.map(&{&1.value, &1.count})
    |> Enum.sort()
  end

  defp facet_pairs(result) do
    result.hits
    |> Enum.map(&{&1.value, &1.count})
    |> Enum.sort()
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
