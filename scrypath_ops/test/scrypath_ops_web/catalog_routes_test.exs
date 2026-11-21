defmodule ScrypathOpsWeb.CatalogRoutesTest do
  # Mutates the application env that the route macro reads at expansion, so it cannot run async.
  use ExUnit.Case, async: false

  alias ScrypathOpsWeb.OptionalCatalogRoutes

  @macro_source Path.expand("../../lib/scrypath_ops_web/optional_catalog_routes.ex", __DIR__)
  @iframe_route "/storybook/iframe/*story"

  setup do
    previous = Application.fetch_env(:scrypath_ops, :catalog_routes)

    on_exit(fn ->
      case previous do
        {:ok, value} -> Application.put_env(:scrypath_ops, :catalog_routes, value)
        :error -> Application.delete_env(:scrypath_ops, :catalog_routes)
      end
    end)

    :ok
  end

  test "enabled?/2 is true only for the literal flag true with the storybook router loaded" do
    assert OptionalCatalogRoutes.enabled?(true, true)

    for flag <- [false, nil, "true", 1, :yes] do
      refute OptionalCatalogRoutes.enabled?(flag, true), "flag #{inspect(flag)} must stay off"
    end

    refute OptionalCatalogRoutes.enabled?(true, false)
    refute OptionalCatalogRoutes.enabled?(true, nil)
    refute OptionalCatalogRoutes.enabled?(false, false)
  end

  test "a router compiled with the flag off has no storybook route" do
    Application.put_env(:scrypath_ops, :catalog_routes, false)

    paths = router_paths(ScrypathOpsWeb.CatalogRoutesTest.FlagOffRouter, OptionalCatalogRoutes)

    assert storybook_paths(paths) == []
  end

  test "a router compiled with the flag unset has no storybook route" do
    Application.delete_env(:scrypath_ops, :catalog_routes)

    paths = router_paths(ScrypathOpsWeb.CatalogRoutesTest.FlagUnsetRouter, OptionalCatalogRoutes)

    assert storybook_paths(paths) == []
  end

  test "a router compiled with the flag on mounts the storybook (positive control)" do
    Application.put_env(:scrypath_ops, :catalog_routes, true)

    paths = router_paths(ScrypathOpsWeb.CatalogRoutesTest.FlagOnRouter, OptionalCatalogRoutes)

    assert @iframe_route in paths
  end

  test "planted: a guard-stripped copy of the macro mounts the storybook with the flag off" do
    Application.put_env(:scrypath_ops, :catalog_routes, false)

    stripped = ScrypathOpsWeb.CatalogRoutesTest.GuardStripped
    compile_guard_stripped_macro!(stripped)

    paths = router_paths(ScrypathOpsWeb.CatalogRoutesTest.StrippedRouter, stripped)

    # The flag-off assertion above would fail on exactly this router, which is what makes it a guard test.
    assert @iframe_route in paths
  end

  defp router_paths(router, macro) do
    ast =
      quote do
        defmodule unquote(router) do
          use Phoenix.Router, helpers: false

          require unquote(macro)
          unquote(macro).catalog_routes()
        end
      end

    [{^router, _binary}] = Code.compile_quoted(ast)

    router |> apply(:__routes__, []) |> Enum.map(& &1.path)
  end

  defp storybook_paths(paths), do: Enum.filter(paths, &String.starts_with?(&1, "/storybook"))

  defp compile_guard_stripped_macro!(new_module) do
    original = [:ScrypathOpsWeb, :OptionalCatalogRoutes]
    renamed = new_module |> Module.split() |> Enum.map(&String.to_atom/1)

    {ast, stripped_ifs} =
      @macro_source
      |> File.read!()
      |> Code.string_to_quoted!()
      |> Macro.prewalk(0, fn
        {:__aliases__, meta, ^original}, count ->
          {{:__aliases__, meta, renamed}, count}

        {:if, _meta, [_condition, clauses]}, count when is_list(clauses) ->
          {Keyword.fetch!(clauses, :do), count + 1}

        node, count ->
          {node, count}
      end)

    if stripped_ifs == 0, do: flunk("no if node to strip: the planted guard removal is a no-op")

    [{^new_module, _binary}] = Code.compile_quoted(ast)
    :ok
  end
end
