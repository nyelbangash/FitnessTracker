defmodule FitnessTracker.Schemas.Workout do
  defstruct [:exercises, :workout_name, :length_of_workout, :date_worked_out]

  def new(exercises, workout_name, length_of_workout)
      when length(exercises) > 0 and
             is_binary(workout_name) and
             workout_name != "" and
             is_number(length_of_workout) and
             length_of_workout > 0 do
    {:ok,
     %__MODULE__{
       exercises: exercises,
       workout_name: workout_name,
       length_of_workout: length_of_workout,
       date_worked_out: DateTime.utc_now()
     }}
  end

  def new(_, _, _), do: {:error, "Invalid workout parameters"}
end
