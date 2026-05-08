defmodule ScrypathOps.SecurityTest do
  use ExUnit.Case, async: true

  alias ScrypathOps.Security

  test "allowed_opsui_auth_modes includes sigra and stays string-based" do
    assert Security.allowed_opsui_auth_modes() == ["basic", "proxy_headers", "sigra"]
  end

  test "validate accepts the supported auth modes" do
    assert :ok == Security.validate(%{auth_mode: "basic", sigra: []})
    assert :ok == Security.validate(%{auth_mode: "proxy_headers", sigra: []})

    assert :ok ==
             Security.validate(%{auth_mode: "sigra", sigra: [sudo_confirm_path: "/sudo/confirm"]})
  end

  test "validate rejects sigra without sudo_confirm_path" do
    assert {:error, message} = Security.validate(%{auth_mode: "sigra", sigra: []})
    assert message =~ "OPSUI_AUTH_MODE=sigra requires :sudo_confirm_path"
    assert message =~ "guides/integrations/sigra.md"
  end

  test "validate rejects unsupported auth modes" do
    assert {:error, message} = Security.validate(%{auth_mode: "danger-zone", sigra: []})
    assert message =~ "danger-zone"
    assert message =~ "basic, proxy_headers, sigra"
  end
end
