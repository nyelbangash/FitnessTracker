defmodule GymBro.WorkoutLog do
  use Ecto.Schema
  import Ecto.Changeset

  schema "workout_logs" do
    field :notes, :string

    belongs_to :profile, GymBro.Profile
    has_many :workouts, GymBro.Workout

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(workout_log, attrs) do
    workout_log
    |> cast(attrs, [:notes, :profile_id])
    |> validate_required([:profile_id])
    |> foreign_key_constraint(:profile_id)
    |> cast_assoc(:workouts)
  end
end
