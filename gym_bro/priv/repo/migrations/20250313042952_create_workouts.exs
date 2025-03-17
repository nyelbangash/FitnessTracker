defmodule GymBro.Repo.Migrations.CreateWorkouts do
  use Ecto.Migration

  def change do
    create table(:workouts) do
      add :workout_name, :string
      add :length_of_workout, :integer
      add :date_worked_out, :date
      add :status, :string
      add :start_time, :utc_datetime
      add :end_time, :utc_datetime
      add :current_exercise, :integer
      add :current_set, :integer
      add :rest_timer_end, :utc_datetime
      add :total_volume, :float
      add :target_volume, :float
      add :average_rpe, :float
      add :target_rpe, :float
      add :notes, :text
      add :template_name, :string

      timestamps(type: :utc_datetime)
    end
  end
end
