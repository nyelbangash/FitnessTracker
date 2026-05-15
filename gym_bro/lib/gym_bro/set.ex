defmodule GymBro.Set do
  use Ecto.Schema
  import Ecto.Changeset

  schema "sets" do
    field :reps, :integer
    field :weight, :float
    field :rpe, :float
    field :completed_at, :utc_datetime
    field :notes, :string

    belongs_to :exercise, GymBro.Exercise

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(set, attrs) do
    set
    |> cast(attrs, [:reps, :weight, :rpe, :completed_at, :notes, :exercise_id])
    |> validate_required([:reps, :weight, :exercise_id])
    |> validate_number(:rpe, greater_than: 0, less_than_or_equal_to: 10)
    |> validate_number(:reps, greater_than_or_equal_to: 0)
    |> validate_number(:weight, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:exercise_id)
  end
end
