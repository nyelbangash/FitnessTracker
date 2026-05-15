defmodule GymBro.Workout do
  use Ecto.Schema
  import Ecto.Changeset

  schema "workouts" do
    field :status, :string, default: "completed"
    field :workout_name, :string
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

  @valid_statuses ~w(planned in_progress completed)

  @doc false
  def changeset(workout, attrs) do
    workout
    |> cast(attrs, [:workout_name, :date_worked_out,
                   :status, :start_time, :end_time, :current_exercise,
                   :current_set, :rest_timer_end, :total_volume,
                   :target_volume, :average_rpe, :target_rpe, :notes,
                   :template_name, :workout_log_id])
    |> validate_required([:workout_name, :date_worked_out, :workout_log_id])
    |> validate_inclusion(:status, @valid_statuses)
    |> foreign_key_constraint(:workout_log_id)
    |> unique_constraint(:status,
         name: :workouts_one_active_per_log_idx,
         message: "active workout already exists")
    |> cast_assoc(:exercises)
  end

  def length_seconds(%__MODULE__{start_time: start, end_time: finish})
      when not is_nil(start) and not is_nil(finish),
      do: DateTime.diff(finish, start)
  def length_seconds(_), do: nil
end
