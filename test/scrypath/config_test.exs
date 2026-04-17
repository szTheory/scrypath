defmodule Scrypath.ConfigTest do
  use ExUnit.Case, async: false

  alias Scrypath.Config

  defmodule TestRepo do
  end

  setup do
    orig_defaults = Application.get_env(:scrypath, :defaults)
    orig_repo_env = Application.get_env(:scrypath, TestRepo)

    on_exit(fn ->
      if orig_defaults,
        do: Application.put_env(:scrypath, :defaults, orig_defaults),
        else: Application.delete_env(:scrypath, :defaults)

      if orig_repo_env,
        do: Application.put_env(:scrypath, TestRepo, orig_repo_env),
        else: Application.delete_env(:scrypath, TestRepo)
    end)

    :ok
  end

  describe "resolve!/1 three-source cascade (D-10, D-11, TUNE-06)" do
    test "per-call wins over per-repo wins over library-global (D-11)" do
      Application.put_env(:scrypath, :defaults,
        backend: Scrypath.Meilisearch,
        meilisearch_url: "http://global"
      )

      Application.put_env(:scrypath, TestRepo, scrypath: [meilisearch_url: "http://repo"])

      opts =
        Config.resolve!(
          repo: TestRepo,
          otp_app: :scrypath,
          meilisearch_url: "http://call"
        )

      assert opts[:meilisearch_url] == "http://call"
    end

    test "per-repo wins over library-global when per-call omits" do
      Application.put_env(:scrypath, :defaults,
        backend: Scrypath.Meilisearch,
        meilisearch_url: "http://global"
      )

      Application.put_env(:scrypath, TestRepo, scrypath: [meilisearch_url: "http://repo"])

      opts = Config.resolve!(repo: TestRepo, otp_app: :scrypath)
      assert opts[:meilisearch_url] == "http://repo"
    end

    test "library-global applies when per-repo omits" do
      Application.put_env(:scrypath, :defaults,
        backend: Scrypath.Meilisearch,
        meilisearch_url: "http://global"
      )

      Application.delete_env(:scrypath, TestRepo)

      opts = Config.resolve!(repo: TestRepo, otp_app: :scrypath)
      assert opts[:meilisearch_url] == "http://global"
    end

    test "settings_merge from per-repo when per-call omits (D-10 recipe)" do
      Application.put_env(:scrypath, :defaults,
        backend: Scrypath.Meilisearch,
        meilisearch_url: "http://global"
      )

      Application.put_env(:scrypath, TestRepo, scrypath: [settings_merge: :deep])

      opts = Config.resolve!(repo: TestRepo, otp_app: :scrypath)
      assert opts[:settings_merge] == :deep
    end

    test "no :repo opt skips per-repo lookup" do
      Application.put_env(:scrypath, :defaults,
        backend: Scrypath.Meilisearch,
        meilisearch_url: "http://global"
      )

      opts = Config.resolve!([])
      assert opts[:meilisearch_url] == "http://global"
    end

    test "explicit otp_app resolves per-repo env when repo has no application" do
      Application.put_env(:scrypath, :defaults,
        backend: Scrypath.Meilisearch,
        meilisearch_url: "http://global"
      )

      Application.put_env(:scrypath, TestRepo, scrypath: [meilisearch_url: "http://repo"])

      assert Application.get_application(TestRepo) == nil

      opts = Config.resolve!(repo: TestRepo, otp_app: :scrypath)
      assert opts[:meilisearch_url] == "http://repo"
    end
  end
end
