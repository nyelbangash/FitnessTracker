defmodule GymBro.Exercise do
  use Ecto.Schema
  import Ecto.Changeset

  schema "exercises" do
    field :exercise_name, :string
    field :target_reps, :integer
    field :target_weight, :float
    field :rest_time, :integer
    field :rpe_target, :float
    field :notes, :string
    field :previous_weight, :float
    field :personal_record, :boolean, default: false
    field :completed_sets, :integer

    belongs_to :workout, GymBro.Workout
    has_many :sets, GymBro.Set

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(exercise, attrs) do
    exercise
    |> cast(attrs, [:exercise_name, :target_reps, :target_weight, :rest_time,
                   :rpe_target, :notes, :previous_weight, :personal_record,
                   :completed_sets, :workout_id])
    |> validate_required([:exercise_name])
    |> foreign_key_constraint(:workout_id)
    |> cast_assoc(:sets)
  end
end
