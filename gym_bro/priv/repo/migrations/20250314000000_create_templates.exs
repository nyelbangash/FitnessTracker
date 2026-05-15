defmodule GymBro.Repo.Migrations.CreateTemplates do
  use Ecto.Migration

  def change do
    create table(:workout_templates) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :name, :string, null: false
      add :exercises, :map, null: false, default: %{"items" => []}
      add :notes, :text

      timestamps(type: :utc_datetime)
    end

    create index(:workout_templates, [:user_id])
    create unique_index(:workout_templates, [:user_id, :name])

    create table(:meal_templates) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :name, :string, null: false
      add :meal_type, :string
      add :calories, :integer
      add :protein, :float
      add :carbs, :float
      add :fat, :float
      add :ingredients, :map, null: false, default: %{"items" => []}
      add :notes, :text

      timestamps(type: :utc_datetime)
    end

    create index(:meal_templates, [:user_id])
    create unique_index(:meal_templates, [:user_id, :name])
  end
end
