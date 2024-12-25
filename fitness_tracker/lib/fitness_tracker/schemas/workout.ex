# lib/fitness_tracker/schemas/workout.ex
defmodule FitnessTracker.Schemas.Workout do
  defstruct [:exercises, :workout_name, :length_of_workout, :date_worked_out]

  def new(attrs) do
    {:ok, struct(__MODULE__, attrs)}
  end

  def to_json(%__MODULE__{} = workout) do
    %{
      exercises: Enum.map(workout.exercises, &FitnessTracker.Schemas.Exercise.to_json/1),
      workout_name: workout.workout_name,
      length_of_workout: workout.length_of_workout,
      date_worked_out: workout.date_worked_out
    }
  end
end
