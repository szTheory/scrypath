defmodule ScrypathOps.Migrations.V01 do
  @moduledoc false

  use Ecto.Migration

  def up(%{prefix: prefix}) do
    create_if_not_exists table(:scrypath_ops_saved_searches, prefix: prefix) do
      add(:name, :text, null: false)
      add(:schema, :text, null: false)
      add(:definition, :map, null: false)

      timestamps(type: :utc_datetime_usec)
    end

    create_if_not_exists(unique_index(:scrypath_ops_saved_searches, [:name], prefix: prefix))
  end

  def down(%{prefix: prefix}) do
    drop_if_exists(table(:scrypath_ops_saved_searches, prefix: prefix))
  end
end
