defmodule ScrypathDemo.Repo.Migrations.AddAuthorsAndPostAuthorFields do
  use Ecto.Migration

  def change do
    create table(:authors) do
      add(:name, :string)

      timestamps(type: :utc_datetime)
    end

    alter table(:posts) do
      add(:author_id, references(:authors))
      add(:author_name, :string)
    end
  end
end
