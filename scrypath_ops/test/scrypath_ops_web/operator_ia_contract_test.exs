defmodule ScrypathOpsWeb.OperatorIaContractTest do
  use ExUnit.Case, async: true

  # Paths from this file: test/scrypath_ops_web → app root.
  @operator_ia Path.join([__DIR__, "..", "..", "docs", "operator-ia.md"]) |> File.read!()
  @router Path.join([__DIR__, "..", "..", "lib", "scrypath_ops_web", "router.ex"]) |> File.read!()

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

    for path <- ~w(/ops/posture /ops/failed-sync /ops/sync-drift /ops/search) do
      assert String.contains?(@operator_ia, path),
             "expected operator-ia.md to mention #{path} for router parity (phase 47 D-07 / D-17)"
    end
  end
end
