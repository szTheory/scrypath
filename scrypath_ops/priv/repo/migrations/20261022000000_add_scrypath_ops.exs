defmodule ScrypathOps.Repo.Migrations.AddScrypathOps do
  use Ecto.Migration

  def up, do: ScrypathOps.Migration.up(version: 1)

  def down, do: ScrypathOps.Migration.down(version: 1)
end
