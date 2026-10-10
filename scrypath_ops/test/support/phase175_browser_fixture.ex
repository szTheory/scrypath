defmodule ScrypathOps.Test.Phase175AuthFixtureOnMount do
  @moduledoc false

  import Phoenix.Component, only: [assign: 3]

  def on_mount(
        :default,
        %{"fixture_auth" => "expired"},
        _session,
        %{assigns: %{live_action: :phase175}} = socket
      ) do
    context = %{
      user_id: "phase175-browser-fixture-user",
      active_org_id: "phase175-browser-fixture-org",
      impersonator_user_id: nil,
      sudo_at: DateTime.add(DateTime.utc_now(), -600, :second)
    }

    {:cont, assign(socket, :operator_context, context)}
  end

  def on_mount(:default, _params, _session, socket), do: {:cont, socket}
end

defmodule ScrypathOpsWeb.Phase175FixtureController do
  use ScrypathOpsWeb, :controller

  def status(conn, _params) do
    source = Module.concat(["ScrypathOps.Test.Phase175FixtureSource"])

    if Process.whereis(source.state_name()) do
      state = Agent.get(source.state_name(), & &1)
      json(conn, Map.take(state, [:swap_post_count, :task_calls, :tasks_calls, :jobs_calls]))
    else
      conn
      |> put_status(:service_unavailable)
      |> json(%{error: "Phase 175 fixture is unavailable"})
    end
  end
end
