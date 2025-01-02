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
    :status,
    :start_time,
    :end_time,
    :current_exercise,
    :current_set,
    :rest_timer_end,
    :total_volume,
    :target_volume,
    :average_rpe,
    :target_rpe,
    :notes,
    :template_name
  ]

  def new(attrs), do: {:ok, struct(__MODULE__, attrs)}

  # In Workout.ex
  def create(username, attrs) do
    case get_profile(username) do
      {:ok, _} ->
        with {:ok, workout_params} <- extract_workout_params(attrs),
             {:ok, workout} <- build_workout(workout_params),
             :ok <- validate_unique_workout(username, workout_params),
             {:ok, _} <- save_item(username, workout) do
          {:ok, workout}
        end

      {:error, :profile_not_found} ->
        {:error, :profile_not_found}
    end
  end

  defp extract_workout_params(%{"workout" => params}), do: {:ok, params}
  defp extract_workout_params(_), do: {:error, "Missing workout parameters"}

  def to_json(workout) when is_map(workout) do
    # Handle both structs and plain maps
    case workout do
      %__MODULE__{} = w -> do_to_json(w)
      _ -> struct(__MODULE__, workout) |> do_to_json()
    end
  end

  defp do_to_json(workout) do
    %{
      "workout_name" => workout.workout_name || "",
      "exercises" =>
        Enum.map(workout.exercises || [], fn exercise ->
          %{
            "exercise_name" => exercise.exercise_name,
            "sets" =>
              Enum.map(exercise.sets || [], fn set ->
                %{
                  "reps" => set.reps,
                  "weight" => set.weight,
                  "rpe" => set.rpe,
                  "completed_at" => set.completed_at,
                  "notes" => set.notes
                }
              end),
            "target_reps" => exercise.target_reps,
            "target_weight" => exercise.target_weight,
            "rest_time" => exercise.rest_time,
            "rpe_target" => exercise.rpe_target,
            "notes" => exercise.notes,
            "previous_weight" => exercise.previous_weight,
            "personal_record" => exercise.personal_record,
            "completed_sets" => exercise.completed_sets
          }
        end),
      "length_of_workout" => workout.length_of_workout || 0,
      "date_worked_out" => workout.date_worked_out || nil,
      "status" => workout.status || "not_started",
      "start_time" => workout.start_time || nil,
      "end_time" => workout.end_time || nil,
      "current_exercise" => workout.current_exercise || 0,
      "current_set" => workout.current_set || 0,
      "rest_timer_end" => workout.rest_timer_end || nil,
      "total_volume" => workout.total_volume || 0,
      "target_volume" => workout.target_volume || 0,
      "average_rpe" => workout.average_rpe || 0,
      "target_rpe" => workout.target_rpe || 0,
      "notes" => workout.notes || "",
      "template_name" => workout.template_name || ""
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

  def start_workout(username, workout_name) do
    with {:ok, template} <- get_template(username, workout_name),
         {:ok, active_workout} <- initialize_active_workout(template),
         :ok <- save_active_workout(username, active_workout) do
      {:ok, active_workout}
    else
      error ->
        error
    end
  end

  # New function to get active workout
  def get_active_workout(username) do
    case get_profile(username) do
      {:ok, profile} ->
        case Map.get(profile, "active_workout") do
          nil -> {:error, :no_active_workout}
          workout -> {:ok, from_json(workout)}
        end

      error ->
        error
    end
  end

  # New function to complete a set
  def complete_set(username, params) when is_map(params) do
    with {:ok, workout} <- get_active_workout(username),
         {:ok, updated_workout} <- do_complete_set(workout, params),
         :ok <- save_active_workout(username, updated_workout) do
      {:ok, updated_workout}
    end
  end

  defp do_complete_set(workout, params) do
    reps = Map.get(params, "reps")
    weight = Map.get(params, "weight")
    rpe = Map.get(params, "rpe")

    if is_nil(reps) or is_nil(weight) or is_nil(rpe) do
      {:error, "Missing required parameters"}
    else
      record_set(workout, reps, weight, rpe)
    end
  end

  # New function to end workout

  def end_workout(username) do
    with {:ok, workout} <- get_active_workout(username),
         completed_workout = %{
           workout
           | status: "completed",
             end_time: DateTime.utc_now() |> DateTime.to_iso8601()
         },
         {:ok, _} <- save_item(username, completed_workout),
         :ok <- update_template_weights(username, completed_workout),
         :ok <- clear_active_workout(username) do
      {:ok, completed_workout}
    else
      error -> error
    end
  end

  defp update_template_weights(username, workout) do
    case get_template(username, workout.workout_name) do
      {:ok, template} ->
        updated_exercises = update_exercises_with_weights(template.exercises, workout.exercises)
        updated_template = %{template | exercises: updated_exercises}

        Mongo.update_one(
          :mongo,
          "profiles",
          %{
            username: username,
            workout_templates: %{
              "$elemMatch": %{
                template_name: workout.workout_name
              }
            }
          },
          %{
            "$set": %{
              "workout_templates.$": to_json(updated_template)
            }
          }
        )

      error ->
        error
    end
  end

  defp update_exercises_with_weights(template_exercises, completed_exercises) do
    Enum.zip(template_exercises, completed_exercises)
    |> Enum.map(fn {template_ex, completed_ex} ->
      max_weight = get_max_weight_from_sets(completed_ex.sets)
      %{template_ex | target_weight: max_weight, previous_weight: max_weight}
    end)
  end

  defp get_max_weight_from_sets(sets) do
    sets
    |> Enum.filter(&(&1.completed_at && &1.weight))
    |> Enum.map(& &1.weight)
    |> Enum.max(fn -> nil end)
  end

  # Make sure this is defined in your module
  defp save_item(username, workout) do
    case Mongo.update_one(:mongo, "profiles", %{"username" => username}, %{
           "$push" => %{"workout_log" => to_json(workout)}
         }) do
      {:ok, result} -> {:ok, result}
      error -> error
    end
  end

  # Template management functions
  def save_as_template(username, workout_name) do
    with {:ok, workout} <- get(username, workout_name, Date.utc_today() |> Date.to_string()),
         {:ok, template} <- create_template(workout) do
      # Convert workout to template format
      template_data = %{
        "workout" => %{
          "workout_name" => workout_name,
          "exercises" => workout.exercises,
          "length_of_workout" => workout.length_of_workout,
          "status" => "template"
        }
      }

      case save_template(username, workout_name, template_data) do
        {:ok, _} -> {:ok, template}
        error -> error
      end
    end
  end

  def get_template(username, template_name) do
    case get_profile(username) do
      {:ok, profile} ->
        case Enum.find(
               profile["workout_templates"] || [],
               &(&1["template_name"] == template_name)
             ) do
          nil -> {:error, :template_not_found}
          template -> {:ok, from_json(template)}
        end

      error ->
        error
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
         {:ok, updated_workout} <- build_workout(workout_params),
         {:ok, profile} <- get_profile(username) do
      update_existing_or_create(username, profile, workout_name, date, updated_workout, attrs)
    end
  end

  def update_set_rpe(username, %{"rpe" => rpe}) when is_number(rpe) and rpe >= 1 and rpe <= 10 do
    with {:ok, workout} <- get_active_workout(username),
         {:ok, updated_workout} <- record_rpe(workout, rpe),
         :ok <- save_active_workout(username, updated_workout) do
      {:ok, updated_workout}
    end
  end

  defp to_mongo_map(workout) do
    workout
    |> Map.from_struct()
    |> Map.put("exercises", Enum.map(workout.exercises || [], &Exercise.to_json/1))
    |> Enum.filter(fn {_, v} -> not is_nil(v) end)
    |> Map.new()
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
      |> Enum.filter(&(not is_nil(&1.completed_at) and not is_nil(&1.rpe)))

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

  defp parse_exercises(workout) do
    (workout["exercises"] || workout.exercises || [])
    |> Enum.map(fn exercise ->
      case exercise do
        %Exercise{} -> exercise
        _ -> Exercise.from_json(exercise)
      end
    end)
  end

  defp parse_exercise(exercise_params) do
    case exercise_params do
      %{"sets" => sets} when is_list(sets) ->
        case exercise_params["exercise_name"] do
          name when is_binary(name) and name != "" ->
            sets = Enum.map(sets, &Set.new/1)
            Exercise.new(%{"sets" => sets, "exercise_name" => name})

          _ ->
            {:error, "exercise_name is required"}
        end

      _ ->
        {:error, "sets must be a list"}
    end
  end

  defp parse_exercises_for_create(exercises) do
    Enum.map(exercises, fn exercise ->
      %Exercise{
        exercise_name: exercise["exercise_name"],
        sets: parse_sets(exercise["sets"] || []),
        target_reps: exercise["target_reps"],
        target_weight: exercise["target_weight"],
        rest_time: exercise["rest_time"],
        rpe_target: exercise["rpe_target"],
        notes: exercise["notes"]
      }
    end)
  end

  defp parse_sets(sets) do
    Enum.map(sets, fn set ->
      %Set{
        reps: set["reps"],
        weight: set["weight"],
        rpe: set["rpe"],
        completed_at: set["completed_at"],
        notes: set["notes"]
      }
    end)
  end

  defp initialize_active_workout(template) do
    {:ok,
     %__MODULE__{
       workout_name: template.workout_name,
       exercises: template.exercises,
       length_of_workout: template.length_of_workout,
       date_worked_out: Date.utc_today() |> Date.to_string(),
       status: "in_progress",
       start_time: DateTime.utc_now() |> DateTime.to_iso8601(),
       current_exercise: 0,
       current_set: 0,
       total_volume: 0,
       average_rpe: 0
     }}
  end

  def record_set(workout, reps, weight, rpe) do
    current_exercise = Enum.at(workout.exercises || [], workout.current_exercise)

    if is_nil(current_exercise) do
      {:error, "Exercise not found"}
    else
      new_volume = (workout.total_volume || 0) + reps * weight

      updated_set = %Set{
        reps: reps,
        weight: weight,
        rpe: rpe,
        completed_at: DateTime.utc_now() |> DateTime.to_iso8601()
      }

      updated_sets =
        List.replace_at(current_exercise.sets || [], workout.current_set, updated_set)

      updated_exercise = %{current_exercise | sets: updated_sets}

      updated_exercises =
        List.replace_at(workout.exercises, workout.current_exercise, updated_exercise)

      {next_exercise, next_set} = get_next_set_indices(workout)

      {:ok,
       %{
         workout
         | exercises: updated_exercises,
           current_exercise: next_exercise,
           current_set: next_set,
           total_volume: new_volume,
           average_rpe: calculate_average_rpe(updated_exercises),
           rest_timer_end:
             DateTime.utc_now() |> DateTime.add(90, :second) |> DateTime.to_iso8601()
       }}
    end
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

  defp count_total_sets(workout) do
    workout.exercises
    |> Enum.reduce(0, fn exercise, acc ->
      acc + length(exercise.sets)
    end)
  end

  defp finalize_workout(workout) do
    {:ok, %{workout | status: "completed", end_time: DateTime.utc_now() |> DateTime.to_iso8601()}}
  end

  def save_active_workout(username, workout) do
    case Mongo.update_one(:mongo, "profiles", %{username: username}, %{
           "$set": %{active_workout: to_json(workout)}
         }) do
      {:ok, result} ->
        :ok

      error ->
        {:error, "Failed to save workout"}
    end
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

  def save_template(username, template_name, data) do
    exercises =
      for exercise <- data["workout"]["exercises"] || [] do
        %{
          "exercise_name" => exercise.exercise_name,
          "sets" => Enum.map(exercise.sets || [], &Set.to_json/1),
          "target_reps" => exercise.target_reps,
          "target_weight" => exercise.target_weight,
          "rest_time" => exercise.rest_time,
          "rpe_target" => exercise.rpe_target,
          "notes" => exercise.notes
        }
      end

    template = %{
      "template_name" => template_name,
      "workout_name" => template_name,
      "exercises" => exercises,
      "length_of_workout" => data["workout"]["length_of_workout"],
      "status" => "template"
    }

    case Mongo.update_one(:mongo, "profiles", %{username: username}, %{
           "$push" => %{
             workout_templates: template
           }
         }) do
      {:ok, _} -> {:ok, template}
      error -> error
    end
  end

  defp parse_template_exercises(exercises) do
    Enum.map(exercises, fn exercise ->
      %{
        "exercise_name" => exercise["exercise_name"],
        "sets" => exercise["sets"] || [],
        "target_reps" => exercise["target_reps"],
        "target_weight" => exercise["target_weight"],
        "rest_time" => exercise["rest_time"],
        "rpe_target" => exercise["rpe_target"],
        "notes" => exercise["notes"]
      }
    end)
  end

  defp find_template(profile, template_name) do
    case Enum.find(profile["workout_templates"] || [], &(&1["template_name"] == template_name)) do
      nil -> {:error, :template_not_found}
      template -> {:ok, from_json(template)}
    end
  end

  # Enhanced validation for the new fields
  def build_workout(params) do
    exercises = parse_exercises_for_create(params["exercises"] || [])

    {:ok,
     %__MODULE__{
       workout_name: params["workout_name"],
       exercises: exercises,
       length_of_workout: params["length_of_workout"],
       date_worked_out: params["date_worked_out"],
       status: params["status"] || "planned",
       target_volume: params["target_volume"],
       target_rpe: params["target_rpe"],
       notes: params["notes"]
     }}
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
    workout["workout_name"] == workout_params["workout_name"] &&
      workout["date_worked_out"] == workout_params["date_worked_out"]
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
        stats = %{
          "total_volume" => calculate_total_volume(workout),
          "sets_completed" => count_completed_sets(workout),
          "total_sets" => count_total_sets(workout),
          "average_rpe" => workout.average_rpe || 0,
          "current_exercise" => workout.current_exercise || 0,
          "current_set" => workout.current_set || 0
        }

        {:ok, stats}

      error ->
        error
    end
  end

  # Add test helper to match dates
  def matches_workout_date?(workout, expected_date) do
    workout.date_worked_out == expected_date
  end

  def get_history(username) do
    with {:ok, workouts} <- get_all(username) do
      history =
        workouts
        |> Enum.filter(&(&1.status == "completed"))
        |> Enum.map(fn workout ->
          total_volume = calculate_total_volume(workout)

          %{
            "name" => workout.workout_name,
            "date" => workout.date_worked_out,
            "duration" => calculate_duration(workout),
            "volume" => total_volume,
            "exercises" => summarize_exercises(workout.exercises)
          }
        end)

      {:ok, history}
    end
  end

  defp calculate_total_volume(workout) do
    workout.exercises
    |> Enum.reduce(0, fn exercise, acc ->
      exercise_volume =
        Enum.reduce(exercise.sets, 0, fn set, set_acc ->
          case {set.reps, set.weight} do
            {reps, weight} when is_number(reps) and is_number(weight) ->
              set_acc + reps * weight

            _ ->
              set_acc
          end
        end)

      acc + exercise_volume
    end)
  end

  # In Workout.ex
  def update_workout_notes(username, notes) when is_binary(notes) do
    with {:ok, workout} <- get_active_workout(username),
         updated_workout = %{workout | notes: notes},
         :ok <- save_active_workout(username, updated_workout) do
      {:ok, updated_workout}
    end
  end

  def skip_exercise(username) do
    with {:ok, workout} <- get_active_workout(username),
         updated_workout = %{
           workout
           | current_exercise: workout.current_exercise + 1,
             current_set: 0
         },
         :ok <- save_active_workout(username, updated_workout) do
      {:ok, updated_workout}
    end
  end

  defp has_next_exercise?(workout) do
    workout.current_exercise + 1 < length(workout.exercises)
  end

  defp do_skip_exercise(workout) do
    {:ok, %{workout | current_exercise: workout.current_exercise + 1, current_set: 0}}
  end

  def update_rest_timer(username, rest_time) when is_number(rest_time) and rest_time > 0 do
    case get_active_workout(username) do
      {:ok, workout} ->
        rest_timer_end =
          DateTime.utc_now()
          |> DateTime.add(rest_time, :second)
          |> DateTime.to_iso8601()

        updated_workout = %{workout | rest_timer_end: rest_timer_end}

        case save_active_workout(username, updated_workout) do
          :ok -> {:ok, updated_workout}
          error -> error
        end

      error ->
        error
    end
  end

  def update_rest_timer(_username, _rest_time), do: {:error, "Invalid rest time parameter"}

  def update_exercise_targets(username, targets) do
    with {:ok, workout} <- get_active_workout(username),
         {:ok, updated_workout} <- update_targets(workout, targets),
         :ok <- save_active_workout(username, updated_workout) do
      {:ok, updated_workout}
    end
  end

  def get_workout_summary(username, workout_name, date) do
    with {:ok, profile} <- get_profile(username),
         completed_workout <- find_completed_workout(profile["workout_log"], workout_name, date) do
      if completed_workout do
        workout = from_json(completed_workout)

        summary = %{
          "workout_name" => workout.workout_name,
          "date" => workout.date_worked_out,
          "duration" => calculate_duration(workout),
          "total_volume" => calculate_total_volume(workout),
          "average_rpe" => workout.average_rpe,
          "start_time" => workout.start_time,
          "end_time" => workout.end_time,
          "exercises_summary" =>
            Enum.map(workout.exercises, fn exercise ->
              completed_sets = Enum.count(exercise.sets, & &1.completed_at)
              volume = calculate_exercise_volume(exercise)

              set_details =
                Enum.map(exercise.sets, fn set ->
                  if set.completed_at do
                    %{
                      "reps" => set.reps,
                      "weight" => set.weight,
                      "rpe" => set.rpe,
                      "completed_at" => set.completed_at
                    }
                  end
                end)
                |> Enum.filter(& &1)

              %{
                "name" => exercise.exercise_name,
                "sets_completed" => completed_sets,
                "total_sets" => length(exercise.sets),
                "volume" => volume,
                "set_details" => set_details,
                "notes" => exercise.notes
              }
            end)
        }

        {:ok, summary}
      else
        {:error, :not_found}
      end
    end
  end

  defp find_completed_workout(workout_log, name, date) do
    Enum.find(workout_log || [], fn workout ->
      workout["workout_name"] == name &&
        workout["date_worked_out"] == date &&
        workout["status"] == "completed"
    end)
  end

  # Add these private helper functions:
  defp calculate_duration(%{start_time: start, end_time: finish})
       when not is_nil(start) and not is_nil(finish) do
    case {DateTime.from_iso8601(start), DateTime.from_iso8601(finish)} do
      {{:ok, start_dt}, {:ok, end_dt}} -> DateTime.diff(end_dt, start_dt, :second)
      _ -> 0
    end
  end

  defp calculate_duration(_), do: 0

  defp summarize_exercises(exercises) do
    Enum.map(exercises, fn exercise ->
      volume = calculate_exercise_volume(exercise)

      %{
        name: exercise.exercise_name,
        sets_completed: Enum.count(exercise.sets, & &1.completed_at),
        total_sets: length(exercise.sets),
        best_set: get_best_set(exercise.sets),
        volume: volume
      }
    end)
  end

  defp calculate_exercise_volume(exercise) do
    exercise.sets
    |> Enum.filter(& &1.completed_at)
    |> Enum.reduce(0, fn set, acc -> acc + set.reps * set.weight end)
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

  defp update_targets(workout, %{"target_weight" => weight, "target_reps" => reps}) do
    current_exercise = Enum.at(workout.exercises, workout.current_exercise)

    if is_nil(current_exercise) do
      {:error, "Exercise not found"}
    else
      updated_exercise = %{current_exercise | target_weight: weight, target_reps: reps}

      updated_exercises =
        List.replace_at(workout.exercises, workout.current_exercise, updated_exercise)

      {:ok, %{workout | exercises: updated_exercises}}
    end
  end

  defp update_targets(_, _), do: {:error, "Invalid targets format"}
end
