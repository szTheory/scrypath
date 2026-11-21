defmodule ScrypathOps.Catalog.PlantedStorybook do
  @moduledoc false

  # Test-only backend whose stories are meant to fail. Mounted only by PlantedRouter, never by DevRouter.
  use PhoenixStorybook,
    otp_app: :scrypath_ops,
    content_path: Path.expand("../storybook_planted", __DIR__),
    css_path: "/assets/css/app.css",
    js_path: "/assets/js/storybook.js",
    sandbox_class: "ops-storybook",
    themes: [light: [name: "Light"], dark: [name: "Dark"], system: [name: "System"]],
    themes_strategies: [data_attribute: "theme"]
end
