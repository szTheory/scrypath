defmodule ScrypathOps.Integrations.Sigra.OnMountTest do
  use ExUnit.Case, async: true

  alias ScrypathOps.Integrations.Sigra.OnMount
  alias ScrypathOps.Integrations.Sigra.OperatorContext

  test "on_mount/4 always returns :cont and assigns operator_context" do
    populated_socket = %Phoenix.LiveView.Socket{
      assigns: %{
        __changed__: %{},
        flash: %{},
        current_scope: %{user: %{id: "user_123"}, active_organization: %{id: "org_456"}},
        sigra_session: %Sigra.Session{sudo_at: ~U[2026-04-25 00:00:00Z]}
      }
    }

    empty_socket = %Phoenix.LiveView.Socket{assigns: %{__changed__: %{}, flash: %{}}}

    assert {:cont, populated_result} = OnMount.on_mount(:default, %{}, %{}, populated_socket)
    assert {:cont, empty_result} = OnMount.on_mount(:default, %{}, %{}, empty_socket)

    if Code.ensure_loaded?(Sigra.Session) do
      assert %OperatorContext{} = populated_result.assigns.operator_context
      assert populated_result.assigns.operator_context.user_id == "user_123"
      assert populated_result.assigns.operator_context.active_org_id == "org_456"
    else
      assert populated_result.assigns.operator_context == nil
    end

    assert empty_result.assigns.operator_context == nil
  end
end
