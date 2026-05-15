defmodule GymBro.Repo.Migrations.AddUserIdToMealLogs do
  use Ecto.Migration

  def change do
    alter table(:meal_logs) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
    end

    create index(:meal_logs, [:user_id])
    create unique_index(:meal_logs, [:user_id, :date])
  end
end
