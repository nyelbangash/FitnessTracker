defmodule FitnessTracker.Schemas.Workout do
  use FitnessTracker.Schemas.BaseLog,
    log_type: "workout_log",
    name_field: "workout_name",
    date_field: "date_worked_out"

  alias FitnessTracker.Schemas.{Exercise, Set}
  @derive Jason.Encoder
  defstruct [
    :workout_name,
    :exercises,
    :length_of_workout,
    :date_worked_out,
    # New: "planned", "in_progress", "completed"
    :status,
    # New: When workout started
    :start_time,
    # New: When workout ended
    :end_time,
    # New: Index of current exercise
    :current_exercise,
    # New: Index of current set
    :current_set,
    # New: When current rest period ends
    :rest_timer_end,
    # New: Total weight × reps
    :total_volume,
    # New: Target volume goal
    :target_volume,
    # New: Average RPE across all sets
    :average_rpe,
    # New: Target RPE range
    :target_rpe,
    # New: Workout notes
    :notes,
    # New: If saved as template
    :template_name
  ]

  def new(attrs), do: {:ok, struct(__MODULE__, attrs)}

  def create(username, attrs) do
    with {:ok, workout_params} <- extract_workout_params(attrs),
         {:ok, exercises} <- parse_exercises(workout_params),
         {:ok, workout} <- build_workout(workout_params, exercises),
         :ok <- validate_unique_workout(username, workout_params),
         {:ok, _} <- save_item(username, workout) do
      {:ok, workout}
    end
  end

  def to_json(%__MODULE__{} = workout) do
    %{
      workout_name: workout.workout_name,
      exercises: Enum.map(workout.exercises, &Exercise.to_json/1),
      length_of_workout: workout.length_of_workout,
      date_worked_out: workout.date_worked_out,
      status: workout.status,
      start_time: workout.start_time,
      end_time: workout.end_time,
      current_exercise: workout.current_exercise,
      current_set: workout.current_set,
      rest_timer_end: workout.rest_timer_end,
      total_volume: workout.total_volume,
      target_volume: workout.target_volume,
      average_rpe: workout.average_rpe,
      target_rpe: workout.target_rpe,
      notes: workout.notes,
      template_name: workout.template_name
    }
  end

  def from_json(json) when is_map(json) do
    %__MODULE__{
      workout_name: json["workout_name"],
      exercises: Enum.map(json["exercises"] || [], &Exercise.from_json/1),
      length_of_workout: json["length_of_workout"],
      date_worked_out: json["date_worked_out"],
      status: json["status"],
      start_time: json["start_time"],
      end_time: json["end_time"],
      current_exercise: json["current_exercise"],
      current_set: json["current_set"],
      rest_timer_end: json["rest_timer_end"],
      total_volume: json["total_volume"],
      target_volume: json["target_volume"],
      average_rpe: json["average_rpe"],
      target_rpe: json["target_rpe"],
      notes: json["notes"],
      template_name: json["template_name"]
    }
  end

  # New function to start a workout
  def start_workout(username, workout_name) do
    with {:ok, workout} <- get_template(username, workout_name),
         {:ok, active_workout} <- initialize_active_workout(workout),
         :ok <- save_active_workout(username, active_workout) do
      {:ok, active_workout}
    end
  end

  # New function to get active workout
  def get_active_workout(username) do
    case get_profile(username) do
      {:ok, %{"active_workout" => nil}} -> {:error, :no_active_workout}
      {:ok, %{"active_workout" => workout}} -> {:ok, from_json(workout)}
      error -> error
    end
  end

  # New function to complete a set
  def complete_set(username, %{reps: reps, weight: weight, rpe: rpe}) do
    with {:ok, workout} <- get_active_workout(username),
         {:ok, updated_workout} <- record_set(workout, reps, weight, rpe),
         :ok <- save_active_workout(username, updated_workout) do
      {:ok, updated_workout}
    end
  end

  # New function to end workout
  def end_workout(username) do
    with {:ok, workout} <- get_active_workout(username),
         {:ok, completed_workout} <- finalize_workout(workout),
         {:ok, _} <- save_item(username, completed_workout),
         :ok <- clear_active_workout(username) do
      {:ok, completed_workout}
    end
  end

  # Template management functions
  def save_as_template(username, workout_name) do
    with {:ok, workout} <- get(username, workout_name, Date.utc_today() |> Date.to_string()),
         {:ok, template} <- create_template(workout),
         :ok <- save_template(username, template) do
      {:ok, template}
    end
  end

  def get_template(username, template_name) do
    with {:ok, profile} <- get_profile(username),
         {:ok, template} <- find_template(profile, template_name) do
      {:ok, template}
    end
  end

  def get_templates(username) do
    case get_profile(username) do
      {:ok, profile} -> {:ok, profile["workout_templates"] || []}
      error -> error
    end
  end

  def update(username, workout_name, date, attrs) do
    with {:ok, workout_params} <- extract_workout_params(attrs),
         {:ok, exercises} <- parse_exercises(workout_params),
         {:ok, updated_workout} <- build_workout(workout_params, exercises),
         {:ok, profile} <- get_profile(username) do
      update_existing_or_create(username, profile, workout_name, date, updated_workout, attrs)
    end
  end

  def update_set_rpe(username, rpe) when is_number(rpe) and rpe >= 1 and rpe <= 10 do
    with {:ok, workout} <- get_active_workout(username),
         {:ok, updated_workout} <- record_rpe(workout, rpe),
         :ok <- save_active_workout(username, updated_workout) do
      {:ok, updated_workout}
    end
  end

  defp record_rpe(workout, rpe) do
    current_exercise = Enum.at(workout.exercises, workout.current_exercise)
    current_set_index = workout.current_set

    # Update the current set with the RPE
    updated_sets =
      List.update_at(current_exercise.sets, current_set_index, fn set ->
        %{set | rpe: rpe}
      end)

    # Update the exercise with modified sets
    updated_exercise = %{current_exercise | sets: updated_sets}

    updated_exercises =
      List.replace_at(workout.exercises, workout.current_exercise, updated_exercise)

    # Recalculate average RPE
    new_average_rpe = calculate_average_rpe(updated_exercises)

    {:ok, %{workout | exercises: updated_exercises, average_rpe: new_average_rpe}}
  end

  defp calculate_average_rpe(exercises) do
    completed_sets =
      exercises
      |> Enum.flat_map(& &1.sets)
      |> Enum.filter(&(&1.completed_at and not is_nil(&1.rpe)))

    case completed_sets do
      [] ->
        0

      sets ->
        total_rpe = Enum.reduce(sets, 0, fn set, acc -> acc + set.rpe end)
        total_rpe / length(sets)
    end
  end

  # Private functions specific to Workout
  defp extract_workout_params(attrs) do
    case Map.fetch(attrs, "workout") do
      {:ok, params} -> {:ok, params}
      :error -> {:error, "Missing workout parameters"}
    end
  end

  defp parse_exercises(workout_params) do
    with true <- is_list(workout_params["exercises"]) || {:error, "exercises must be a list"},
         exercises <- Enum.map(workout_params["exercises"], &parse_exercise/1),
         false <- Enum.any?(exercises, &match?({:error, _}, &1)) do
      {:ok, exercises}
    else
      {:error, message} -> {:error, message}
      true -> {:error, "Invalid exercise format"}
    end
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

  defp initialize_active_workout(workout) do
    {:ok,
     %{
       workout
       | status: "in_progress",
         start_time: DateTime.utc_now(),
         current_exercise: 0,
         current_set: 0,
         total_volume: 0,
         average_rpe: 0
     }}
  end

  defp record_set(workout, reps, weight, rpe) do
    current_exercise = Enum.at(workout.exercises, workout.current_exercise)
    new_volume = workout.total_volume + reps * weight
    new_rpe_count = count_completed_sets(workout) + 1
    new_average_rpe = (workout.average_rpe * (new_rpe_count - 1) + rpe) / new_rpe_count

    # Update the current set
    updated_set = %Set{
      reps: reps,
      weight: weight,
      rpe: rpe,
      completed_at: DateTime.utc_now()
    }

    # Update the exercise sets
    updated_sets = List.replace_at(current_exercise.sets, workout.current_set, updated_set)
    updated_exercise = %{current_exercise | sets: updated_sets}

    updated_exercises =
      List.replace_at(workout.exercises, workout.current_exercise, updated_exercise)

    # Move to next set or exercise
    {next_exercise, next_set} = get_next_set_indices(workout)

    {:ok,
     %{
       workout
       | exercises: updated_exercises,
         current_exercise: next_exercise,
         current_set: next_set,
         total_volume: new_volume,
         average_rpe: new_average_rpe,
         rest_timer_end: DateTime.utc_now() |> DateTime.add(workout.rest_time || 90, :second)
     }}
  end

  defp get_next_set_indices(workout) do
    current_exercise = Enum.at(workout.exercises, workout.current_exercise)

    if workout.current_set + 1 < length(current_exercise.sets) do
      {workout.current_exercise, workout.current_set + 1}
    else
      if workout.current_exercise + 1 < length(workout.exercises) do
        {workout.current_exercise + 1, 0}
      else
        # Workout complete
        {workout.current_exercise, workout.current_set}
      end
    end
  end

  defp count_completed_sets(workout) do
    workout.exercises
    |> Enum.flat_map(& &1.sets)
    |> Enum.count(& &1.completed_at)
  end

  defp finalize_workout(workout) do
    {:ok, %{workout | status: "completed", end_time: DateTime.utc_now()}}
  end

  defp save_active_workout(username, workout) do
    Mongo.update_one(:mongo, "profiles", %{username: username}, %{
      "$set": %{active_workout: to_json(workout)}
    })
  end

  defp clear_active_workout(username) do
    Mongo.update_one(:mongo, "profiles", %{username: username}, %{
      "$set": %{active_workout: nil}
    })
  end

  defp create_template(workout) do
    {:ok,
     %{
       workout
       | template_name: workout.workout_name,
         status: "template",
         start_time: nil,
         end_time: nil,
         current_exercise: nil,
         current_set: nil
     }}
  end

  defp save_template(username, template) do
    Mongo.update_one(:mongo, "profiles", %{username: username}, %{
      "$push": %{workout_templates: to_json(template)}
    })
  end

  defp find_template(profile, template_name) do
    case Enum.find(profile["workout_templates"] || [], &(&1["template_name"] == template_name)) do
      nil -> {:error, :template_not_found}
      template -> {:ok, from_json(template)}
    end
  end

  # Enhanced validation for the new fields
  defp build_workout(params, exercises) do
    with true <- is_binary(params["workout_name"]) || {:error, "workout_name is required"},
         true <-
           is_number(params["length_of_workout"]) ||
             {:error, "length_of_workout must be a number"},
         true <- is_binary(params["date_worked_out"]) || {:error, "date_worked_out is required"},
         true <- validate_optional_fields(params) do
      new(%{
        workout_name: params["workout_name"],
        exercises: exercises,
        length_of_workout: params["length_of_workout"],
        date_worked_out: params["date_worked_out"],
        status: params["status"] || "planned",
        target_volume: params["target_volume"],
        target_rpe: params["target_rpe"],
        notes: params["notes"]
      })
    end
  end

  defp validate_optional_fields(params) do
    valid_target_volume = params["target_volume"] == nil || is_number(params["target_volume"])
    valid_target_rpe = params["target_rpe"] == nil || is_number(params["target_rpe"])

    cond do
      !valid_target_volume -> {:error, "target_volume must be a number"}
      !valid_target_rpe -> {:error, "target_rpe must be a number"}
      true -> true
    end
  end

  defp validate_unique_workout(username, workout_params) do
    case get_profile(username) do
      {:ok, profile} ->
        case Enum.find(profile["workout_log"] || [], &matching_workout?(&1, workout_params)) do
          nil -> :ok
          _ -> {:error, :workout_exists}
        end

      error ->
        error
    end
  end

  defp matching_workout?(workout, workout_params) do
    matches_criteria?(workout, workout_params["workout_name"], workout_params["date_worked_out"])
  end

  defp update_existing_or_create(username, profile, workout_name, date, updated_workout, attrs) do
    if profile["workout_log"] |> find_item(workout_name, date) |> is_map() do
      update_workout(username, workout_name, date, to_json(updated_workout))
    else
      create(username, attrs)
    end
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

  # Add these functions to your Workout module:

  # Stats & History
  def get_workout_stats(username) do
    case get_active_workout(username) do
      {:ok, workout} ->
        {:ok,
         %{
           total_volume: workout.total_volume,
           target_volume: workout.target_volume,
           sets_completed: count_completed_sets(workout),
           total_sets: count_total_sets(workout),
           average_rpe: workout.average_rpe,
           current_exercise: workout.current_exercise,
           current_set: workout.current_set
         }}

      error ->
        error
    end
  end

  def get_history(username) do
    with {:ok, workouts} <- get_all(username) do
      history =
        workouts
        |> Enum.filter(&(&1.status == "completed"))
        |> Enum.map(fn workout ->
          %{
            name: workout.workout_name,
            date: workout.date_worked_out,
            duration: calculate_duration(workout),
            volume: workout.total_volume,
            exercises: summarize_exercises(workout.exercises)
          }
        end)

      {:ok, history}
    end
  end

  def update_workout_notes(username, notes) do
    with {:ok, workout} <- get_active_workout(username),
         {:ok, updated_workout} <- update_notes(workout, notes),
         :ok <- save_active_workout(username, updated_workout) do
      {:ok, updated_workout}
    end
  end

  def skip_exercise(username) do
    with {:ok, workout} <- get_active_workout(username),
         {:ok, updated_workout} <- advance_to_next_exercise(workout),
         :ok <- save_active_workout(username, updated_workout) do
      {:ok, updated_workout}
    end
  end

  def update_rest_timer(username, rest_time) do
    with {:ok, workout} <- get_active_workout(username),
         {:ok, updated_workout} <- set_rest_timer(workout, rest_time),
         :ok <- save_active_workout(username, updated_workout) do
      {:ok, updated_workout}
    end
  end

  def update_exercise_targets(username, targets) do
    with {:ok, workout} <- get_active_workout(username),
         {:ok, updated_workout} <- update_targets(workout, targets),
         :ok <- save_active_workout(username, updated_workout) do
      {:ok, updated_workout}
    end
  end

  # Add these private helper functions:

  defp count_total_sets(workout) do
    Enum.reduce(workout.exercises, 0, fn exercise, acc ->
      acc + length(exercise.sets)
    end)
  end

  defp calculate_duration(%{start_time: start_time, end_time: end_time})
       when not is_nil(start_time) and not is_nil(end_time) do
    DateTime.diff(end_time, start_time, :second)
  end

  defp calculate_duration(_), do: nil

  defp summarize_exercises(exercises) do
    Enum.map(exercises, fn exercise ->
      %{
        name: exercise.exercise_name,
        sets_completed: Enum.count(exercise.sets, & &1.completed_at),
        total_sets: length(exercise.sets),
        best_set: get_best_set(exercise.sets)
      }
    end)
  end

  defp get_best_set(sets) do
    sets
    |> Enum.filter(& &1.completed_at)
    |> Enum.max_by(fn set -> set.weight * set.reps end, fn -> nil end)
  end

  defp update_notes(workout, notes) do
    {:ok, %{workout | notes: notes}}
  end

  defp advance_to_next_exercise(workout) do
    if workout.current_exercise + 1 < length(workout.exercises) do
      {:ok, %{workout | current_exercise: workout.current_exercise + 1, current_set: 0}}
    else
      {:error, "No more exercises"}
    end
  end

  defp set_rest_timer(workout, rest_time) when is_number(rest_time) and rest_time > 0 do
    {:ok, %{workout | rest_timer_end: DateTime.utc_now() |> DateTime.add(rest_time, :second)}}
  end

  defp set_rest_timer(_, _), do: {:error, "Invalid rest time"}

  defp update_targets(workout, %{target_weight: weight, target_reps: reps})
       when is_number(weight) and is_number(reps) do
    current_exercise = Enum.at(workout.exercises, workout.current_exercise)
    updated_exercise = %{current_exercise | target_weight: weight, target_reps: reps}

    updated_exercises =
      List.replace_at(workout.exercises, workout.current_exercise, updated_exercise)

    {:ok, %{workout | exercises: updated_exercises}}
  end

  defp update_targets(_, _), do: {:error, "Invalid targets"}
end
