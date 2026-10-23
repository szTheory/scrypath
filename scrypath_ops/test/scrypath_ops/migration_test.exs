defmodule ScrypathOps.MigrationTest do
  use ScrypathOps.DataCase, async: false

  alias Ecto.Adapters.SQL

  @prefix "scrypath_ops_migration_test"

  defmodule MigrateToV1 do
    use Ecto.Migration

    def up, do: ScrypathOps.Migration.up(version: 1, prefix: "scrypath_ops_migration_test")
    def down, do: ScrypathOps.Migration.down(version: 1, prefix: "scrypath_ops_migration_test")
  end

  # Postgres DDL is transactional, so the schema and the migrated tables live inside the shared
  # sandbox transaction and are rolled back after each test. The migrator's table lock would hold
  # the single sandbox connection while the migration task waits for it, so it is disabled here.
  setup do
    repo_config = Application.fetch_env!(:scrypath_ops, Repo)
    Application.put_env(:scrypath_ops, Repo, Keyword.put(repo_config, :migration_lock, false))
    on_exit(fn -> Application.put_env(:scrypath_ops, Repo, repo_config) end)

    SQL.query!(Repo, ~s(CREATE SCHEMA "#{@prefix}"))
    :ok
  end

  test "up/1 creates the saved searches table in the prefix, records the version and is repeatable" do
    assert :ok = Ecto.Migrator.up(Repo, 1, MigrateToV1, log: false, prefix: @prefix)

    assert table_comment() == "1"

    assert columns() == [
             {"definition", "jsonb", "NO"},
             {"id", "bigint", "NO"},
             {"inserted_at", "timestamp without time zone", "NO"},
             {"name", "text", "NO"},
             {"schema", "text", "NO"},
             {"updated_at", "timestamp without time zone", "NO"}
           ]

    assert %{rows: [[1]]} =
             SQL.query!(
               Repo,
               "SELECT count(*)::int FROM pg_indexes WHERE schemaname = $1 AND indexname = $2",
               [@prefix, "scrypath_ops_saved_searches_name_index"]
             )

    # Running the same version again is a no-op rather than an error.
    assert :ok = Ecto.Migrator.up(Repo, 2, MigrateToV1, log: false, prefix: @prefix)
  end

  test "the store reads and writes through the prefix and down/1 drops the table" do
    :ok = Ecto.Migrator.up(Repo, 1, MigrateToV1, log: false, prefix: @prefix)

    definition = %{
      "playbook_format" => 1,
      "mode" => "search",
      "schema" => "MyApp.Post",
      "q" => "x",
      "opts" => %{}
    }

    assert {:ok, _} =
             ScrypathOps.SavedSearches.create(Repo, "prefixed", definition, prefix: @prefix)

    assert [%{name: "prefixed"}] = ScrypathOps.SavedSearches.list(Repo, prefix: @prefix)
    assert ScrypathOps.SavedSearches.list(Repo) == []

    assert :ok = Ecto.Migrator.down(Repo, 1, MigrateToV1, log: false, prefix: @prefix)
    assert columns() == []
  end

  test "rejects unknown versions and empty prefixes" do
    assert_raise ArgumentError, ~r/:version/, fn ->
      ScrypathOps.Migration.up(version: 99)
    end

    assert_raise ArgumentError, ~r/:prefix/, fn ->
      ScrypathOps.Migration.up(prefix: "")
    end

    assert ScrypathOps.Migration.current_version() == 1
  end

  defp table_comment do
    %{rows: [[comment]]} =
      SQL.query!(
        Repo,
        "SELECT obj_description(to_regclass($1), 'pg_class')",
        ["#{@prefix}.scrypath_ops_saved_searches"]
      )

    comment
  end

  defp columns do
    Repo
    |> SQL.query!(
      """
      SELECT column_name::text, data_type::text, is_nullable::text
      FROM information_schema.columns
      WHERE table_schema = $1 AND table_name = 'scrypath_ops_saved_searches'
      ORDER BY column_name
      """,
      [@prefix]
    )
    |> Map.fetch!(:rows)
    |> Enum.map(&List.to_tuple/1)
  end
end
