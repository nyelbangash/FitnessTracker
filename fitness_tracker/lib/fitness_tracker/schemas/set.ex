defmodule FitnessTracker.Schemas.Set do
  defstruct [:reps, :weight]

  def new(reps, weight)
      when is_integer(reps) and reps > 0 and is_number(weight) and weight >= 0 do
    {:ok, %__MODULE__{reps: reps, weight: weight}}
  end

  def new(_, _), do: {:error, "Invalid set parameters"}
end
