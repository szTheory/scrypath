defmodule ScrypathDemo.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ScrypathDemoWeb.Telemetry,
      ScrypathDemo.Repo,
      {ScrypathDemo.Oban, Application.fetch_env!(:scrypath_demo, Oban)},
      {DNSCluster, query: Application.get_env(:scrypath_demo, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: ScrypathDemo.PubSub},
      # Start a worker by calling: ScrypathDemo.Worker.start_link(arg)
      # {ScrypathDemo.Worker, arg},
      # Start to serve requests, typically the last entry
      ScrypathDemoWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ScrypathDemo.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ScrypathDemoWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
