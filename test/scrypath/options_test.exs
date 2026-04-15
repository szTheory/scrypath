defmodule Scrypath.OptionsTest do
  use ExUnit.Case, async: true

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
end
