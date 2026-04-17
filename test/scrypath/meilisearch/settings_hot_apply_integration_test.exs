defmodule Scrypath.Meilisearch.SettingsHotApplyIntegrationTest do
  use ExUnit.Case, async: false

  alias Scrypath.Meilisearch.Settings
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
  test "hot_apply stop_words against live index", %{
    index_prefix: prefix,
    live_index: live_index
  } do
    _ = System.get_env("SCRYPATH_INTEGRATION")

    url = MeilisearchIntegration.meilisearch_url!()

    post = %QueryablePost{
      id: 1,
      title: "Hot apply",
      body: "Body",
      status: "published",
      inserted_at: DateTime.utc_now()
    }

    assert {:ok, %{mode: :inline, status: :completed}} =
             Scrypath.sync_record(QueryablePost, post,
               backend: Scrypath.Meilisearch,
               index_prefix: prefix,
               meilisearch_url: url
             )

    assert :ok = MeilisearchIntegration.wait_for_search_count!(QueryablePost, live_index, 1)

    assert {:ok, %{task: %{status: :succeeded}}} =
             Settings.hot_apply(QueryablePost, live_index,
               acknowledge_live_index: true,
               backend: Scrypath.Meilisearch,
               meilisearch_url: url,
               index_prefix: prefix,
               sync_mode: :inline,
               inline_poll_interval: 100,
               inline_timeout: 10_000,
               settings: %{stop_words: ["the"]}
             )

    settings = MeilisearchIntegration.fetch_settings!(live_index)
    assert "the" in (settings["stopWords"] || [])
  end
end
