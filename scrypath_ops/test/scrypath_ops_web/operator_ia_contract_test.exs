defmodule ScrypathOpsWeb.OperatorIaContractTest do
  use ExUnit.Case, async: true

  alias ScrypathOpsWeb.Nav

  # Paths from this file: test/scrypath_ops_web → app root.
  @operator_ia Path.join([__DIR__, "..", "..", "docs", "operator-ia.md"]) |> File.read!()
  @router Path.join([__DIR__, "..", "..", "lib", "scrypath_ops_web", "router.ex"]) |> File.read!()

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
    assert @operator_ia =~ "/ops/posture"
  end

  test "every live /ops route in router.ex is documented in operator-ia.md" do
    assert @router =~ ~s(live("/posture")
    assert @router =~ ~s(live("/failed-sync")
    assert @router =~ ~s(live("/sync-drift")
    assert @router =~ ~s(live("/search")
    assert @router =~ ~s(live("/playbooks")

    for path <- ~w(/ops/posture /ops/failed-sync /ops/sync-drift /ops/search /ops/playbooks) do
      assert String.contains?(@operator_ia, path),
             "expected operator-ia.md to mention #{path} for router parity (phase 47 D-07 / D-17)"
    end
  end

  test "Nav.primary/0 exposes five ordered ops routes with canonical labels" do
    items = Nav.primary()
    assert length(items) == 5

    expected_path_strings = [
      "/ops/posture",
      "/ops/failed-sync",
      "/ops/sync-drift",
      "/ops/search",
      "/ops/playbooks"
    ]

    expected_labels = [
      "Posture / health",
      "Failed sync work",
      "Sync / drift",
      "Search & federation",
      "Saved playbooks"
    ]

    assert Enum.map(items, &(&1.path |> to_string())) == expected_path_strings
    assert Enum.map(items, & &1.label) == expected_labels
  end

  test "every live route in live_session :ops appears in Nav.primary/0" do
    nav_path_strings =
      Nav.primary()
      |> Enum.map(fn %{path: p} -> p |> to_string() end)
      |> MapSet.new()

    for ops_path <- ops_live_paths(@router) do
      assert MapSet.member?(nav_path_strings, ops_path),
             "expected Nav.primary/0 to include #{inspect(ops_path)} for router :ops parity"
    end
  end
end
