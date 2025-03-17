defmodule GymBro.Repo.Migrations.CreateSets do
  use Ecto.Migration

  def change do
    create table(:sets) do
      add :reps, :integer
      add :weight, :float
      add :rpe, :float
      add :completed_at, :utc_datetime
      add :notes, :text

      timestamps(type: :utc_datetime)
    end
  end
end
