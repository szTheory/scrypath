defmodule ScrypathDemoWeb.Router do
  use ScrypathDemoWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", ScrypathDemoWeb do
    pipe_through :api
  end
end
