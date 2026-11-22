defmodule ScrypathOpsWeb.OptionalCatalogRoutes do
  @moduledoc false

  # The guard is an `if` outside the `quote`, so it runs when the router expands this macro. The flag
  # is read with the macro form `Application.compile_env(__CALLER__, ...)`, which returns the plain value
  # (`Macro.expand` of the `compile_env/3` macro would yield a call AST, which is always truthy) and
  # also records the read, so changing the flag between two compiles recompiles the router or aborts
  # instead of silently keeping a stale `/storybook` mount.
  defmacro catalog_routes do
    if enabled?(
         Application.compile_env(__CALLER__, :scrypath_ops, :catalog_routes, false),
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
