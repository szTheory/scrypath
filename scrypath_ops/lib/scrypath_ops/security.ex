defmodule ScrypathOps.Security do
  @moduledoc false

  @allowed_opsui_auth_modes ~w(basic proxy_headers)

  def allowed_opsui_auth_modes, do: @allowed_opsui_auth_modes
end
