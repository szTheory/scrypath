defmodule ScrypathOpsWeb.OptionalCatalogRoutes do
  @moduledoc false

  # The guard is an `if` outside the `quote`, so it runs when the router expands this macro. The flag
  # is read with `Application.get_env` as a plain value: `Macro.expand` of a `compile_env` call would
  # yield a call AST, which is always truthy.
  defmacro catalog_routes do
    if enabled?(
         Application.get_env(:scrypath_ops, :catalog_routes, false),
         Code.ensure_loaded?(PhoenixStorybook.Router)
       ) do
      quote do
        import PhoenixStorybook.Router

        scope "/" do
          storybook_assets()
        end

        scope "/" do
          live_storybook("/storybook", backend_module: ScrypathOps.Catalog.Storybook)
        end
      end
    else
      quote(do: :ok)
    end
  end

  @doc false
  def enabled?(flag, storybook_loaded?), do: flag == true and storybook_loaded? == true
end
