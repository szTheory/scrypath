defmodule ScrypathOps.Integrations.Sigra.GatingTest do
  use ExUnit.Case, async: true

  alias ScrypathOps.Integrations.Sigra.Gating
  alias ScrypathOps.Integrations.Sigra.OperatorContext

  setup do
    original_sigra = Application.get_env(:scrypath_ops, :sigra)

    on_exit(fn ->
      if original_sigra == nil do
        Application.delete_env(:scrypath_ops, :sigra)
      else
        Application.put_env(:scrypath_ops, :sigra, original_sigra)
      end
    end)

    :ok
  end

  test "__action_config__/0 uses stable scrypath.ops prefixes" do
    action_config = Gating.__action_config__()

    assert Enum.all?(Map.values(action_config), &String.starts_with?(&1, "scrypath.ops."))
    assert Map.values(action_config) == Enum.uniq(Map.values(action_config))
  end

  test "nil operator_context executes the closure" do
    socket = socket(%{})

    assert :ran = Gating.gate_sensitive_action(socket, :playbook_delete, fn -> :ran end)
  end

  test "impersonation blocks the action and adds an error flash" do
    context = operator_context(impersonator: "impersonator_789")
    socket = socket(%{operator_context: context})

    result = Gating.gate_sensitive_action(socket, :playbook_delete, fn -> flunk("action should not run") end)

    assert get_flash(result, "error") =~ "Impersonation must be cleared"
  end

  test "stale sudo sends the operator to the confirm path with return_to" do
    context = operator_context(sudo_at: DateTime.add(DateTime.utc_now(), -600, :second))
    socket = socket(%{operator_context: context, return_to: "/ops/playbooks/42"})

    result = Gating.gate_sensitive_action(socket, :playbook_delete, fn -> flunk("action should not run") end)

    assert inspect(result.redirected) =~ "/sudo/confirm"
    assert inspect(result.redirected) =~ "return_to=%2Fops%2Fplaybooks%2F42"
  end

  test "fresh sudo executes the closure" do
    context = operator_context(sudo_at: DateTime.add(DateTime.utc_now(), -60, :second))
    socket = socket(%{operator_context: context})

    assert :ran = Gating.gate_sensitive_action(socket, :playbook_delete, fn -> :ran end)
  end

  defp operator_context(opts) do
    scope = %{
      user: %{id: "user_123"},
      active_organization: %{id: "org_456"},
      impersonating_from: if(Keyword.get(opts, :impersonator), do: %{id: Keyword.fetch!(opts, :impersonator)}, else: nil)
    }

    session = %Sigra.Session{
      sudo_at: Keyword.get(opts, :sudo_at, DateTime.add(DateTime.utc_now(), -60, :second)),
      impersonator_user_id: Keyword.get(opts, :impersonator)
    }

    OperatorContext.build(scope, session)
  end

  defp socket(assigns) do
    %Phoenix.LiveView.Socket{
      assigns: Map.merge(%{__changed__: %{}, current_scope: %{user: %{id: "user_123"}, active_organization: %{id: "org_456"}}, flash: %{}}, assigns),
      host_uri: URI.parse("https://scrypath.example/ops/playbooks/42")
    }
  end

  defp get_flash(socket, key) do
    socket.assigns |> Map.get(:flash, %{}) |> Map.get(key)
  end
end
