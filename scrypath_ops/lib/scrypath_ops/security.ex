defmodule ScrypathOps.Security do
  @moduledoc false

  alias ScrypathOps.Integrations.Sigra, as: SigraIntegration

  @allowed_opsui_auth_modes ~w(basic proxy_headers sigra)
  @unsafe_confirm_path_parts ["?", "#", "\\", "/%09", "/\t", "\n", "\r"]

  def allowed_opsui_auth_modes, do: @allowed_opsui_auth_modes

  def auth_mode, do: System.get_env("OPSUI_AUTH_MODE", "basic")

  def sigra_available?, do: SigraIntegration.available?()

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
    cond do
      not sigra_available?() ->
        {:error, SigraIntegration.unavailable_message()}

      not valid_sudo_confirm_path?(sigra_config_value(env, :sudo_confirm_path)) ->
        {:error, invalid_sudo_confirm_path_message()}

      true ->
        :ok
    end
  end

  def validate(%{auth_mode: _mode}), do: :ok

  defp sigra_config_value(env, key) do
    case Map.get(env, :sigra, []) do
      config when is_list(config) -> Keyword.get(config, key)
      _ -> nil
    end
  end

  defp valid_sudo_confirm_path?(path) when is_binary(path) do
    path != "" and String.valid?(path) and String.trim(path) == path and
      String.starts_with?(path, "/") and not String.starts_with?(path, "//") and
      not String.contains?(path, @unsafe_confirm_path_parts) and
      case URI.parse(path) do
        %URI{scheme: nil, host: nil, path: parsed_path} when is_binary(parsed_path) ->
          true

        _ ->
          false
      end
  rescue
    ArgumentError -> false
  end

  defp valid_sudo_confirm_path?(_path), do: false

  defp invalid_sudo_confirm_path_message do
    "OPSUI_AUTH_MODE=sigra requires a valid :sudo_confirm_path.\n\n" <>
      "Add a local application path to config/runtime.exs:\n\n" <>
      "    config :scrypath_ops, :sigra, sudo_confirm_path: \"/sudo/confirm\"\n" <>
      "    # Optional: sudo_window defaults to 300 seconds\n\n" <>
      "See scrypath_ops/README.md and guides/support-and-compatibility.md."
  end

  defp default_env do
    %{
      auth_mode: auth_mode(),
      sigra: Application.get_env(:scrypath_ops, :sigra, [])
    }
  end
end
