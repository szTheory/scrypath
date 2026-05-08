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

  test "validate!/0 raises when sigra sudo_confirm_path is missing" do
    System.put_env("OPSUI_AUTH_MODE", "sigra")
    Application.put_env(:scrypath_ops, :sigra, [])

    assert_raise RuntimeError, ~r/OPSUI_AUTH_MODE=sigra requires :sudo_confirm_path/, fn ->
      Security.validate!()
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
