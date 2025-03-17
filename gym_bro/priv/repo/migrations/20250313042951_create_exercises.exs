defmodule GymBro.Repo.Migrations.CreateExercises do
  use Ecto.Migration

  def change do
    create table(:exercises) do
      add :exercise_name, :string
      add :target_reps, :integer
      add :target_weight, :float
      add :rest_time, :integer
      add :rpe_target, :float
      add :notes, :text
      add :previous_weight, :float
      add :personal_record, :boolean, default: false, null: false
      add :completed_sets, :integer

      timestamps(type: :utc_datetime)
    end
  end
end
