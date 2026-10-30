defmodule ScrypathOps.SecurityValidationTest do
  use ExUnit.Case, async: false

  alias ScrypathOps.Security

  setup do
    original_auth_mode = System.get_env("OPSUI_AUTH_MODE")
    original_sigra = Application.get_env(:scrypath_ops, :sigra)

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

  test "allowed_opsui_auth_modes includes sigra and stays string-based" do
    assert Security.allowed_opsui_auth_modes() == ["basic", "proxy_headers", "sigra"]
  end

  test "validate/1 accepts the supported auth modes" do
    assert :ok == Security.validate(%{auth_mode: "basic", sigra: []})
    assert :ok == Security.validate(%{auth_mode: "proxy_headers", sigra: []})

    assert :ok ==
             Security.validate(%{auth_mode: "sigra", sigra: [sudo_confirm_path: "/sudo/confirm"]})
  end

  test "validate!/0 accepts sigra only when sudo_confirm_path is configured" do
    System.put_env("OPSUI_AUTH_MODE", "sigra")
    Application.put_env(:scrypath_ops, :sigra, sudo_confirm_path: "/sudo/confirm")

    assert :ok == Security.validate!()
  end

  test "validate!/0 explains when sigra sudo_confirm_path is missing" do
    System.put_env("OPSUI_AUTH_MODE", "sigra")
    Application.put_env(:scrypath_ops, :sigra, [])

    error =
      assert_raise RuntimeError, fn ->
        Security.validate!()
      end

    message = Exception.message(error)
    assert message =~ "OPSUI_AUTH_MODE=sigra requires a valid :sudo_confirm_path"
    assert message =~ "scrypath_ops/README.md"
    assert message =~ "guides/support-and-compatibility.md"
    refute message =~ "guides/integrations/sigra.md"
  end

  test "validate/1 rejects empty, relative, and external sigra sudo confirmation paths" do
    for path <- [
          "",
          "sudo/confirm",
          "//other.example/sudo",
          "https://other.example/sudo",
          "/sudo/\\confirm",
          "/sudo/\nconfirm",
          "/sudo/\rconfirm",
          "/sudo/\tconfirm",
          "/%09confirm"
        ] do
      assert {:error, message} =
               Security.validate(%{auth_mode: "sigra", sigra: [sudo_confirm_path: path]})

      assert message =~ ":sudo_confirm_path"
    end
  end

  test "accepted confirmation paths reach LiveView confirmation without running the action" do
    System.put_env("OPSUI_AUTH_MODE", "sigra")

    for path <- ["/sudo/confirm", "/account/confirm-step", "/team/confirm%20identity"] do
      config = [sudo_confirm_path: path]
      assert :ok = Security.validate(%{auth_mode: "sigra", sigra: config})
      Application.put_env(:scrypath_ops, :sigra, config)

      context = %ScrypathOps.Integrations.Sigra.OperatorContext{
        user_id: "user_123",
        active_org_id: "org_456",
        sudo_at: nil
      }

      socket = %Phoenix.LiveView.Socket{
        assigns: %{__changed__: %{}, operator_context: context, return_to: "/ops", flash: %{}}
      }

      result =
        ScrypathOps.Integrations.Sigra.Gating.gate_sensitive_action(socket, :reindex, fn ->
          flunk("confirmation must happen before the protected action")
        end)

      assert {:live, :redirect, %{to: target}} = result.redirected
      assert target == path <> "?return_to=%2Fops"
    end
  end

  test "validate rejects unsupported auth modes" do
    assert {:error, message} = Security.validate(%{auth_mode: "danger-zone", sigra: []})
    assert message =~ "danger-zone"
    assert message =~ "basic, proxy_headers, sigra"
  end

  defp restore_env(name, nil), do: System.delete_env(name)
  defp restore_env(name, value), do: System.put_env(name, value)
end
