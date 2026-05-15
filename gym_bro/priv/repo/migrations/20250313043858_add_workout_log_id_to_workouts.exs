defmodule GymBro.Repo.Migrations.AddWorkoutLogIdToWorkouts do
  use Ecto.Migration

  def change do
    alter table(:workouts) do
      add :workout_log_id, references(:workout_logs, on_delete: :delete_all), null: false
    end

    create index(:workouts, [:workout_log_id])
    create index(:workouts, [:date_worked_out])
    create unique_index(:workouts, [:workout_log_id, :status],
             where: "status = 'in_progress'",
             name: :workouts_one_active_per_log_idx)
  end
end
