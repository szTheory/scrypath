defmodule ScrypathOps.Catalog.Storybook do
  @moduledoc false

  # Compiled in dev and test only (`elixirc_paths` in mix.exs); prod and mounted consumers compile `lib` only.
  use PhoenixStorybook,
    otp_app: :scrypath_ops,
    content_path: Path.expand("../../../../storybook", __DIR__),
    css_path: "/assets/css/app.css",
    js_path: "/assets/js/storybook.js",
    sandbox_class: "ops-storybook",
    themes: [light: [name: "Light"], dark: [name: "Dark"], system: [name: "System"]],
    themes_strategies: [data_attribute: "theme"]
end
