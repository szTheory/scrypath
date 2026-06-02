defmodule ScrypathEcommerce.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ScrypathEcommerce.Repo,
      {Oban, Application.fetch_env!(:scrypath_ecommerce, Oban)},
      {Phoenix.PubSub, name: ScrypathEcommerce.PubSub},
      ScrypathEcommerceWeb.Endpoint
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: ScrypathEcommerce.Supervisor)
  end

  @impl true
  def config_change(changed, _new, removed) do
    ScrypathEcommerceWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
