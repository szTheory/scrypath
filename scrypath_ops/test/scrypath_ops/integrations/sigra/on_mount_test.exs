defmodule ScrypathOps.Integrations.Sigra.OnMountTest do
  use ExUnit.Case, async: false

  alias ScrypathOps.Integrations.Sigra.Gating
  alias ScrypathOps.Integrations.Sigra.OnMount
  alias ScrypathOps.Integrations.Sigra.OperatorContext

  setup do
    original_auth_mode = System.get_env("OPSUI_AUTH_MODE")
    System.put_env("OPSUI_AUTH_MODE", "sigra")

    on_exit(fn -> restore_env("OPSUI_AUTH_MODE", original_auth_mode) end)

    :ok
  end

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

  test "OnMount creates identity for the gate while unauthenticated route lifecycle continues" do
    populated_socket = %Phoenix.LiveView.Socket{
      assigns: %{
        __changed__: %{},
        flash: %{},
        current_scope: %{user: %{id: "user_123"}, active_organization: %{id: "org_456"}},
        sigra_session: %Sigra.Session{sudo_at: DateTime.utc_now()}
      }
    }

    {:cont, populated_result} = OnMount.on_mount(:default, %{}, %{}, populated_socket)

    assert %OperatorContext{user_id: "user_123", active_org_id: "org_456"} =
             populated_result.assigns.operator_context

    assert :ran = Gating.gate_sensitive_action(populated_result, :reindex, fn -> :ran end)

    empty_socket = %Phoenix.LiveView.Socket{assigns: %{__changed__: %{}, flash: %{}}}
    assert {:cont, empty_result} = OnMount.on_mount(:default, %{}, %{}, empty_socket)
    assert empty_result.assigns.operator_context == nil

    result =
      Gating.gate_sensitive_action(empty_result, :reindex, fn ->
        flunk("OnMount continuing the route must not authorize the sensitive action")
      end)

    assert result.assigns.flash["error"] =~ "Sign in again"
  end

  defp restore_env(name, nil), do: System.delete_env(name)
  defp restore_env(name, value), do: System.put_env(name, value)
end
