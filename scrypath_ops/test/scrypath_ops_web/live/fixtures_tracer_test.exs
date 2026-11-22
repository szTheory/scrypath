defmodule ScrypathOpsWeb.FixturesTracerTest do
  @moduledoc false
  # Phase 196 tracer: the Logistify builders emit raw wire shapes, the fake client and inspector hand
  # them to the real Scrypath code, and /ops/health renders the result. App env is global, so this
  # module is async: false and restores every key it touches.
  use ScrypathOpsWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias ScrypathFixtures.Logistify
  alias ScrypathOps.Test.FixtureEnv

  setup do
    scenario = Logistify.scenario(:deep_queue, now: ScrypathFixtures.preview_epoch())
    on_exit(FixtureEnv.put(scenario))
    %{scenario: scenario}
  end

  test "Logistify deep queue renders a neutral pending verdict with nothing failed", %{conn: conn} do
    {:ok, lv, _document} = live(conn, ~p"/ops/health")

    assert has_element?(
             lv,
             ".ops-verdict[data-verdict-kind='neutral'] [data-sync-status='pending']"
           )

    refute has_element?(lv, "[data-sync-status='failed']")

    headline =
      lv
      |> element(".ops-posture-verdict p.text-ops-h2")
      |> render()
      |> LazyHTML.from_fragment()
      |> LazyHTML.text()

    assert headline =~ "No sync failures found"
  end
end
