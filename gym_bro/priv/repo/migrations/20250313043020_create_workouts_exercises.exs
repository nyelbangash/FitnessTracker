defmodule GymBro.Repo.Migrations.CreateWorkoutsExercises do
  use Ecto.Migration

  def change do
    alter table(:exercises) do
      add :workout_id, references(:workouts, on_delete: :delete_all)
    end

    create index(:exercises, [:workout_id])
  end
end
