defmodule GymBro.Workout do
  use Ecto.Schema
  import Ecto.Changeset

  schema "workouts" do
    field :status, :string
    field :workout_name, :string
    field :length_of_workout, :integer
    field :date_worked_out, :date
    field :start_time, :utc_datetime
    field :end_time, :utc_datetime
    field :current_exercise, :integer
    field :current_set, :integer
    field :rest_timer_end, :utc_datetime
    field :total_volume, :float
    field :target_volume, :float
    field :average_rpe, :float
    field :target_rpe, :float
    field :notes, :string
    field :template_name, :string

    belongs_to :workout_log, GymBro.WorkoutLog
    has_many :exercises, GymBro.Exercise

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(workout, attrs) do
    workout
    |> cast(attrs, [:workout_name, :length_of_workout, :date_worked_out,
                   :status, :start_time, :end_time, :current_exercise,
                   :current_set, :rest_timer_end, :total_volume,
                   :target_volume, :average_rpe, :target_rpe, :notes,
                   :template_name, :workout_log_id])
    |> validate_required([:workout_name, :date_worked_out, :workout_log_id])
    |> foreign_key_constraint(:workout_log_id)
    |> cast_assoc(:exercises)
  end
end
