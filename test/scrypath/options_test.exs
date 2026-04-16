defmodule Scrypath.OptionsTest do
  use ExUnit.Case, async: true

  import Ecto.Query

  alias Scrypath.Config
  alias Scrypath.TestSupport.FakeBackend

  setup do
    original_defaults = Application.get_env(:scrypath, :defaults)

    on_exit(fn ->
      if original_defaults == nil do
        Application.delete_env(:scrypath, :defaults)
      else
        Application.put_env(:scrypath, :defaults, original_defaults)
      end
    end)

    :ok
  end

  test "validate_runtime_options!/1 accepts Meilisearch and inline waiting options" do
    config =
      Scrypath.Options.validate_runtime_options!(
        backend: FakeBackend,
        meilisearch_url: "http://localhost:7700",
        meilisearch_api_key: "secret",
        inline_poll_interval: 250,
        inline_timeout: 9_000
      )

    assert config[:backend] == FakeBackend
    assert config[:meilisearch_url] == "http://localhost:7700"
    assert config[:meilisearch_api_key] == "secret"
    assert config[:inline_poll_interval] == 250
    assert config[:inline_timeout] == 9_000
  end

  test "Scrypath.Config.resolve!/1 merges defaults and explicit runtime options" do
    Application.put_env(:scrypath, :defaults,
      backend: FakeBackend,
      meilisearch_url: "http://defaults.test:7700",
      meilisearch_api_key: "default-key",
      inline_poll_interval: 150,
      inline_timeout: 7_500
    )

    config =
      Config.resolve!(
        meilisearch_api_key: "explicit-key",
        inline_timeout: 12_000
      )

    assert config[:backend] == FakeBackend
    assert Config.fetch_meilisearch_url!(config) == "http://defaults.test:7700"
    assert Config.meilisearch_api_key(config) == "explicit-key"
    assert Config.inline_poll_interval(config) == 150
    assert Config.inline_timeout(config) == 12_000
  end

  test "validate_runtime_options!/1 rejects invalid inline waiting values" do
    assert_raise ArgumentError, ~r/inline_poll_interval/, fn ->
      Scrypath.Options.validate_runtime_options!(
        backend: FakeBackend,
        inline_poll_interval: 0
      )
    end

    assert_raise ArgumentError, ~r/inline_timeout/, fn ->
      Scrypath.Options.validate_runtime_options!(
        backend: FakeBackend,
        inline_timeout: -1
      )
    end

    assert_raise ArgumentError, ~r/meilisearch_url/, fn ->
      Scrypath.Options.validate_runtime_options!(
        backend: FakeBackend,
        meilisearch_url: 123
      )
    end
  end

  test "validate_backfill_options!/1 requires backend and repo and accepts explicit overrides" do
    query = from("posts")

    config =
      Scrypath.Options.validate_backfill_options!(
        backend: FakeBackend,
        repo: Scrypath.TestRepo,
        batch_size: 500,
        query: query,
        index_prefix: "tenant",
        index_name: "posts_v2",
        settings: %{filterableAttributes: ["status"]},
        meilisearch_url: "http://localhost:7700",
        inline_poll_interval: 250,
        inline_timeout: 6_000,
        sync_mode: :manual
      )

    assert config[:backend] == FakeBackend
    assert config[:repo] == Scrypath.TestRepo
    assert config[:batch_size] == 500
    assert config[:query] == query
    assert config[:index_prefix] == "tenant"
    assert config[:index_name] == "posts_v2"
    assert config[:settings] == %{filterableAttributes: ["status"]}
    assert config[:meilisearch_url] == "http://localhost:7700"
    assert config[:inline_poll_interval] == 250
    assert config[:inline_timeout] == 6_000
    assert config[:sync_mode] == :manual
  end

  test "validate_reindex_options!/1 requires backend and repo and validates cutover contract" do
    config =
      Scrypath.Options.validate_reindex_options!(
        backend: FakeBackend,
        repo: Scrypath.TestRepo,
        batch_size: 1_000,
        index_prefix: "tenant",
        target_index: "posts_tmp",
        cutover?: false,
        settings: %{sortableAttributes: ["inserted_at"]},
        meilisearch_url: "http://localhost:7700",
        inline_poll_interval: 200,
        inline_timeout: 8_000,
        sync_mode: :manual
      )

    assert config[:backend] == FakeBackend
    assert config[:repo] == Scrypath.TestRepo
    assert config[:batch_size] == 1_000
    assert config[:index_prefix] == "tenant"
    assert config[:target_index] == "posts_tmp"
    assert config[:cutover?] == false
    assert config[:settings] == %{sortableAttributes: ["inserted_at"]}
    assert config[:meilisearch_url] == "http://localhost:7700"
    assert config[:inline_poll_interval] == 200
    assert config[:inline_timeout] == 8_000
    assert config[:sync_mode] == :manual
  end

  test "bulk workflow validators reject impossible values before execution" do
    assert_raise ArgumentError, ~r/repo/, fn ->
      Scrypath.Options.validate_backfill_options!(
        backend: FakeBackend,
        batch_size: 100
      )
    end

    assert_raise ArgumentError, ~r/batch_size/, fn ->
      Scrypath.Options.validate_backfill_options!(
        backend: FakeBackend,
        repo: Scrypath.TestRepo,
        batch_size: 0
      )
    end

    assert_raise ArgumentError, ~r/sync_mode/, fn ->
      Scrypath.Options.validate_backfill_options!(
        backend: FakeBackend,
        repo: Scrypath.TestRepo,
        batch_size: 100,
        sync_mode: :oban
      )
    end

    assert_raise ArgumentError, ~r/sync_mode/, fn ->
      Scrypath.Options.validate_reindex_options!(
        backend: FakeBackend,
        repo: Scrypath.TestRepo,
        batch_size: 100,
        sync_mode: :oban
      )
    end
  end
end
