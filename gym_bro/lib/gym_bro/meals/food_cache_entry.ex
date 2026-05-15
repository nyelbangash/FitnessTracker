defmodule GymBro.Meals.FoodCacheEntry do
  use Ecto.Schema
  import Ecto.Changeset

  schema "food_cache" do
    field :fdc_id, :integer
    field :name, :string
    field :data_type, :string
    field :brand_owner, :string

    field :kcal_per_100g, :float
    field :protein_per_100g, :float
    field :carbs_per_100g, :float
    field :fat_per_100g, :float

    field :raw, :map

    timestamps(type: :utc_datetime)
  end

  def changeset(entry, attrs) do
    entry
    |> cast(attrs, [
      :fdc_id, :name, :data_type, :brand_owner,
      :kcal_per_100g, :protein_per_100g, :carbs_per_100g, :fat_per_100g, :raw
    ])
    |> validate_required([:fdc_id, :name, :kcal_per_100g, :protein_per_100g, :carbs_per_100g, :fat_per_100g])
    |> unique_constraint(:fdc_id)
  end
end
