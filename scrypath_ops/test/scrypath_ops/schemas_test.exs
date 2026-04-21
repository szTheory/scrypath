defmodule ScrypathOps.SchemasTest do
  use ExUnit.Case, async: true

  alias ScrypathOps.Schemas

  test "allowlist/0 defaults to [] in test" do
    assert Schemas.allowlist() == []
  end

  test "modules_from_csv/1 parses a single dotted module string" do
    assert [ScrypathOps.Test.AllowlistStub] ==
             Schemas.modules_from_csv("ScrypathOps.Test.AllowlistStub")
  end

  test "allowlist/0 reads configured list from Application env" do
    previous = Application.get_env(:scrypath_ops, :schema_allowlist)

    on_exit(fn ->
      if previous == nil do
        Application.delete_env(:scrypath_ops, :schema_allowlist)
      else
        Application.put_env(:scrypath_ops, :schema_allowlist, previous)
      end
    end)

    Application.put_env(:scrypath_ops, :schema_allowlist, [ScrypathOps.Test.AllowlistStub])
    assert Schemas.allowlist() == [ScrypathOps.Test.AllowlistStub]
  end
end
