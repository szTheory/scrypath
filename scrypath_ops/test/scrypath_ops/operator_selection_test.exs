defmodule ScrypathOps.OperatorSelectionTest do
  use ExUnit.Case, async: true

  alias ScrypathOps.OperatorSelection
  alias ScrypathOps.Test.OpsPostA
  alias ScrypathOps.Test.OpsPostB

  test "overview URLs discard selection while retaining unrelated parameters and mount paths" do
    assert OperatorSelection.overview_path("http://localhost/mounted/ops/health?schema=Gone") ==
             "/mounted/ops/health"

    uri = "http://localhost/mounted/ops?scenario=errors&schema=&note=%C3%89clair#checks"
    parsed = uri |> OperatorSelection.overview_path() |> URI.parse()
    assert parsed.path == "/mounted/ops"
    assert URI.decode_query(parsed.query) == %{"scenario" => "errors", "note" => "Éclair"}
    assert parsed.fragment == "checks"
    assert parsed.host == nil

    assert OperatorSelection.path("/mounted/ops/", "health", OpsPostB) ==
             "/mounted/ops/health"
  end

  test "resolves the first allowlisted schema only when the query is absent" do
    assert OperatorSelection.resolve(%{}, [OpsPostA, OpsPostB]) == {:ok, OpsPostA}
    assert OperatorSelection.resolve(%{"schema" => ""}, [OpsPostA]) == :unavailable
  end

  test "distinguishes empty setup from an unavailable explicit selection" do
    assert OperatorSelection.resolve(%{}, []) == :setup

    assert OperatorSelection.resolve(%{"schema" => "ScrypathOps.Test.Removed"}, [OpsPostA]) ==
             :unavailable

    assert OperatorSelection.resolve(%{"schema" => " ScrypathOps.Test.OpsPostA"}, [OpsPostA]) ==
             :unavailable
  end

  test "canonical names and paths preserve exact UTF-8 identity and mounted paths" do
    assert OperatorSelection.canonical(OpsPostB) == "ScrypathOps.Test.OpsPostB"

    assert OperatorSelection.resolve(%{"schema" => OperatorSelection.canonical(OpsPostB)}, [
             OpsPostA,
             OpsPostB
           ]) ==
             {:ok, OpsPostB}

    assert OperatorSelection.path("/mounted/ops", "failed-sync", OpsPostB) ==
             "/mounted/ops/failed-sync?schema=ScrypathOps.Test.OpsPostB"

    assert OperatorSelection.path("/ops", "failed-sync", OpsPostA) ==
             "/ops/failed-sync?schema=ScrypathOps.Test.OpsPostA"

    unicode = :"Elixir.ScrypathOps.Test.Éclair"
    encoded = OperatorSelection.path("/ops", "failed-sync", unicode)
    assert encoded == "/ops/failed-sync?schema=ScrypathOps.Test.%C3%89clair"

    assert URI.decode_query(URI.parse(encoded).query)["schema"] ==
             OperatorSelection.canonical(unicode)

    assert OperatorSelection.resolve(%{"schema" => OperatorSelection.canonical(unicode)}, [
             unicode
           ]) ==
             {:ok, unicode}
  end

  test "hostile values never create atoms or resolve outside the allowlist" do
    hostile = "Elixir.ScrypathOps.Test.OpsPostA&schema=Elixir.Evil"

    assert OperatorSelection.resolve(%{"schema" => hostile}, [OpsPostA]) == :unavailable

    refute OperatorSelection.resolve(%{"schema" => "Elixir.ScrypathOps.Test.OpsPostA"}, [OpsPostA]) ==
             {:ok, OpsPostA}
  end
end
