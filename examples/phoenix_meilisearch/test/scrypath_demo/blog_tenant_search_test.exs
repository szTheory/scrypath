defmodule ScrypathDemo.BlogTenantSearchTest do
  use ScrypathDemo.DataCase, async: false

  alias ScrypathDemo.Blog
  alias ScrypathDemo.Blog.Post
  alias ScrypathDemo.Repo

  defmodule RecordingBackend do
    @behaviour Scrypath.Backend

    alias Scrypath.Query

    @impl true
    def name, do: :blog_tenant_search_test

    @impl true
    def index_name(_schema_module, _config), do: "blog_tenant_search_test"

    @impl true
    def upsert_documents(_schema_module, _documents, _config), do: {:ok, []}

    @impl true
    def delete_documents(_schema_module, _document_ids, _config), do: {:ok, []}

    @impl true
    def search(schema_module, %Query{} = query, _config) do
      send(self(), {:tenant_search, schema_module, query})

      {:ok,
       Process.get({__MODULE__, :search_response}, %{
         "hits" => [],
         "page" => 1,
         "hitsPerPage" => 20,
         "totalHits" => 0
       })}
    end

    @impl true
    def search_facet_values(schema_module, facet_name, facet_query, opts, _config) do
      send(self(), {:tenant_facet_search, schema_module, facet_name, facet_query, opts})
      {:ok, %{"facetHits" => [], "facetQuery" => facet_query}}
    end
  end

  setup do
    tenant_a = 166_101
    tenant_b = 166_102

    actor_a = insert_actor_with_membership(tenant_a)
    actor_b = insert_actor_with_membership(tenant_b)
    actor_without_membership = insert_actor()

    %{
      tenant_a: tenant_a,
      tenant_b: tenant_b,
      actor_a: actor_a,
      actor_b: actor_b,
      actor_without_membership: actor_without_membership,
      runtime_opts: [backend: RecordingBackend, repo: Repo]
    }
  end

  test "authorized search and facet calls dispatch with membership-derived scope", context do
    assert {:ok, %{search: %Scrypath.SearchResult{query: search_query, records: []}}} =
             Blog.search_posts(
               context.actor_a,
               context.tenant_a,
               %{"q" => "term", "category" => "phone-a"},
               context.runtime_opts
             )

    expected_search_filter = [
      tenant_id: context.tenant_a,
      status: "published",
      category: "phone-a"
    ]

    assert MapSet.new(search_query.filter) == MapSet.new(expected_search_filter)
    assert_receive {:tenant_search, Post, %Scrypath.Query{filter: recorded_search_filter}}
    assert MapSet.new(recorded_search_filter) == MapSet.new(expected_search_filter)

    assert {:ok, %Scrypath.FacetSearchResult{facet_query: "pho"}} =
             Blog.search_post_categories(
               context.actor_a,
               context.tenant_a,
               %{"facet_query" => "pho"},
               context.runtime_opts
             )

    assert_receive {:tenant_facet_search, Post, "category", "pho", facet_opts}

    assert MapSet.new(Keyword.fetch!(facet_opts, :filter)) ==
             MapSet.new(tenant_id: context.tenant_a, status: "published")

    refute_receive {:tenant_search, _, _}
    refute_receive {:tenant_facet_search, _, _, _, _}
  end

  test "invalid principals and unowned tenant selections stop before dispatch", context do
    invalid_cases = [
      {nil, context.tenant_a},
      {%{id: 9_999_999_999}, context.tenant_a},
      {context.actor_without_membership, context.tenant_a},
      {context.actor_a, context.tenant_b},
      {:invalid_principal, context.tenant_a},
      {%{"id" => context.actor_a.id}, context.tenant_a},
      {%{id: 0}, context.tenant_a}
    ]

    for {principal, tenant_id} <- invalid_cases do
      assert {:error, :unauthorized} =
               Blog.search_posts(principal, tenant_id, %{"q" => "term"}, context.runtime_opts)

      assert {:error, :unauthorized} =
               Blog.search_post_categories(
                 principal,
                 tenant_id,
                 %{"facet_query" => "pho"},
                 context.runtime_opts
               )

      refute_receive {:tenant_search, _, _}
      refute_receive {:tenant_facet_search, _, _, _, _}
    end
  end

  test "scope and runtime overrides in string or atom keys stop before dispatch", context do
    overrides = [
      {"tenant_scope", :tenant_scope, context.tenant_b},
      {"tenant_id", :tenant_id, context.tenant_b},
      {"filter", :filter, [status: "draft"]},
      {"repo", :repo, Repo},
      {"backend", :backend, RecordingBackend},
      {"index_name", :index_name, "outside_index"},
      {"index_prefix", :index_prefix, "outside_prefix"},
      {"meilisearch_url", :meilisearch_url, "http://outside.invalid"},
      {"req_options", :req_options, [retry: false]},
      {"configuration", :configuration, %{tenant_scope: context.tenant_b}}
    ]

    for {string_key, atom_key, value} <- overrides, key <- [string_key, atom_key] do
      search_params = Map.put(%{"q" => "term"}, key, value)
      facet_params = Map.put(%{"facet_query" => "pho"}, key, value)

      assert {:error, :invalid_search_input} =
               Blog.search_posts(
                 context.actor_a,
                 context.tenant_a,
                 search_params,
                 context.runtime_opts
               )

      assert {:error, :invalid_search_input} =
               Blog.search_post_categories(
                 context.actor_a,
                 context.tenant_a,
                 facet_params,
                 context.runtime_opts
               )

      refute_receive {:tenant_search, _, _}
      refute_receive {:tenant_facet_search, _, _, _, _}
    end
  end

  test "malformed or wrongly typed ordinary params stop before dispatch", context do
    for params <- [
          nil,
          "term",
          %{"q" => 123},
          %{"category" => false},
          %{"q" => nil},
          %{q: "term"}
        ] do
      assert {:error, :invalid_search_input} =
               Blog.search_posts(context.actor_a, context.tenant_a, params, context.runtime_opts)

      refute_receive {:tenant_search, _, _}
    end

    for params <- [nil, "pho", %{}, %{"facet_query" => 123}, %{"facet_query" => nil}] do
      assert {:error, :invalid_search_input} =
               Blog.search_post_categories(
                 context.actor_a,
                 context.tenant_a,
                 params,
                 context.runtime_opts
               )

      refute_receive {:tenant_facet_search, _, _, _, _}
    end
  end

  test "host hydration restricts rows by tenant and hit IDs while retaining raw hits", context do
    post_a = insert_post(context.tenant_a, "authorized A")
    post_b = insert_post(context.tenant_b, "foreign B")

    Process.put({RecordingBackend, :search_response}, %{
      "hits" => [
        %{"id" => post_a.id, "title" => "authorized A", "tenant_id" => context.tenant_a},
        %{"id" => post_b.id, "title" => "foreign B", "tenant_id" => context.tenant_b}
      ],
      "page" => 1,
      "hitsPerPage" => 20,
      "totalHits" => 2
    })

    try do
      assert {:ok, %{search: result, records: [%Post{id: authorized_id, tenant_id: tenant_id}]}} =
               Blog.search_posts(
                 context.actor_a,
                 context.tenant_a,
                 %{"q" => "term"},
                 context.runtime_opts
               )

      assert authorized_id == post_a.id
      assert tenant_id == context.tenant_a

      assert Enum.map(result.raw["hits"], &to_string(&1["id"])) ==
               Enum.map([post_a, post_b], &to_string(&1.id))

      assert result.records == []
    after
      Process.delete({RecordingBackend, :search_response})
    end
  end

  defp insert_actor do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    {1, [%{id: actor_id}]} =
      Repo.insert_all(
        "host_actors",
        [%{name: "synthetic-actor", inserted_at: now, updated_at: now}],
        returning: [:id]
      )

    %{id: actor_id}
  end

  defp insert_actor_with_membership(tenant_id) do
    %{id: actor_id} = actor = insert_actor()
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    Repo.insert_all("host_memberships", [
      %{actor_id: actor_id, tenant_id: tenant_id, inserted_at: now, updated_at: now}
    ])

    actor
  end

  defp insert_post(tenant_id, title) do
    {:ok, post} =
      %Post{}
      |> Post.changeset(%{
        title: title,
        body: "Recorder response fixture",
        status: "published",
        tenant_id: tenant_id,
        category: "phone-a"
      })
      |> Repo.insert()

    post
  end
end
