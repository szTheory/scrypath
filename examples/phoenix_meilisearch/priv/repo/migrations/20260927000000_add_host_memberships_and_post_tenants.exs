defmodule ScrypathDemo.Repo.Migrations.AddHostMembershipsAndPostTenants do
  use Ecto.Migration

  def change do
    create table(:host_actors) do
      add(:name, :string, null: false)

      timestamps(type: :utc_datetime)
    end

    create table(:host_memberships) do
      add(:actor_id, references(:host_actors, on_delete: :delete_all), null: false)
      add(:tenant_id, :integer, null: false)

      timestamps(type: :utc_datetime)
    end

    create(unique_index(:host_memberships, [:actor_id, :tenant_id]))

    alter table(:posts) do
      add(:tenant_id, :integer)
      add(:category, :string)
    end
  end
end
