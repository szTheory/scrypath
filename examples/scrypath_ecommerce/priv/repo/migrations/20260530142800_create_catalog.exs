defmodule ScrypathEcommerce.Repo.Migrations.CreateCatalog do
  use Ecto.Migration

  def change do
    create table(:tenants) do
      add :name, :string, null: false
      timestamps(type: :utc_datetime)
    end

    create table(:categories) do
      add :tenant_id, references(:tenants, on_delete: :delete_all), null: false
      add :name, :string, null: false
      timestamps(type: :utc_datetime)
    end

    create index(:categories, [:tenant_id])

    create table(:products) do
      add :tenant_id, references(:tenants, on_delete: :delete_all), null: false
      add :name, :string, null: false
      add :description, :text
      add :category_id, references(:categories, on_delete: :delete_all), null: false
      timestamps(type: :utc_datetime)
    end

    create index(:products, [:tenant_id])
    create index(:products, [:category_id])

    create table(:variants) do
      add :tenant_id, references(:tenants, on_delete: :delete_all), null: false
      add :product_id, references(:products, on_delete: :delete_all), null: false
      add :sku, :string, null: false
      add :price_cents, :integer, null: false
      add :currency, :string, null: false, default: "USD"
      add :inventory_count, :integer, null: false, default: 0
      add :options, :map, default: %{}
      timestamps(type: :utc_datetime)
    end

    create index(:variants, [:tenant_id])
    create index(:variants, [:product_id])
    create unique_index(:variants, [:tenant_id, :sku])
  end
end
