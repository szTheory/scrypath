defmodule ScrypathOps.ConfigProdGuardTest do
  use ExUnit.Case, async: true

  @modes ~w(basic proxy_headers)

  test "prod requires OPSUI_AUTH_MODE documentation constant" do
    assert ScrypathOps.Security.allowed_opsui_auth_modes() == @modes
    assert Enum.join(@modes, ",") <> " OPSUI_AUTH_MODE" =~ "OPSUI_AUTH_MODE"
  end

  test "contract uses Enum.member? for OPSUI_AUTH_MODE allow-list" do
    mode = hd(@modes)
    assert Enum.member?(["basic", "proxy_headers"], mode)
  end
end
