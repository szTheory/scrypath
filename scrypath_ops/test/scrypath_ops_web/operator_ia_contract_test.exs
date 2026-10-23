defmodule ScrypathOpsWeb.OperatorIaContractTest do
  use ExUnit.Case, async: true

  alias ScrypathOpsWeb.Nav

  # Paths from this file: test/scrypath_ops_web → app root.
  @operator_ia Path.join([__DIR__, "..", "..", "docs", "operator-ia.md"]) |> File.read!()
  @router Path.join([__DIR__, "..", "..", "lib", "scrypath_ops_web", "router.ex"]) |> File.read!()
  @posture_live Path.join([
                  __DIR__,
                  "..",
                  "..",
                  "lib",
                  "scrypath_ops_web",
                  "live",
                  "posture_live.ex"
                ])
                |> File.read!()
  @failed_sync_live Path.join([
                      __DIR__,
                      "..",
                      "..",
                      "lib",
                      "scrypath_ops_web",
                      "live",
                      "failed_sync_live.ex"
                    ])
                    |> File.read!()
  @sync_drift_live Path.join([
                     __DIR__,
                     "..",
                     "..",
                     "lib",
                     "scrypath_ops_web",
                     "live",
                     "sync_drift_live.ex"
                   ])
                   |> File.read!()

  defp ops_live_session_inner(router_source) do
    [_before, after_ops] = String.split(router_source, "live_session :ops", parts: 2)
    [inner | _] = String.split(after_ops, "\n    end\n", parts: 2)
    inner
  end

  defp ops_live_paths(router_source) do
    inner = ops_live_session_inner(router_source)

    ~r/live\("([^"]+)"/
    |> Regex.scan(inner, capture: :all_but_first)
    |> List.flatten()
    |> Enum.map(fn segment ->
      segment = String.trim_leading(segment, "/")
      "/ops/#{segment}"
    end)
  end

  test "guide starts with tasks and keeps the operational distinctions" do
    assert @operator_ia =~ "## Start with your task"
    assert @operator_ia =~ "## Navigation"
    assert @operator_ia =~ "Oban jobs"
    assert @operator_ia =~ "Meilisearch tasks"
    assert @operator_ia =~ "not a completed update"
  end

  test "guide documents the current flat navigation and legacy routes" do
    assert @operator_ia =~ "| Destination | Default route | Purpose |"
    assert @operator_ia =~ "/ops/posture"
    assert @operator_ia =~ "Manage saved searches"
    refute @operator_ia =~ "| Saved searches |"
  end

  test "machine-readable nav JSON stays hidden from the rendered guide" do
    assert Regex.match?(~r/<!--\s*\[\{"route":/, @operator_ia)

    visible_markdown = Regex.replace(~r/<!--.*?-->/s, @operator_ia, "")
    refute Regex.match?(~r/^\s*\[\{"route":/m, visible_markdown)
  end

  test "every live /ops route in router.ex is documented in operator-ia.md" do
    assert @router =~ ~s(live("/health")
    assert @router =~ "live(\"/posture\", ScrypathOpsWeb.PostureLive, :legacy)"
    assert @router =~ ~s(live("/failed-sync")
    assert @router =~ ~s(live("/sync-and-index")
    assert @router =~ "live(\"/sync-drift\", ScrypathOpsWeb.SyncDriftLive, :legacy)"
    assert @router =~ ~s(live("/search")
    assert @router =~ "live(\"/playbooks\", ScrypathOpsWeb.SearchLive, :legacy_saved_searches)"

    for path <-
          ~w(/ops/health /ops/failed-sync /ops/sync-and-index /ops/sync-drift /ops/search /ops/playbooks /ops/search?saved=manage) do
      assert String.contains?(@operator_ia, path),
             "expected operator-ia.md to mention #{path} for router parity (phase 47 D-07 / D-17)"
    end
  end

  test "Nav.primary/0 exposes five ordered ops routes with canonical labels" do
    items = Nav.primary()
    assert length(items) == 5

    expected_path_strings = [
      "/ops/search",
      "/ops/health",
      "/ops/failed-sync",
      "/ops/sync-and-index",
      "/ops/help"
    ]

    expected_labels = [
      "Search",
      "Search health",
      "Failed sync work",
      "Sync and index",
      "Help"
    ]

    assert Enum.map(items, &(&1.path |> to_string())) == expected_path_strings
    assert Enum.map(items, & &1.label) == expected_labels

    assert Enum.map(items, & &1.title) == expected_labels
  end

  test "every live route in live_session :ops appears in Nav.primary/0" do
    nav_path_strings =
      Nav.primary()
      |> Enum.map(fn %{path: p} -> p |> to_string() end)
      |> MapSet.new()

    for ops_path <- ops_live_paths(@router),
        ops_path not in ["/ops/", "/ops/posture", "/ops/playbooks", "/ops/sync-drift"] do
      assert MapSet.member?(nav_path_strings, ops_path),
             "expected Nav.primary/0 to include #{inspect(ops_path)} for router :ops parity"
    end
  end

  test "incident handoffs use exact allowlisted schema identity and expose triage first" do
    assert @posture_live =~ "OperatorSelection.path(@mount_path, \"failed-sync\", mod)"
    assert @failed_sync_live =~ "def handle_params(params, _uri, socket)"

    assert @failed_sync_live =~
             "OperatorSelection.path(@mount_path, \"sync-and-index\", @selected_schema)"

    assert @sync_drift_live =~ "def handle_params(params, _uri, socket)"

    assert @sync_drift_live =~
             "OperatorSelection.path(@mount_path, \"health\", @selected_schema)"

    assert @failed_sync_live =~ "phx-click=\"retry\""
    assert @failed_sync_live =~ "summary=\"Job details\""
  end
end
