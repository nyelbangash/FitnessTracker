defmodule GymBro.Repo.Migrations.CreateExercisesSets do
  use Ecto.Migration

  def change do
    alter table(:sets) do
      add :exercise_id, references(:exercises, on_delete: :delete_all)
    end

    create index(:sets, [:exercise_id])
  end
end
