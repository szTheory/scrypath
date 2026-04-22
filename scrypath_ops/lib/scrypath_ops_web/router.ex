defmodule ScrypathOpsWeb.Router do
  use ScrypathOpsWeb, :router

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

  scope "/ops", ScrypathOpsWeb do
    pipe_through(:browser)

    live_session :ops, on_mount: [{ScrypathOpsWeb.Live.OnMount, :default}] do
      live("/posture", PostureLive)
      live("/failed-sync", FailedSyncLive)
      live("/sync-drift", SyncDriftLive)
      live("/search", SearchLive)
      live("/playbooks", PlaybookLive)
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", ScrypathOpsWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:scrypath_ops, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through(:browser)

      live_dashboard("/dashboard", metrics: ScrypathOpsWeb.Telemetry)
      forward("/mailbox", Plug.Swoosh.MailboxPreview)
    end
  end
end
