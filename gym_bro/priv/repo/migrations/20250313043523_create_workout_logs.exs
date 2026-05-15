defmodule GymBro.Repo.Migrations.CreateWorkoutLogs do
  use Ecto.Migration

  def change do
    create table(:workout_logs) do
      add :notes, :text
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:workout_logs, [:user_id])
  end
end
