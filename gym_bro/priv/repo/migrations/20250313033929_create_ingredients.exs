defmodule GymBro.Repo.Migrations.CreateIngredients do
  use Ecto.Migration

  def change do
    create table(:ingredients) do
      add :name, :string
      add :amount, :integer
      add :unit, :string
      add :calories, :integer
      add :protein, :integer
      add :carbs, :integer
      add :fat, :integer
      add :is_favorite, :boolean, default: false, null: false

      timestamps(type: :utc_datetime)
    end

  end
end
