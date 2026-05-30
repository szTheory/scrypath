defmodule ScrypathEcommerceWeb.Router do
  use ScrypathEcommerceWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {ScrypathEcommerceWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", ScrypathEcommerceWeb do
    pipe_through :browser

    live "/", SearchLive, :index
  end

  if Mix.env() in [:dev, :test] do
    scope "/dev/e2e", ScrypathEcommerceWeb do
      pipe_through :api
      post "/seed", E2EController, :seed
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", ScrypathEcommerceWeb do
  #   pipe_through :api
  # end
end
