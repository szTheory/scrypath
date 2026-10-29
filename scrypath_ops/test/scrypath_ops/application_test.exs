defmodule ScrypathOps.ApplicationTest do
  use ExUnit.Case, async: false

  test "keeps core children and omits diagnostics when standalone is false in test" do
    # Stop the application to test the startup logic
    Application.stop(:scrypath_ops)

    original = Application.get_env(:scrypath_ops, :standalone)
    Application.put_env(:scrypath_ops, :standalone, false)

    on_exit(fn ->
      Application.stop(:scrypath_ops)

      if original == nil do
        Application.delete_env(:scrypath_ops, :standalone)
      else
        Application.put_env(:scrypath_ops, :standalone, original)
      end

      Application.ensure_all_started(:scrypath_ops)
    end)

    assert {:ok, _} = Application.ensure_all_started(:scrypath_ops)

    children = Supervisor.which_children(ScrypathOps.Supervisor)
    # The format of which_children is [{id, child, type, modules}]
    modules =
      Enum.map(children, fn {_, _, _, mods} ->
        case mods do
          [mod] -> mod
          _ -> nil
        end
      end)
      |> Enum.reject(&is_nil/1)

    refute ScrypathOpsWeb.Telemetry in modules
    assert ScrypathOps.RecoveryObservation in modules
    assert Phoenix.PubSub.Supervisor in modules
    assert Task.Supervisor in modules
    refute ScrypathOpsWeb.Endpoint in modules
    refute ScrypathOps.Repo in modules
    refute DNSCluster in modules
  end

  test "standalone ownership retains Endpoint and Repo without test diagnostics" do
    Application.stop(:scrypath_ops)

    original = Application.get_env(:scrypath_ops, :standalone)
    Application.put_env(:scrypath_ops, :standalone, true)

    on_exit(fn ->
      Application.stop(:scrypath_ops)

      if original == nil do
        Application.delete_env(:scrypath_ops, :standalone)
      else
        Application.put_env(:scrypath_ops, :standalone, original)
      end

      Application.ensure_all_started(:scrypath_ops)
    end)

    assert {:ok, _} = Application.ensure_all_started(:scrypath_ops)

    modules =
      Supervisor.which_children(ScrypathOps.Supervisor)
      |> Enum.map(fn {_, _, _, mods} -> List.first(mods) end)

    assert ScrypathOps.RecoveryObservation in modules
    assert Phoenix.PubSub.Supervisor in modules
    assert Task.Supervisor in modules
    assert ScrypathOps.Repo in modules
    assert ScrypathOpsWeb.Endpoint in modules
    assert DNSCluster in modules
    refute ScrypathOpsWeb.Telemetry in modules
  end
end
