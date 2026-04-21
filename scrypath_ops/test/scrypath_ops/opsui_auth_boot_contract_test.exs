defmodule ScrypathOps.OpsuiAuthBootContractTest do
  use ExUnit.Case, async: true

  @application_src Path.join([__DIR__, "..", "..", "lib", "scrypath_ops", "application.ex"])
                   |> File.read!()

  test "production boot consults OPSUI_AUTH_MODE against Security allow-list" do
    assert @application_src =~ "validate_opsui_auth_on_start"
    assert @application_src =~ "OPSUI_AUTH_MODE"
    assert @application_src =~ "ScrypathOps.Security.allowed_opsui_auth_modes()"
  end
end
