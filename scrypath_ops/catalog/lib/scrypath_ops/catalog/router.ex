defmodule ScrypathOps.Catalog.Router do
  @moduledoc false

  # Routes of `ScrypathOps.Catalog.Endpoint`: the storybook and its assets, nothing else.
  use Phoenix.Router, helpers: false

  import PhoenixStorybook.Router

  scope "/" do
    storybook_assets()
  end

  scope "/" do
    live_storybook("/storybook", backend_module: ScrypathOps.Catalog.Storybook)
  end
end
