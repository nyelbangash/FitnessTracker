defmodule GymBro.Repo.Migrations.AddThemeToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :theme, :string, null: false, default: "paper"
    end
  end
end
