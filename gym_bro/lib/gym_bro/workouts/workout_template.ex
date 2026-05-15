defmodule GymBro.Workouts.WorkoutTemplate do
  use Ecto.Schema
  import Ecto.Changeset

  schema "workout_templates" do
    field :name, :string
    field :exercises, :map, default: %{"items" => []}
    field :notes, :string

    belongs_to :user, GymBro.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def changeset(template, attrs) do
    template
    |> cast(attrs, [:name, :exercises, :notes, :user_id])
    |> validate_required([:name, :user_id])
    |> foreign_key_constraint(:user_id)
    |> unique_constraint([:user_id, :name])
  end
end
