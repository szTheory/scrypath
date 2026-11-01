defmodule ScrypathOpsWeb.RouterTest do
  use ExUnit.Case, async: false

  import ScrypathOpsWeb.Router

  defmodule CallerAuthPlug do
    @moduledoc false
    @behaviour Plug

    import Plug.Conn

    @header "x-test-caller-identity"
    @valid_identity "test-operator"

    @impl Plug
    def init(opts), do: opts

    @impl Plug
    def call(conn, _opts) do
      case get_req_header(conn, @header) do
        [@valid_identity] -> assign(conn, :test_caller_identity, @valid_identity)
        [] -> conn |> send_resp(:unauthorized, "caller identity required") |> halt()
        _ -> conn |> send_resp(:forbidden, "caller identity is invalid") |> halt()
      end
    end
  end

  defmodule SecuredCallerRouter do
    @moduledoc false
    use ScrypathOpsWeb, :router

    import ScrypathOpsWeb.Router, only: [scrypath_ops_routes: 2]

    pipeline :secured_browser do
      plug(:accepts, ["html"])
      plug(:fetch_session)
      plug(:fetch_live_flash)
      plug(:put_root_layout, html: {ScrypathOpsWeb.Layouts, :root})
      plug(:protect_from_forgery)
      plug(:put_secure_browser_headers)
      plug(ScrypathOpsWeb.RouterTest.CallerAuthPlug)
    end

    scope "/", alias: false do
      pipe_through(:secured_browser)
      scrypath_ops_routes("/admin/search", repo: ScrypathOps.Repo)
    end
  end

  setup do
    previous_allowlist = Application.get_env(:scrypath_ops, :schema_allowlist)
    Application.put_env(:scrypath_ops, :schema_allowlist, [])

    on_exit(fn ->
      case previous_allowlist do
        nil -> Application.delete_env(:scrypath_ops, :schema_allowlist)
        value -> Application.put_env(:scrypath_ops, :schema_allowlist, value)
      end
    end)

    :ok
  end

  defp secured_request(path, identity \\ nil) do
    conn =
      Plug.Test.conn(:get, path)
      |> Plug.Test.init_test_session(%{})
      |> Plug.Conn.put_private(:phoenix_endpoint, ScrypathOpsWeb.Endpoint)

    conn =
      if is_nil(identity) do
        conn
      else
        Plug.Conn.put_req_header(conn, "x-test-caller-identity", identity)
      end

    SecuredCallerRouter.call(conn, SecuredCallerRouter.init([]))
  end

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

  test "secured caller router rejects a request without caller identity over HTTP" do
    conn = secured_request("/admin/search/")

    assert conn.status == 401
    assert conn.resp_body == "caller identity required"
  end

  test "secured caller router rejects an invalid caller identity over HTTP" do
    conn = secured_request("/admin/search/", "not-a-test-operator")

    assert conn.status == 403
    assert conn.resp_body == "caller identity is invalid"
  end

  test "secured caller router permits valid identity into the real mounted Ops route" do
    conn = secured_request("/admin/search/", "test-operator")

    assert conn.status == 200
    assert conn.resp_body =~ "Control Room"
    assert conn.resp_body =~ "data-phx-main"
    assert conn.private[:phoenix_router] == SecuredCallerRouter
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
