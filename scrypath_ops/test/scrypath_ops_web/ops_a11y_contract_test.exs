defmodule ScrypathOpsWeb.OpsA11yContractTest do
  @moduledoc false
  # Phase 50 OPSUX-07: DOM semantics contracts for critical `/ops` routes (D-18).

  use ScrypathOpsWeb.ConnCase, async: false

  @moduletag :opsui_a11y

  import Phoenix.LiveViewTest

  alias ScrypathOps.Test.OpsPostA
  alias ScrypathOps.Test.OpsPostB
  alias ScrypathOps.Test.SearchPlaygroundStubAdapter

  defmodule OpsA11yContractMeili do
    @moduledoc false
    def tasks(filters, config) do
      uids = filters[:index_uids] || []

      if "a11y_ops_post_a" in uids do
        {:error, :boom}
      else
        {:ok, %{results: Keyword.get(config, :meilisearch_tasks, [])}}
      end
    end

    def get_settings(_index, _config), do: {:error, :settings}
  end

  defmodule OpsA11yContractObanInspector do
    @moduledoc false
    def list_jobs(_schema_module, config) do
      {:ok, Keyword.get(config, :oban_jobs, [])}
    end
  end

  defmodule RecordingOban do
    @moduledoc false
    def insert(changeset) do
      job = Ecto.Changeset.apply_changes(changeset)
      {:ok, %{job | id: 992, state: "available"}}
    end
  end

  setup do
    keys = ~w(
      schema_allowlist backend sync_mode index_prefix meilisearch_url meilisearch_client
      meilisearch_tasks oban oban_queue oban_inspector oban_jobs search_playground_adapter
      search_stub_variant
    )a

    previous = Map.new(keys, &{&1, Application.get_env(:scrypath_ops, &1)})

    Application.put_env(:scrypath_ops, :schema_allowlist, [OpsPostA, OpsPostB])
    Application.put_env(:scrypath_ops, :backend, Scrypath.Meilisearch)
    Application.put_env(:scrypath_ops, :sync_mode, :manual)
    Application.put_env(:scrypath_ops, :index_prefix, "a11y")
    Application.put_env(:scrypath_ops, :meilisearch_url, "http://localhost:7700")
    Application.put_env(:scrypath_ops, :meilisearch_client, OpsA11yContractMeili)

    Application.put_env(:scrypath_ops, :meilisearch_tasks, [
      %{
        "uid" => 1,
        "status" => "succeeded",
        "type" => "documentAdditionOrUpdate",
        "indexUid" => "a11y_ops_post_b",
        "finishedAt" => "2026-04-16T18:00:00Z"
      }
    ])

    Application.put_env(:scrypath_ops, :oban, RecordingOban)
    Application.put_env(:scrypath_ops, :oban_queue, :search_sync)
    Application.put_env(:scrypath_ops, :oban_inspector, OpsA11yContractObanInspector)

    Application.put_env(:scrypath_ops, :oban_jobs, [
      %{
        id: 502,
        state: "retryable",
        worker: "Scrypath.Oban.UpsertWorker",
        queue: "search_sync",
        args: %{
          "operation" => "upsert",
          "schema" => "Elixir.ScrypathOps.Test.OpsPostA",
          "backend" => "Elixir.Scrypath.Meilisearch",
          "index" => "a11y_ops_post_a",
          "document_count" => 1,
          "document_ids" => [1],
          "documents" => [
            %{"id" => 1, "data" => %{"title" => "One"}, "source" => "fields"}
          ]
        }
      }
    ])

    Application.put_env(:scrypath_ops, :search_playground_adapter, SearchPlaygroundStubAdapter)
    Application.put_env(:scrypath_ops, :search_stub_variant, :ok)

    on_exit(fn ->
      Enum.each(previous, fn
        {k, nil} -> Application.delete_env(:scrypath_ops, k)
        {k, v} -> Application.put_env(:scrypath_ops, k, v)
      end)
    end)

    :ok
  end

  defp assert_ops_a11y_shell!(html, search: search?) do
    assert html =~ ~s(id="ops-main")
    assert html =~ ~s(href="#ops-main")
    assert html =~ "Skip to operator content"
    assert html =~ ~s(<header class="ops-header)
    assert html =~ ~s(aria-label="Operator primary")
    assert html =~ ~s(id="ops-page-title")

    assert html =~ ~r/<main[^>]*\bid="ops-main"/
    assert html =~ ~r/<main[^>]*\baria-labelledby="ops-page-title"/

    h1_opens = Regex.scan(~r/<h1\b/, html)
    assert length(h1_opens) == 1, "expected exactly one page h1, got #{length(h1_opens)}"

    if search? do
      assert html =~ "<fieldset"
      assert html =~ "<legend"
    end
  end

  describe "ops DOM semantics" do
    test "/ops/posture", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/ops/posture")
      assert_ops_a11y_shell!(html, search: false)
    end

    test "/ops/failed-sync", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/ops/failed-sync")
      assert_ops_a11y_shell!(html, search: false)
    end

    test "/ops/sync-drift", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/ops/sync-drift")
      assert_ops_a11y_shell!(html, search: false)
    end

    test "/ops/search", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/ops/search")
      assert_ops_a11y_shell!(html, search: true)
    end
  end
end
