defmodule ScrypathOpsWeb.ControlRoomLiveTest do
  @moduledoc false
  use ScrypathOpsWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  setup do
    prev_allow = Application.get_env(:scrypath_ops, :schema_allowlist)
    prev_backend = Application.get_env(:scrypath_ops, :backend)
    prev_auth_mode = System.get_env("OPSUI_AUTH_MODE")

    # Empty allowlist keeps this test free of a live backend while still exercising
    # the full Control Room chrome (strip + intent cards + jump-to shortcuts).
    Application.put_env(:scrypath_ops, :schema_allowlist, [])
    Application.delete_env(:scrypath_ops, :backend)
    System.put_env("OPSUI_AUTH_MODE", "sigra")

    on_exit(fn ->
      if prev_allow == nil,
        do: Application.delete_env(:scrypath_ops, :schema_allowlist),
        else: Application.put_env(:scrypath_ops, :schema_allowlist, prev_allow)

      if prev_backend == nil,
        do: Application.delete_env(:scrypath_ops, :backend),
        else: Application.put_env(:scrypath_ops, :backend, prev_backend)

      if is_nil(prev_auth_mode),
        do: System.delete_env("OPSUI_AUTH_MODE"),
        else: System.put_env("OPSUI_AUTH_MODE", prev_auth_mode)
    end)

    :ok
  end

  test "the /ops root renders the Control Room landing, not the posture table", %{conn: conn} do
    {:ok, _lv, html} = live(conn, ~p"/ops")

    assert html =~ "Control Room"
    assert html =~ "What do you need to do?"
    # Overview, not the deep per-schema table (that lives on /ops/posture).
    refute html =~ "data-testid=\"posture-row\""
  end

  test "intent cards route by job to the right surfaces", %{conn: conn} do
    {:ok, lv, _html} = live(conn, ~p"/ops")

    assert has_element?(lv, "[data-testid='intent-incident'][href$='/ops/posture']")
    assert has_element?(lv, "[data-testid='intent-change'][href$='/ops/sync-drift']")
    assert has_element?(lv, "[data-testid='intent-explore'][href$='/ops/search']")
  end

  test "unconfigured fleet shows the config empty state but keeps the intent cards", %{conn: conn} do
    {:ok, _lv, html} = live(conn, ~p"/ops")

    assert html =~ "No schemas configured"
    assert html =~ "Something looks broken"
    assert html =~ "Explore &amp; capture"
  end
end
