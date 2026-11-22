defmodule ScrypathOpsWeb.CatalogEndpointTest do
  # Dispatches through `ScrypathOps.Catalog.Endpoint` and its router, the pair `mix
  # scrypath_ops.catalog.serve` binds to 127.0.0.1, without opening a port (`server: false` in
  # config/test.exs). The catalog contract renders every story through the main dev endpoint, and
  # its planted tests use a hand-built copy of this endpoint, so without this file a regression in
  # the real plug order, session, static scope or router would stay green and be found by eye.
  #
  # Synchronous: the endpoint is a named process and its config lives in VM-wide tables. It checks
  # out no database connection; the telemetry handler below fails the test if any request or
  # LiveView process runs a query.
  use ExUnit.Case, async: false

  import Phoenix.ConnTest
  import Plug.Conn, only: [get_resp_header: 2]
  import Phoenix.LiveViewTest, only: [live: 1, render: 1]

  @endpoint ScrypathOps.Catalog.Endpoint

  @iframe "/storybook/iframe/primitives/ops_button?variation_id=default&theme=light"

  setup do
    handler = "catalog-endpoint-test-#{System.unique_integer([:positive])}"

    :ok =
      :telemetry.attach(
        handler,
        [:scrypath_ops, :repo, :query],
        &__MODULE__.forward_query/4,
        self()
      )

    on_exit(fn -> :telemetry.detach(handler) end)

    start_supervised!(ScrypathOps.Catalog.Endpoint)
    :ok
  end

  @doc false
  def forward_query(_event, _measurements, metadata, test_pid),
    do: send(test_pid, {:repo_query, metadata[:query]})

  describe "the no-database check" do
    test "its handler hears the repo's query event, so silence below means no query ran" do
      assert ScrypathOps.Repo.config()[:telemetry_prefix] ++ [:query] ==
               [:scrypath_ops, :repo, :query]

      :telemetry.execute([:scrypath_ops, :repo, :query], %{}, %{query: "planted"})

      assert_received {:repo_query, "planted"}
    end
  end

  describe "the catalog's own routes answer" do
    test "the landing page prints where the catalog comes from" do
      conn = get(build_conn(), "/storybook/welcome")

      doc = conn |> html_response(200) |> LazyHTML.from_document()
      assert Enum.count(LazyHTML.query(doc, "[data-catalog-main-sha]")) == 1

      assert LazyHTML.text(LazyHTML.query(doc, "#catalog-source")) =~
               "Where this storybook comes from"

      refute_received {:repo_query, _query}
    end

    test "/storybook sends the reviewer to the landing page" do
      conn = get(build_conn(), "/storybook")

      assert redirected_to(conn, 302) == "/storybook/welcome"
    end

    test "an iframe story renders with the built stylesheet and mounts as a LiveView" do
      conn = get(build_conn(), @iframe)

      html = html_response(conn, 200)
      doc = LazyHTML.from_document(html)
      assert html =~ ~r|@import "/assets/css/app\.css\?hash=[0-9a-f]{32}"|
      refute Enum.empty?(LazyHTML.query(doc, ~s(body[data-theme="light"])))

      # The connected mount goes through this endpoint's session and LiveView signing salt.
      assert {:ok, view, _dead_html} = live(conn)
      live_doc = view |> render() |> LazyHTML.from_fragment()
      assert LazyHTML.text(LazyHTML.query(live_doc, "button")) =~ "Retry"

      refute_received {:repo_query, _query}
    end
  end

  describe "what a story page references is served" do
    test "the scripts and the stylesheet of an iframe story answer, from the static scope and the storybook's assets" do
      html = build_conn() |> get(@iframe) |> html_response(200)
      doc = LazyHTML.from_document(html)

      scripts = doc |> LazyHTML.query("script[src]") |> LazyHTML.attribute("src")

      [_match, stylesheet] =
        Regex.run(~r|@import "(/assets/css/app\.css\?hash=[0-9a-f]{32})"|, html)

      # Both owners of a page asset are involved: the endpoint's static files and the router's
      # storybook assets, so dropping either one fails here and not in a browser.
      assert Enum.any?(scripts, &String.starts_with?(&1, "/assets/js/storybook.js?hash="))
      assert Enum.any?(scripts, &String.starts_with?(&1, "/storybook/assets/iframejs-"))

      for path <- [stylesheet | scripts] do
        conn = get(build_conn(), path)

        assert conn.status == 200, "#{path}: answered #{conn.status}"
        assert byte_size(conn.resp_body) > 0, "#{path}: empty body"
      end

      refute_received {:repo_query, _query}
    end
  end

  describe "static files" do
    test "the product font and the built stylesheet are served from the static scope" do
      font = get(build_conn(), "/assets/fonts/ui.woff2")

      assert font.status == 200
      assert font |> get_resp_header("content-type") |> hd() =~ "woff2"
      assert binary_part(font.resp_body, 0, 4) == "wOF2"

      css = get(build_conn(), "/assets/css/app.css")

      assert css.status == 200
      assert css |> get_resp_header("content-type") |> hd() =~ "text/css"
      assert css.resp_body =~ "--font-sans"
    end
  end

  describe "nothing but the storybook and its static files" do
    test "the catalog router routes /storybook and nothing else" do
      paths = for route <- Phoenix.Router.routes(ScrypathOps.Catalog.Router), do: route.path

      assert paths != []

      assert Enum.reject(paths, &String.starts_with?(&1, "/storybook")) == [],
             "routes outside /storybook: #{inspect(paths)}"
    end

    test "every page of the host app is refused by the catalog router with a bare 404" do
      pages = host_app_pages()

      # The cause is real: the host app has these routes, so the refusals below are not vacuous.
      assert "/ops/failed-sync" in pages
      assert "/ops/health" in pages

      for path <- ["/", "/ops", "/admin", "/admin/search"] ++ pages do
        conn = get(build_conn(), path)

        # The catalog router matched nothing (it is the router on the conn), so the 404 is its refusal
        # and the body is the bare error page, not a screen of the host app or the storybook.
        assert conn.status == 404, "#{path}: answered #{conn.status}"
        assert conn.private.phoenix_router == ScrypathOps.Catalog.Router, "#{path}: wrong router"
        assert conn.resp_body =~ "Not Found", "#{path}: not the error page"
        refute conn.resp_body =~ "data-catalog-main-sha", "#{path}: served the catalog"
        refute conn.resp_body =~ "Failed sync", "#{path}: served a host app screen"
      end

      refute_received {:repo_query, _query}
    end
  end

  # The static GET pages of the host app's dev router, outside the storybook.
  defp host_app_pages do
    for %{verb: :get, path: path} <- Phoenix.Router.routes(ScrypathOpsWeb.DevRouter),
        not String.starts_with?(path, "/storybook"),
        not String.contains?(path, [":", "*"]),
        path != "/",
        uniq: true,
        do: path
  end
end
