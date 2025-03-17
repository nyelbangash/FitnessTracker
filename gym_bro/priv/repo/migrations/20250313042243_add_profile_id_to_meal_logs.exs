defmodule GymBro.Repo.Migrations.AddProfileIdToMealLogs do
  use Ecto.Migration

  def change do
    alter table(:meal_logs) do
      add :profile_id, references(:profiles, on_delete: :delete_all)
    end

    create unique_index(:meal_logs, [:profile_id])
  end
end
