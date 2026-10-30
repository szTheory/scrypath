defmodule ScrypathOps.Integrations.Sigra.GatingTest do
  use ExUnit.Case, async: false

  alias ScrypathOps.Integrations.Sigra.Gating
  alias ScrypathOps.Integrations.Sigra.OperatorContext

  setup do
    original_sigra = Application.get_env(:scrypath_ops, :sigra)
    original_auth_mode = System.get_env("OPSUI_AUTH_MODE")

    System.put_env("OPSUI_AUTH_MODE", "sigra")

    on_exit(fn ->
      restore_env("OPSUI_AUTH_MODE", original_auth_mode)

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

  test "requested Sigra denies an action with nil operator_context" do
    assert_denied(socket(%{}), :saved_search_delete)
  end

  test "requested Sigra denies every configured action for invalid identity and sudo context" do
    now = DateTime.utc_now()

    contexts = [
      nil,
      "scalar",
      %{},
      %{sudo_at: now},
      %{user_id: "user_123", sudo_at: now},
      %OperatorContext{user_id: nil, active_org_id: "org_456", sudo_at: now},
      %OperatorContext{user_id: "user_123", active_org_id: nil, sudo_at: now},
      %{operator_context([]) | sudo_at: "not-a-datetime"},
      operator_context(sudo_at: DateTime.utc_now() |> Map.put(:month, 13)),
      operator_context(sudo_at: DateTime.add(DateTime.utc_now(), 60, :second)),
      operator_context(impersonator: "impersonator_789")
    ]

    for action <- Map.keys(Gating.__action_config__()), context <- contexts do
      assert_denied(socket(%{operator_context: context}), action)
    end
  end

  test "impersonation blocks the action and adds an error flash" do
    context = operator_context(impersonator: "impersonator_789")
    socket = socket(%{operator_context: context})

    result =
      Gating.gate_sensitive_action(socket, :saved_search_delete, fn ->
        flunk("action should not run")
      end)

    assert get_flash(result, "error") =~ "Impersonation must be cleared"
  end

  test "requested Sigra rejects malformed user and organization identities for every action" do
    for action <- Map.keys(Gating.__action_config__()),
        field <- [:user_id, :active_org_id],
        value <- [false, true, [], %{}, :unknown, 0, -1, 1.5] do
      context = Map.put(operator_context([]), field, value)
      assert_denied(socket(%{operator_context: context}), action)
    end
  end

  test "fresh confirmation supports positive integer identities" do
    context = %{operator_context([]) | user_id: 123, active_org_id: 456}

    assert :ran =
             Gating.gate_sensitive_action(socket(%{operator_context: context}), :reindex, fn ->
               :ran
             end)
  end

  test "stale sudo sends the operator to the confirm path with return_to" do
    context = operator_context(sudo_at: DateTime.add(DateTime.utc_now(), -600, :second))

    socket =
      socket(%{operator_context: context, return_to: "/ops/playbooks/42?tab=recent & open"})

    result =
      Gating.gate_sensitive_action(socket, :saved_search_delete, fn ->
        flunk("action should not run")
      end)

    assert inspect(result.redirected) =~ "/sudo/confirm"

    assert inspect(result.redirected) =~
             "return_to=%2Fops%2Fplaybooks%2F42%3Ftab%3Drecent+%26+open"
  end

  test "an unconfirmed operator reaches confirmation without running any protected action" do
    Application.put_env(:scrypath_ops, :sigra, sudo_confirm_path: "/account/confirm")
    context = operator_context(sudo_at: nil)

    for action <- Map.keys(Gating.__action_config__()) do
      socket = socket(%{operator_context: context, return_to: "/ops/playbooks/42"})

      result =
        Gating.gate_sensitive_action(socket, action, fn ->
          flunk("an unconfirmed operator must not run the protected action")
        end)

      assert result.redirected ==
               {:live, :redirect,
                %{kind: :push, to: "/account/confirm?return_to=%2Fops%2Fplaybooks%2F42"}}
    end
  end

  test "sudo age equal to the configured window remains valid" do
    Application.put_env(:scrypath_ops, :sigra,
      sudo_confirm_path: "/sudo/confirm",
      sudo_window: 60
    )

    context = operator_context(sudo_at: DateTime.add(DateTime.utc_now(), -60, :second))
    socket = socket(%{operator_context: context})

    assert :ran = Gating.gate_sensitive_action(socket, :saved_search_delete, fn -> :ran end)
  end

  test "fresh sudo invokes the closure once and passes audit identity to Sigra" do
    context = operator_context(sudo_at: DateTime.add(DateTime.utc_now(), -60, :second))

    scope = %{
      user: %{id: "scope_user"},
      active_organization: %{id: "scope_org"},
      impersonating_from: nil
    }

    socket = socket(%{operator_context: context, current_scope: scope})
    ref = make_ref()

    {action, audit_scope, opts} =
      Gating.__audit_arguments__(:saved_search_delete, context, socket)

    result =
      Gating.gate_sensitive_action(socket, :saved_search_delete, fn ->
        send(self(), {:callback_ran, ref})
        :ran
      end)

    assert :ran = result
    assert_received {:callback_ran, ^ref}
    refute_received {:callback_ran, ^ref}
    assert action == "scrypath.ops.saved_search_delete"
    assert audit_scope == scope
    assert Keyword.get(opts, :actor_id) == context.user_id
    assert Keyword.get(opts, :organization_id) == context.active_org_id
    assert Keyword.get(opts, :impersonator_user_id) == context.impersonator_user_id
    assert Keyword.get(opts, :sudo_at) == context.sudo_at
  end

  test "basic and proxy_headers preserve host-owned callback behavior" do
    for mode <- ["basic", "proxy_headers"] do
      System.put_env("OPSUI_AUTH_MODE", mode)
      socket = socket(%{})
      assert :ran = Gating.gate_sensitive_action(socket, :saved_search_delete, fn -> :ran end)
    end
  end

  defp operator_context(opts) do
    scope = %{
      user: %{id: "user_123"},
      active_organization: %{id: "org_456"},
      impersonating_from:
        if(Keyword.get(opts, :impersonator),
          do: %{id: Keyword.fetch!(opts, :impersonator)},
          else: nil
        )
    }

    session = %Sigra.Session{
      sudo_at: Keyword.get(opts, :sudo_at, DateTime.add(DateTime.utc_now(), -60, :second)),
      impersonator_user_id: Keyword.get(opts, :impersonator)
    }

    OperatorContext.build(scope, session)
  end

  defp socket(assigns) do
    %Phoenix.LiveView.Socket{
      assigns:
        Map.merge(
          %{
            __changed__: %{},
            current_scope: %{user: %{id: "user_123"}, active_organization: %{id: "org_456"}},
            flash: %{}
          },
          assigns
        ),
      host_uri: URI.parse("https://scrypath.example/ops/playbooks/42")
    }
  end

  defp get_flash(socket, key) do
    socket.assigns |> Map.get(:flash, %{}) |> Map.get(key)
  end

  defp assert_denied(socket, action) do
    ref = make_ref()

    result =
      try do
        {:ok,
         Gating.gate_sensitive_action(socket, action, fn ->
           send(self(), {:callback_ran, ref})
           :ran
         end)}
      rescue
        _ -> :raised
      end

    refute_receive {:callback_ran, ^ref}
    assert {:ok, %Phoenix.LiveView.Socket{} = denied_socket} = result
    assert is_binary(get_flash(denied_socket, "error"))
    assert String.trim(get_flash(denied_socket, "error")) != ""
  end

  defp restore_env(name, nil), do: System.delete_env(name)
  defp restore_env(name, value), do: System.put_env(name, value)
end
