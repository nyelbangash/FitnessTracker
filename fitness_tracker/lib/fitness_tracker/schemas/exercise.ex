defmodule FitnessTracker.Schemas.Exercise do
  defstruct [:sets, :exercise_name]

  def new(attrs) do
    {:ok, struct(__MODULE__, attrs)}
  end

  def to_json(%__MODULE__{} = exercise) do
    %{
      sets: Enum.map(exercise.sets, &FitnessTracker.Schemas.Set.to_json/1),
      exercise_name: exercise.exercise_name
    }
  end
end
