defmodule GymBro.Repo.Migrations.CreateWorkoutLogs do
  use Ecto.Migration

  def change do
    create table(:workout_logs) do
      add :notes, :text
      add :profile_id, references(:profiles, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:workout_logs, [:profile_id])
  end
end
