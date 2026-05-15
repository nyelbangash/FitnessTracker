defmodule GymBro.Repo.Migrations.CreateMealLogs do
  use Ecto.Migration

  def change do
    create table(:meal_logs) do
      add :date, :date, null: false
      add :notes, :text

      timestamps(type: :utc_datetime)
    end

    create index(:meal_logs, [:date])
  end
end
