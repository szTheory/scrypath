defmodule ScrypathOps.Test.CopySurfaces do
  @moduledoc false
  # Registry of the rendered surfaces the copy rules table names. Each surface is an existing
  # fixture state of a ScrypathOps screen, rendered to HTML. Every surface carries a state
  # anchor: a short literal that appears in the HTML only when the surface reached its intended
  # state. The contract test asserts the anchor before it evaluates any row, so a forbidden-only
  # row cannot pass on a page that never showed the state. An anchor never contains a phrase a
  # row forbids or requires (`CopyRules.validate/2` checks that).
  #
  # Shared fixture setup lives in `ScrypathOps.Test.CopyStubs.*`, which the LiveView tests use
  # too, so no stub is defined twice.

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias ScrypathOps.Test.CopyStubs.ControlRoom, as: ControlRoomStubs
  alias ScrypathOps.Test.CopyStubs.SyncDrift, as: SyncDriftStubs
  alias ScrypathOps.Test.OpsPostA

  @endpoint ScrypathOpsWeb.Endpoint

  @anchors %{
    "control_room.default" => "Search backend not configured.",
    "sync_drift.default" => ~s(aria-label="Related search views"),
    "sync_drift.settings_missing_field" => ~s(data-missing="true")
  }

  @doc "Registered surface ids."
  def ids, do: @anchors |> Map.keys() |> Enum.sort()

  @doc "Surface id to state anchor."
  def anchors, do: @anchors

  @doc "State anchor of one surface."
  def anchor(id), do: Map.fetch!(@anchors, id)

  @doc """
  Renders one surface to HTML. `ctx` carries the `conn` of the calling test (so the Ecto sandbox
  and the endpoint are the test's own).
  """
  def render(id, ctx)

  # /ops with one allowlisted schema and no configured backend (the first Control room test).
  def render("control_room.default", %{conn: conn}) do
    ControlRoomStubs.with_env(fn ->
      Application.put_env(:scrypath_ops, :schema_allowlist, [OpsPostA])
      {:ok, _lv, html} = live(conn, "/ops")
      html
    end)
  end

  # /ops/sync-and-index as it loads, after its settings and sync checks finish.
  def render("sync_drift.default", %{conn: conn}) do
    SyncDriftStubs.with_stubs(fn ->
      {:ok, lv, _html} = live(conn, "/ops/sync-and-index")
      render_async(lv)
    end)
  end

  # /ops/sync-and-index when the live index lacks a field the schema declares as searchable.
  def render("sync_drift.settings_missing_field", %{conn: conn}) do
    SyncDriftStubs.with_stubs(fn ->
      Agent.update(SyncDriftStubs.state_name(), fn state ->
        Map.put(state, :applied_settings, %{
          "searchableAttributes" => ["other"],
          "filterableAttributes" => [],
          "sortableAttributes" => []
        })
      end)

      {:ok, lv, _html} = live(conn, "/ops/sync-and-index")
      render_async(lv)
    end)
  end
end
