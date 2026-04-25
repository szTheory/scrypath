defmodule ScrypathOps.Security do
  @moduledoc false

  @allowed_opsui_auth_modes ~w(basic proxy_headers sigra)

  def allowed_opsui_auth_modes, do: @allowed_opsui_auth_modes

  def validate!(env \\ default_env()) do
    case validate(env) do
      :ok -> :ok
      {:error, message} -> raise message
    end
  end

  def validate(%{auth_mode: mode}) when mode not in @allowed_opsui_auth_modes do
    {:error,
     "OPSUI_AUTH_MODE=#{mode} is not allowed. Allowed: #{Enum.join(@allowed_opsui_auth_modes, ", ")}"}
  end

  def validate(%{auth_mode: "sigra"} = env) do
    sigra_cfg = Map.get(env, :sigra, []) || []

    case Keyword.get(sigra_cfg, :sudo_confirm_path) do
      nil ->
        {:error,
         "OPSUI_AUTH_MODE=sigra requires :sudo_confirm_path.\n\n" <>
           "Add to config/runtime.exs:\n\n" <>
           "    config :scrypath_ops, :sigra, sudo_confirm_path: \"/sudo/confirm\"\n" <>
           "    # Optional: sudo_window defaults to 300 seconds\n\n" <>
           "See guides/integrations/sigra.md."}

      _ ->
        :ok
    end
  end

  def validate(%{auth_mode: _mode}), do: :ok

  defp default_env do
    %{
      auth_mode: System.get_env("OPSUI_AUTH_MODE", "basic"),
      sigra: Application.get_env(:scrypath_ops, :sigra, [])
    }
  end
end
