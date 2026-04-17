defmodule Scrypath.SearchManyIntegrationTest do
  use ExUnit.Case, async: false

  alias Scrypath.TestSupport.IntegrationRepo
  alias Scrypath.TestSupport.MeilisearchIntegration

  @moduletag :integration

  setup_all do
    database = MeilisearchIntegration.setup_repo!()

    on_exit(fn ->
      MeilisearchIntegration.cleanup_repo!(database)
    end)

    :ok
  end

  setup do
    MeilisearchIntegration.reset_repo!()
    prefix = MeilisearchIntegration.index_prefix()
    live_index = "#{prefix}_queryable_post"

    on_exit(fn ->
      MeilisearchIntegration.delete_indexes([live_index])
    end)

    %{index_prefix: prefix, live_index: live_index}
  end

  @tag timeout: 60_000
  test "singleton Scrypath.search_many/2 facet envelope matches Scrypath.search/3", %{
    index_prefix: prefix,
    live_index: live_index
  } do
    # SCRYPATH_INTEGRATION is honored via ExUnit `:integration` tagging (see test_helper.exs).
    _ = System.get_env("SCRYPATH_INTEGRATION")

    url = MeilisearchIntegration.meilisearch_url!()

    post = %QueryablePost{
      id: 1,
      title: "Facet parity",
      body: "Body",
      status: "published",
      inserted_at: DateTime.utc_now()
    }

    assert {:ok, %{mode: :inline, status: :completed, task: %{status: :succeeded}}} =
             Scrypath.sync_record(QueryablePost, post,
               backend: Scrypath.Meilisearch,
               index_prefix: prefix,
               meilisearch_url: url
             )

    assert :ok = MeilisearchIntegration.wait_for_search_count!(QueryablePost, live_index, 1)

    opts = [
      backend: Scrypath.Meilisearch,
      meilisearch_url: url,
      index_prefix: prefix,
      repo: IntegrationRepo
    ]

    assert {:ok, solo} = Scrypath.search(QueryablePost, "Facet", opts)

    assert {:ok, multi} =
             Scrypath.search_many(
               [{QueryablePost, "Facet", []}],
               opts
             )

    assert multi.by_schema[QueryablePost].facets == solo.facets
  end
end
