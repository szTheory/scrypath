defmodule ScrypathOps.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    :ok = ScrypathOps.Security.validate!()

    standalone? = Application.get_env(:scrypath_ops, :standalone, false)

    if Application.get_env(:scrypath_ops, :validate_opsui_auth_on_start) do
      start_supervisor(standalone?)
    else
      start_supervisor(standalone?)
    end
  end

  defp start_supervisor(standalone?) do
    base_children = [
      ScrypathOpsWeb.Telemetry,
      {Phoenix.PubSub, name: ScrypathOps.PubSub}
    ]

    standalone_children =
      if standalone? do
        [
          ScrypathOps.Repo,
          {DNSCluster, query: Application.get_env(:scrypath_ops, :dns_cluster_query) || :ignore},
          ScrypathOpsWeb.Endpoint
        ]
      else
        []
      end

    children = base_children ++ standalone_children

    opts = [strategy: :one_for_one, name: ScrypathOps.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    if Application.get_env(:scrypath_ops, :standalone, false) do
      ScrypathOpsWeb.Endpoint.config_change(changed, removed)
    end
    :ok
  end
end
