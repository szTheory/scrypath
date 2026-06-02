defmodule ScrypathOpsWeb.DevRouter do
  use ScrypathOpsWeb, :router

  import ScrypathOpsWeb.Router, only: [scrypath_ops_routes: 2]

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, html: {ScrypathOpsWeb.Layouts, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/", ScrypathOpsWeb do
    pipe_through(:browser)

    get("/", PageController, :home)
  end

  # Mount the ScrypathOps routes for development
  scope "/" do
    pipe_through(:browser)
    scrypath_ops_routes("/ops", repo: ScrypathOps.Repo)
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:scrypath_ops, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through(:browser)

      live_dashboard("/dashboard", metrics: ScrypathOpsWeb.Telemetry)
      forward("/mailbox", Plug.Swoosh.MailboxPreview)
    end
  end
end
