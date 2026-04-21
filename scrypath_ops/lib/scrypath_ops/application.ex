defmodule ScrypathOps.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    if Application.get_env(:scrypath_ops, :validate_opsui_auth_on_start) do
      mode = System.get_env("OPSUI_AUTH_MODE")

      if mode in ScrypathOps.Security.allowed_opsui_auth_modes() do
        start_supervisor()
      else
        {:error,
         {:invalid_opsui_auth_mode,
          "OPSUI_AUTH_MODE must be set for production to a documented value (allowed: basic, proxy_headers)."}}
      end
    else
      start_supervisor()
    end
  end

  defp start_supervisor do
    children = [
      ScrypathOpsWeb.Telemetry,
      ScrypathOps.Repo,
      {DNSCluster, query: Application.get_env(:scrypath_ops, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: ScrypathOps.PubSub},
      ScrypathOpsWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: ScrypathOps.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ScrypathOpsWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
