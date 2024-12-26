defmodule FitnessTracker.Schemas.Exercise do
  alias FitnessTracker.Schemas.Set
  @derive Jason.Encoder
  defstruct [:sets, :exercise_name]

  def new(attrs) do
    {:ok, struct(__MODULE__, attrs)}
  end

  def to_json(%__MODULE__{} = exercise) do
    %{
      sets: Enum.map(exercise.sets, &Set.to_json/1),
      exercise_name: exercise.exercise_name
    }
  end

  def from_json(json) when is_map(json) do
    %__MODULE__{
      sets: Enum.map(json["sets"], &Set.from_json/1),
      exercise_name: json["exercise_name"]
    }
  end
end
