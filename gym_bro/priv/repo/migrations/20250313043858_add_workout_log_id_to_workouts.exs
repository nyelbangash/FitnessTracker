defmodule GymBro.Repo.Migrations.AddWorkoutLogIdToWorkouts do
  use Ecto.Migration

  def change do
    alter table(:workouts) do
      add :workout_log_id, references(:workout_logs, on_delete: :delete_all)
    end

    create index(:workouts, [:workout_log_id])
  end
end
