defmodule GymBro.Repo.Migrations.CreateFoodCache do
  use Ecto.Migration

  def change do
    # Cache of USDA FoodData Central lookups keyed by FDC id. Per-100g macros
    # are canonical; portion macros are computed on the fly.
    create table(:food_cache) do
      add :fdc_id, :bigint, null: false
      add :name, :string, null: false
      # "branded", "foundation", "sr_legacy", "survey", etc. — USDA dataType
      add :data_type, :string
      add :brand_owner, :string

      # Per-100g macros (USDA's canonical representation)
      add :kcal_per_100g, :float, null: false
      add :protein_per_100g, :float, null: false
      add :carbs_per_100g, :float, null: false
      add :fat_per_100g, :float, null: false

      # Raw response so we can re-derive other nutrients later without
      # re-hitting the API.
      add :raw, :map

      timestamps(type: :utc_datetime)
    end

    create unique_index(:food_cache, [:fdc_id])
    create index(:food_cache, [:name])
  end
end
