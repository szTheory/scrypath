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

  test "operator-ia.md spine: major ## headings appear in JTBD / nav order" do
    assert @operator_ia =~ "## Personas"
    assert @operator_ia =~ "## Jobs-to-be-done"
    assert @operator_ia =~ "## Navigation"

    personas = @operator_ia |> :binary.match("## Personas") |> elem(0)
    jobs = @operator_ia |> :binary.match("## Jobs-to-be-done") |> elem(0)
    nav = @operator_ia |> :binary.match("## Navigation") |> elem(0)

    assert personas < jobs
    assert jobs < nav
  end

  test "operator-ia.md navigation table keeps a Route column for ops surfaces" do
    assert @operator_ia =~ "| Route |"
    assert @operator_ia =~ "/ops/health"
    assert @operator_ia =~ "redirects to `/ops/health`"
  end

  test "every live /ops route in router.ex is documented in operator-ia.md" do
    assert @router =~ ~s(live("/health")
    assert @router =~ "live(\"/posture\", ScrypathOpsWeb.PostureLive, :legacy)"
    assert @router =~ ~s(live("/failed-sync")
    assert @router =~ ~s(live("/sync-drift")
    assert @router =~ ~s(live("/search")
    assert @router =~ ~s(live("/playbooks")

    for path <- ~w(/ops/health /ops/failed-sync /ops/sync-drift /ops/search /ops/playbooks) do
      assert String.contains?(@operator_ia, path),
             "expected operator-ia.md to mention #{path} for router parity (phase 47 D-07 / D-17)"
    end
  end

  test "Nav.primary/0 exposes five ordered ops routes with canonical labels" do
    items = Nav.primary()
    assert length(items) == 5

    expected_path_strings = [
      "/ops/health",
      "/ops/failed-sync",
      "/ops/sync-drift",
      "/ops/search",
      "/ops/playbooks"
    ]

    expected_labels = [
      "Search health",
      "Failed sync work",
      "Sync and drift",
      "Search",
      "Playbooks"
    ]

    assert Enum.map(items, &(&1.path |> to_string())) == expected_path_strings
    assert Enum.map(items, & &1.label) == expected_labels

    assert Enum.map(items, & &1.title) == [
             "Search health",
             "Failed sync work",
             "Sync and drift",
             "Search",
             "Saved playbooks"
           ]
  end

  test "every live route in live_session :ops appears in Nav.primary/0" do
    nav_path_strings =
      Nav.primary()
      |> Enum.map(fn %{path: p} -> p |> to_string() end)
      |> MapSet.new()

    for ops_path <- ops_live_paths(@router), ops_path not in ["/ops/", "/ops/posture"] do
      assert MapSet.member?(nav_path_strings, ops_path),
             "expected Nav.primary/0 to include #{inspect(ops_path)} for router :ops parity"
    end
  end

  test "incident handoffs use exact allowlisted schema identity and expose triage first" do
    assert @posture_live =~ "OperatorSelection.path(@mount_path, \"failed-sync\", mod)"
    assert @failed_sync_live =~ "def handle_params(params, _uri, socket)"

    assert @failed_sync_live =~
             "OperatorSelection.path(@mount_path, \"sync-drift\", @selected_schema)"

    assert @sync_drift_live =~ "def handle_params(params, _uri, socket)"

    assert @sync_drift_live =~
             "OperatorSelection.path(@mount_path, \"health\", @selected_schema)"

    assert @failed_sync_live =~ "Retry sync work"
    assert @failed_sync_live =~ "summary=\"Diagnostics\""
  end
end
