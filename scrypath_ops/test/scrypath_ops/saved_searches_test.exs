defmodule ScrypathOps.SavedSearchesTest do
  use ScrypathOps.DataCase, async: true

  alias ScrypathOps.SavedSearches
  alias ScrypathOps.SavedSearches.SavedSearch

  @fixture_dir Path.expand("../../examples/saved_searches", __DIR__)

  defp definition(query, extra \\ %{}) do
    Map.merge(
      %{
        "playbook_format" => 1,
        "mode" => "search",
        "schema" => "ScrypathOps.Test.OpsPostA",
        "q" => query,
        "opts" => %{}
      },
      extra
    )
  end

  defp many_definition do
    %{
      "playbook_format" => 1,
      "mode" => "search_many",
      "entries" => [
        ["ScrypathOps.Test.OpsPostA", "q", %{}],
        ["ScrypathOps.Test.OpsPostB", "q", %{}],
        ["ScrypathOps.Test.OpsPostA", "other", %{}]
      ],
      "opts" => %{}
    }
  end

  test "create/4 stores a validated definition and derives the schema column" do
    assert {:ok, %SavedSearch{} = saved} =
             SavedSearches.create(Repo, "  Daily check  ", definition("hello"))

    assert saved.name == "Daily check"
    assert saved.schema == "ScrypathOps.Test.OpsPostA"
    assert {:ok, fetched} = SavedSearches.get(Repo, "Daily check")
    assert fetched.definition == definition("hello")

    assert {:ok, many} = SavedSearches.create(Repo, "Federated", many_definition())
    assert many.schema == "ScrypathOps.Test.OpsPostA,ScrypathOps.Test.OpsPostB"
  end

  test "create/4 rejects a duplicate name, an invalid name and an invalid definition" do
    assert {:ok, _} = SavedSearches.create(Repo, "taken", definition("one"))
    assert {:error, :name_taken} = SavedSearches.create(Repo, "taken", definition("two"))
    assert {:error, :invalid_name} = SavedSearches.create(Repo, "   ", definition("two"))

    assert {:error, :invalid_name} =
             SavedSearches.create(Repo, String.duplicate("n", 121), definition("two"))

    assert {:error, {:invalid_saved_search, {:invalid_playbook_format, 2}}} =
             SavedSearches.create(Repo, "bad", definition("x", %{"playbook_format" => 2}))

    assert {:ok, %{definition: %{"q" => "one"}}} = SavedSearches.get(Repo, "taken")
  end

  test "list/2 orders by name and get/3 reports missing names" do
    for name <- ["b", "a", "c"], do: {:ok, _} = SavedSearches.create(Repo, name, definition(name))

    assert ["a", "b", "c"] = Repo |> SavedSearches.list() |> Enum.map(& &1.name)
    assert {:error, :not_found} = SavedSearches.get(Repo, "missing")
  end

  test "save/4 inserts or replaces the definition for a name" do
    assert {:ok, first} = SavedSearches.save(Repo, "shared", definition("first"))
    assert {:ok, second} = SavedSearches.save(Repo, "shared", many_definition())

    assert second.id == first.id
    assert [%{definition: definition, schema: schema}] = SavedSearches.list(Repo)
    assert definition == many_definition()
    assert schema == "ScrypathOps.Test.OpsPostA,ScrypathOps.Test.OpsPostB"
  end

  test "rename/4 moves a saved search and refuses an occupied name" do
    {:ok, _} = SavedSearches.create(Repo, "from", definition("from"))
    {:ok, _} = SavedSearches.create(Repo, "other", definition("other"))

    assert {:error, :name_taken} = SavedSearches.rename(Repo, "from", "other")
    assert {:error, :not_found} = SavedSearches.rename(Repo, "missing", "new")
    assert {:ok, %{name: "to"}} = SavedSearches.rename(Repo, "from", "to")
    assert {:error, :not_found} = SavedSearches.get(Repo, "from")
    assert {:ok, %{definition: %{"q" => "from"}}} = SavedSearches.get(Repo, "to")
  end

  test "duplicate/4 copies the definition and suggest_duplicate_name/3 avoids taken names" do
    {:ok, _} = SavedSearches.create(Repo, "check", definition("check"))

    assert SavedSearches.suggest_duplicate_name(Repo, "check") == "check copy"
    assert {:ok, copy} = SavedSearches.duplicate(Repo, "check", "check copy")
    assert copy.definition == definition("check")
    assert SavedSearches.suggest_duplicate_name(Repo, "check") == "check copy 2"
    assert {:error, :name_taken} = SavedSearches.duplicate(Repo, "check", "check copy")
    assert {:error, :not_found} = SavedSearches.duplicate(Repo, "missing", "x")
  end

  test "delete/3 removes a saved search once" do
    {:ok, _} = SavedSearches.create(Repo, "gone", definition("gone"))

    assert :ok = SavedSearches.delete(Repo, "gone")
    assert {:error, :not_found} = SavedSearches.delete(Repo, "gone")
    assert SavedSearches.list(Repo) == []
  end

  test "import_json/4 accepts existing v1 files unchanged and export_json/1 round-trips them" do
    files = Path.wildcard(Path.join(@fixture_dir, "*.json"))
    assert files != []

    for path <- files do
      json = File.read!(path)
      name = Path.basename(path)

      assert {:ok, saved} = SavedSearches.import_json(Repo, name, json)
      assert saved.definition == Jason.decode!(json)

      assert {:ok, exported} = SavedSearches.export_json(saved)
      assert Jason.decode!(exported) == Jason.decode!(json)
      assert {:ok, again} = SavedSearches.import_json(Repo, name <> " again", exported)
      assert again.definition == saved.definition
    end
  end

  test "import_json/4 reports malformed JSON and invalid definitions" do
    assert {:error, {:invalid_json, _}} = SavedSearches.import_json(Repo, "x", "{")
    assert {:error, {:invalid_json, :not_object}} = SavedSearches.import_json(Repo, "x", "[]")

    assert {:error, {:invalid_saved_search, _}} =
             SavedSearches.import_json(Repo, "x", Jason.encode!(%{"mode" => "search"}))

    assert SavedSearches.list(Repo) == []
  end

  test "valid_name?/1 trims, bounds length and rejects control characters" do
    assert SavedSearches.valid_name?("one.json")
    assert SavedSearches.valid_name?("Daily catalog check")
    refute SavedSearches.valid_name?("  ")
    refute SavedSearches.valid_name?("tab\there")
    refute SavedSearches.valid_name?(String.duplicate("n", 121))
    refute SavedSearches.valid_name?(nil)
  end
end
