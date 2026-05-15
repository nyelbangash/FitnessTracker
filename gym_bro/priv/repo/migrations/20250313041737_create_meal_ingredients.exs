defmodule GymBro.Repo.Migrations.CreateMealIngredients do
  use Ecto.Migration

  def change do
    create table(:meal_ingredients, primary_key: false) do
      add :meal_id, references(:meals, on_delete: :delete_all), primary_key: true
      add :ingredient_id, references(:ingredients, on_delete: :delete_all), primary_key: true
      add :amount, :float
      add :unit, :string
    end

    create index(:meal_ingredients, [:meal_id])
    create index(:meal_ingredients, [:ingredient_id])
  end
end
