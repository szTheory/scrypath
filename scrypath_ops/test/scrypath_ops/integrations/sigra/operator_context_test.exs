defmodule ScrypathOps.Integrations.Sigra.OperatorContextTest do
  use ExUnit.Case, async: true

  alias ScrypathOps.Integrations.Sigra.OperatorContext

  test "build/2 returns an IDs-only struct with exactly four fields" do
    scope = %{
      user: %{id: "user_123"},
      active_organization: %{id: "org_456"},
      impersonating_from: %{id: "impersonator_789"}
    }

    session = %Sigra.Session{
      sudo_at: ~U[2026-04-25 00:00:00Z],
      impersonator_user_id: "impersonator_789"
    }

    context = OperatorContext.build(scope, session)

    assert %OperatorContext{} = context
    assert context.user_id == "user_123"
    assert context.active_org_id == "org_456"
    assert context.impersonator_user_id == "impersonator_789"
    assert context.sudo_at == ~U[2026-04-25 00:00:00Z]

    struct_keys = context |> Map.from_struct() |> Map.keys() |> MapSet.new()

    assert struct_keys == MapSet.new([:user_id, :active_org_id, :impersonator_user_id, :sudo_at])

    refute Enum.any?([:ip, :user_agent, :parsed_ua, :geo_city, :geo_country_code, :email, :name], &MapSet.member?(struct_keys, &1))
  end

  test "build/2 returns nil when scope is absent" do
    assert is_nil(OperatorContext.build(nil, nil))
  end

  test "from_socket/1 reads assigns and delegates to build/2" do
    scope = %{user: %{id: "user_123"}, active_organization: %{id: "org_456"}}
    session = %Sigra.Session{sudo_at: ~U[2026-04-25 00:00:00Z]}

    socket = %Phoenix.LiveView.Socket{assigns: %{current_scope: scope, sigra_session: session}}

    assert OperatorContext.from_socket(socket) == OperatorContext.build(scope, session)
  end
end
