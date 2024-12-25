defmodule FitnessTracker.Schemas.Exercise do
  defstruct [:sets, :exercise_name]

  def new(sets, exercise_name) when is_list(sets) and is_binary(exercise_name) and exercise_name != "" do
    {:ok, %__MODULE__{sets: sets, exercise_name: exercise_name}}
  end

  def new(_, _), do: {:error, "Invalid exercise parameters"}
end
