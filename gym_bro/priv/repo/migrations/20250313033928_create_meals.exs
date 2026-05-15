defmodule GymBro.Repo.Migrations.CreateMeals do
  use Ecto.Migration

  def change do
    create table(:meals) do
      add :name, :string, null: false
      add :time_eaten, :time
      add :meal_type, :string
      add :calories, :integer
      add :protein, :float
      add :carbs, :float
      add :fat, :float
      add :is_favorite, :boolean, default: false
      add :is_recurring, :boolean, default: false
      add :is_quick_access, :boolean, default: false
      add :template_name, :string
      add :notes, :text
      add :schedule, :string

      add :meal_log_id, references(:meal_logs, on_delete: :delete_all)

      timestamps()
    end
    
    create index(:meals, [:meal_log_id])
    create index(:meals, [:name])
  end
end
