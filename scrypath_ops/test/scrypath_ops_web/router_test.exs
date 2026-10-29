defmodule ScrypathOpsWeb.RouterTest do
  use ExUnit.Case, async: true

  import ScrypathOpsWeb.Router

  test "macro expands with valid config" do
    ast =
      quote do
        defmodule TestRouter do
          use Phoenix.Router
          import ScrypathOpsWeb.Router

          scrypath_ops_routes("/ops", repo: ScrypathOps.Repo)
        end
      end

    assert [{_, _} | _] = Code.compile_quoted(ast)
  end

  test "macro retains supported operator, legacy, and asset routes" do
    ast =
      quote do
        defmodule SupportedRoutesRouter do
          use Phoenix.Router
          import ScrypathOpsWeb.Router

          scrypath_ops_routes("/ops", repo: ScrypathOps.Repo)
        end
      end

    compiled_modules = Code.compile_quoted(ast) |> Enum.map(&elem(&1, 0))
    assert SupportedRoutesRouter in compiled_modules
    router_module = Enum.find(compiled_modules, &(&1 == SupportedRoutesRouter))
    route_paths = router_module |> apply(:__routes__, []) |> Enum.map(& &1.path)

    for path <- [
          "/ops",
          "/ops/health",
          "/ops/posture",
          "/ops/failed-sync",
          "/ops/sync-and-index",
          "/ops/sync-drift",
          "/ops/search",
          "/ops/playbooks",
          "/ops/help",
          "/ops/assets",
          "/ops/images",
          "/ops/favicon.svg",
          "/ops/favicon.ico"
        ] do
      assert path in route_paths,
             "expected supported route #{path} to remain mounted"
    end
  end

  test "macro raises NimbleOptions.ValidationError for invalid config" do
    assert_raise NimbleOptions.ValidationError, fn ->
      quote do
        defmodule InvalidRouter do
          use Phoenix.Router
          import ScrypathOpsWeb.Router

          scrypath_ops_routes("/ops")
        end
      end
      |> Code.compile_quoted()
    end
  end
end
