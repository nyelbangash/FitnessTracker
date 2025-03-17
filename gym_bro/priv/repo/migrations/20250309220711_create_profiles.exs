defmodule GymBro.Repo.Migrations.CreateProfiles do
  use Ecto.Migration

  def change do
    create table(:profiles) do
      add :name, :string
      add :email, :string
      add :height, :integer
      add :weight, :float
      add :password, :string
      add :dob, :date

      timestamps(type: :utc_datetime)
    end
  end
end
