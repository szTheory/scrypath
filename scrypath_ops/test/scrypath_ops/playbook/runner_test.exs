defmodule ScrypathOps.Playbook.RunnerTest do
  use ExUnit.Case, async: false

  alias ScrypathOps.Playbook.Runner
  alias ScrypathOps.Playbook.V1
  alias ScrypathOps.Schemas
  alias ScrypathOps.Test.OpsPostA
  alias ScrypathOps.Test.OpsPostB
  alias ScrypathOps.Test.SearchPlaygroundStubAdapter

  setup do
    prev_allow = Application.get_env(:scrypath_ops, :schema_allowlist)
    prev_backend = Application.get_env(:scrypath_ops, :backend)
    prev_sync = Application.get_env(:scrypath_ops, :sync_mode)
    prev_prefix = Application.get_env(:scrypath_ops, :index_prefix)
    prev_url = Application.get_env(:scrypath_ops, :meilisearch_url)
    prev_adapter = Application.get_env(:scrypath_ops, :search_playground_adapter)
    prev_stub_variant = Application.get_env(:scrypath_ops, :search_stub_variant)

    Application.put_env(:scrypath_ops, :schema_allowlist, [OpsPostA, OpsPostB])
    Application.put_env(:scrypath_ops, :backend, Scrypath.Meilisearch)
    Application.put_env(:scrypath_ops, :sync_mode, :manual)
    Application.put_env(:scrypath_ops, :index_prefix, "runner_test")
    Application.put_env(:scrypath_ops, :meilisearch_url, "http://localhost:7700")
    Application.put_env(:scrypath_ops, :search_playground_adapter, SearchPlaygroundStubAdapter)
    Application.put_env(:scrypath_ops, :search_stub_variant, :ok)

    on_exit(fn ->
      restore = fn k, v ->
        if v == nil,
          do: Application.delete_env(:scrypath_ops, k),
          else: Application.put_env(:scrypath_ops, k, v)
      end

      restore.(:schema_allowlist, prev_allow)
      restore.(:backend, prev_backend)
      restore.(:sync_mode, prev_sync)
      restore.(:index_prefix, prev_prefix)
      restore.(:meilisearch_url, prev_url)
      restore.(:search_playground_adapter, prev_adapter)
      restore.(:search_stub_variant, prev_stub_variant)
    end)

    :ok
  end

  test "run_validated search dispatches stub adapter after V1.validate/1" do
    raw = %{
      "playbook_format" => 1,
      "mode" => "search",
      "schema" => "ScrypathOps.Test.OpsPostA",
      "q" => "needle",
      "opts" => %{"page" => %{"size" => 5}}
    }

    assert {:ok, map} = V1.validate(raw)

    assert {:ok, res} =
             Runner.run_validated(map, Schemas.allowlist(), Schemas.scrypath_opts())

    assert res.hits == []
  end

  test "run_validated search_many maps entries and dispatches" do
    raw = %{
      "playbook_format" => 1,
      "mode" => "search_many",
      "entries" => [
        ["ScrypathOps.Test.OpsPostA", "a", %{}],
        ["ScrypathOps.Test.OpsPostB", "b", %{}]
      ],
      "opts" => %{}
    }

    assert {:ok, map} = V1.validate(raw)

    assert {:ok, %Scrypath.MultiSearchResult{} = ms} =
             Runner.run_validated(map, Schemas.allowlist(), Schemas.scrypath_opts())

    assert length(ms.ordered) == 2
  end

  test "rejects {:error, _} tuple" do
    assert {:error, :playbook_not_validated} =
             Runner.run_validated({:error, :x}, [OpsPostA], backend: Scrypath.Meilisearch)
  end
end
