# lib/fitness_tracker/schemas/workout.ex
defmodule FitnessTracker.Schemas.Workout do
  alias FitnessTracker.Schemas.{Exercise, Set}
  @derive Jason.Encoder
  defstruct [:exercises, :workout_name, :length_of_workout, :date_worked_out]

  def new(attrs) do
    {:ok, struct(__MODULE__, attrs)}
  end

  def to_json(%__MODULE__{} = workout) do
    %{
      exercises: Enum.map(workout.exercises, &Exercise.to_json/1),
      workout_name: workout.workout_name,
      length_of_workout: workout.length_of_workout,
      date_worked_out: workout.date_worked_out
    }
  end

  def create(username, attrs) do
    with {:ok, workout_params} <- Map.fetch(attrs, "workout"),
         true <- is_list(workout_params["exercises"]) || {:error, "exercises must be a list"},
         exercises <- Enum.map(workout_params["exercises"], &parse_exercise/1),
         false <- Enum.any?(exercises, &match?({:error, _}, &1)),
         true <-
           is_binary(workout_params["workout_name"]) || {:error, "workout_name is required"},
         true <-
           is_number(workout_params["length_of_workout"]) ||
             {:error, "length_of_workout must be a number"},
         true <-
           is_binary(workout_params["date_worked_out"]) || {:error, "date_worked_out is required"},
         {:ok, workout} <-
           new(%{
             exercises: exercises,
             workout_name: workout_params["workout_name"],
             length_of_workout: workout_params["length_of_workout"],
             date_worked_out: workout_params["date_worked_out"]
           }),
         profile when not is_nil(profile) <-
           Mongo.find_one(:mongo, "profiles", %{username: username}),
         nil <- Enum.find(profile["workout_log"] || [], &matching_workout?(&1, workout_params)),
         {:ok, _} <-
           Mongo.update_one(:mongo, "profiles", %{username: username}, %{
             "$push": %{"workout_log" => to_json(workout)}
           }) do
      {:ok, workout}
    else
      {:error, message} -> {:error, message}
      nil -> {:error, :profile_not_found}
      _ -> {:error, :workout_exists}
    end
  end

  def get_all(username) do
    case Mongo.find_one(:mongo, "profiles", %{username: username}) do
      nil ->
        {:error, :profile_not_found}

      %{"workout_log" => workout_log} ->
        {:ok, Enum.map(workout_log, &from_json/1)}

      _ ->
        {:error, :workout_log_not_found}
    end
  end

  def get(username, workout_name, date) do
    case Mongo.find_one(:mongo, "profiles", %{username: username}) do
      nil ->
        {:error, :profile_not_found}

      profile ->
        case find_workout(profile["workout_log"], workout_name, date) do
          nil -> {:error, :not_found}
          workout -> {:ok, from_json(workout)}
        end
    end
  end

  def update(username, workout_name, date, attrs) do
    with {:ok, workout_params} <- Map.fetch(attrs, "workout"),
         exercises <- Enum.map(workout_params["exercises"], &parse_exercise/1),
         {:ok, updated_workout} <-
           new(%{
             exercises: exercises,
             workout_name: workout_params["workout_name"],
             length_of_workout: workout_params["length_of_workout"],
             date_worked_out: workout_params["date_worked_out"]
           }),
         profile when not is_nil(profile) <-
           Mongo.find_one(:mongo, "profiles", %{username: username}),
         true <- has_workout?(profile["workout_log"], workout_name, date) do
      update_workout(username, workout_name, date, to_json(updated_workout))
    else
      false -> create(username, attrs)
      nil -> {:error, :profile_not_found}
      error -> error
    end
  end

  def delete(username, workout_name, date) do
    case Mongo.update_one(:mongo, "profiles", %{username: username}, %{
           "$pull": %{
             workout_log: %{
               workout_name: workout_name,
               date_worked_out: date
             }
           }
         }) do
      {:ok, %{modified_count: 1}} -> :ok
      {:ok, %{modified_count: 0}} -> {:error, :not_found}
      {:error, error} -> {:error, error}
    end
  end

  def clear_log(username) do
    case Mongo.update_one(:mongo, "profiles", %{username: username}, %{
           "$set": %{
             workout_log: []
           }
         }) do
      {:ok, %{modified_count: 1}} -> :ok
      {:ok, %{modified_count: 0}} -> {:error, :profile_not_found}
      {:error, error} -> {:error, error}
    end
  end

  # ... helper functions ...
  def from_json(json) when is_map(json) do
    %__MODULE__{
      exercises: Enum.map(json["exercises"], &Exercise.from_json/1),
      workout_name: json["workout_name"],
      length_of_workout: json["length_of_workout"],
      date_worked_out: json["date_worked_out"]
    }
  end

  defp parse_exercise(exercise_params) do
    case exercise_params do
      %{"sets" => sets, "exercise_name" => name} when is_list(sets) ->
        sets = Enum.map(sets, &Set.new/1)
        {:ok, exercise} = Exercise.new(%{sets: sets, exercise_name: name})
        exercise

      _ ->
        {:error, "each exercise must have sets and exercise_name"}
    end
  end

  defp matching_workout?(workout, workout_params) do
    workout["workout_name"] == workout_params["workout_name"] &&
      workout["date_worked_out"] == workout_params["date_worked_out"]
  end

  defp find_workout(workout_log, workout_name, date) do
    Enum.find(workout_log, fn workout ->
      workout["workout_name"] == workout_name &&
        workout["date_worked_out"] == date
    end)
  end

  defp has_workout?(workout_log, workout_name, date) do
    workout_log |> find_workout(workout_name, date) |> is_map()
  end

  defp update_workout(username, workout_name, date, updated_workout) do
    Mongo.update_one(
      :mongo,
      "profiles",
      %{
        username: username,
        workout_log: %{
          "$elemMatch": %{
            workout_name: workout_name,
            date_worked_out: date
          }
        }
      },
      %{
        "$set": %{
          "workout_log.$": updated_workout
        }
      }
    )
  end
end
