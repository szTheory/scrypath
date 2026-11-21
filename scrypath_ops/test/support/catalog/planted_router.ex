defmodule ScrypathOps.Catalog.PlantedRouter do
  @moduledoc false

  use Phoenix.Router, helpers: false

  import PhoenixStorybook.Router

  scope "/" do
    storybook_assets()
  end

  scope "/" do
    live_storybook("/storybook", backend_module: ScrypathOps.Catalog.PlantedStorybook)
  end
end
