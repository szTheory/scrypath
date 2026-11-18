if Code.ensure_loaded?(Oban.Migrations) do
  defmodule Scrypath.TestSupport.ObanSQLiteMigration do
    @moduledoc false

    # Creates the oban_jobs table for ObanSQLiteRepo. Oban dispatches to
    # Oban.Migrations.SQLite for the SQLite3 adapter.

    use Ecto.Migration

    def up, do: Oban.Migrations.up()
    def down, do: Oban.Migrations.down()
  end
end
