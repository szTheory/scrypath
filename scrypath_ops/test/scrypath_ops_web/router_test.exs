defmodule ScrypathOpsWeb.RouterTest do
  use ExUnit.Case, async: true
  
  import ScrypathOpsWeb.Router

  test "macro expands with valid config" do
    ast = quote do
      defmodule TestRouter do
        use Phoenix.Router
        import ScrypathOpsWeb.Router

        scrypath_ops_routes("/ops", repo: ScrypathOps.Repo)
      end
    end
    
    assert [{:module, _, _, _}] = Code.compile_quoted(ast)
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
