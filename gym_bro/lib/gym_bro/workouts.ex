defmodule GymBro.Workouts do
  @moduledoc """
  The Workouts context: workout CRUD, the active-workout lifecycle, templates,
  and history/summary queries.
  """

  import Ecto.Query, warn: false

  alias Ecto.Multi
  alias GymBro.Accounts
  alias GymBro.Accounts.User
  alias GymBro.Repo
  alias GymBro.{Exercise, Set, Workout, WorkoutLog}
  alias GymBro.Workouts.WorkoutTemplate

  @default_rest_seconds 90

  ## Workouts CRUD

  def list_workouts(%User{} = user) do
    Workout
    |> join(:inner, [w], l in WorkoutLog, on: w.workout_log_id == l.id)
    |> where([_, l], l.user_id == ^user.id)
    |> order_by([w], desc: w.date_worked_out, desc: w.inserted_at)
    |> preload(exercises: :sets)
    |> Repo.all()
  end

  def get_workout(%User{} = user, workout_name, %Date{} = date) do
    Workout
    |> join(:inner, [w], l in WorkoutLog, on: w.workout_log_id == l.id)
    |> where([w, l], l.user_id == ^user.id and w.workout_name == ^workout_name and w.date_worked_out == ^date)
    |> preload(exercises: :sets)
    |> Repo.one()
    |> case do
      nil -> {:error, :not_found}
      workout -> {:ok, workout}
    end
  end

  def delete_workout(%User{} = user, workout_name, %Date{} = date) do
    with {:ok, workout} <- get_workout(user, workout_name, date) do
      Repo.delete(workout)
    end
  end

  ## Active workout lifecycle

  def get_active(%User{} = user) do
    Workout
    |> join(:inner, [w], l in WorkoutLog, on: w.workout_log_id == l.id)
    |> where([w, l], l.user_id == ^user.id and w.status == "in_progress")
    |> preload(exercises: :sets)
    |> Repo.one()
    |> case do
      nil -> {:error, :no_active_workout}
      workout -> {:ok, workout}
    end
  end

  @doc """
  Starts a workout from a template. Fails if the user already has an active
  workout (enforced by the partial unique index).
  """
  def start_workout(%User{} = user, template_name) do
    with {:ok, template} <- get_template(user, template_name),
         {:ok, log} <- Accounts.ensure_workout_log(user) do
      now = DateTime.utc_now() |> DateTime.truncate(:second)
      today = Date.utc_today()

      Multi.new()
      |> Multi.insert(:workout, fn _ ->
        Workout.changeset(%Workout{}, %{
          workout_name: template.name,
          date_worked_out: today,
          status: "in_progress",
          start_time: now,
          current_exercise: 0,
          current_set: 0,
          total_volume: 0.0,
          average_rpe: 0.0,
          template_name: template.name,
          workout_log_id: log.id
        })
      end)
      |> Multi.run(:exercises, fn repo, %{workout: workout} ->
        items = template_exercise_items(template)

        results =
          Enum.map(items, fn item ->
            target_sets = item["target_sets"] || 3
            target_reps = item["target_reps"]
            target_weight = item["target_weight"]

            exercise =
              repo.insert!(
                Exercise.changeset(%Exercise{}, %{
                  exercise_name: item["exercise_name"],
                  target_reps: target_reps,
                  target_weight: target_weight,
                  rest_time: item["rest_time"],
                  rpe_target: item["rpe_target"],
                  previous_weight: item["previous_weight"],
                  workout_id: workout.id
                })
              )

            for _ <- 1..target_sets do
              repo.insert!(
                Set.changeset(%Set{}, %{
                  reps: 0,
                  weight: 0.0,
                  exercise_id: exercise.id
                })
              )
            end

            exercise
          end)

        {:ok, results}
      end)
      |> Repo.transaction()
      |> case do
        {:ok, _changes} -> get_active(user)
        {:error, _step, changeset, _} -> {:error, changeset}
      end
    end
  end

  @doc """
  Records the next pending set on the user's active workout. Updates indices,
  volume, average RPE, and rest_timer_end.
  """
  def complete_set(%User{} = user, params) do
    with {:ok, workout} <- get_active(user),
         {:ok, reps, weight, rpe} <- extract_set_params(params),
         {:ok, exercise} <- current_exercise(workout),
         {:ok, set} <- current_set_record(exercise, workout.current_set) do
      now = DateTime.utc_now() |> DateTime.truncate(:second)

      Multi.new()
      |> Multi.update(:set,
        Set.changeset(set, %{
          reps: reps,
          weight: weight,
          rpe: rpe,
          completed_at: now
        })
      )
      |> Multi.update(:workout, fn _ ->
        {next_ex, next_set} = next_indices(workout)
        new_volume = (workout.total_volume || 0.0) + reps * weight

        Workout.changeset(workout, %{
          current_exercise: next_ex,
          current_set: next_set,
          total_volume: new_volume,
          rest_timer_end:
            DateTime.add(now, exercise.rest_time || @default_rest_seconds, :second)
        })
      end)
      |> Repo.transaction()
      |> case do
        {:ok, _} -> recompute_and_return(user)
        {:error, _step, changeset, _} -> {:error, changeset}
      end
    end
  end

  def update_set_rpe(%User{} = user, rpe) when is_number(rpe) and rpe >= 1 and rpe <= 10 do
    with {:ok, workout} <- get_active(user),
         {:ok, exercise} <- current_exercise(workout),
         {:ok, set} <- current_set_record(exercise, workout.current_set) do
      set
      |> Set.changeset(%{rpe: rpe})
      |> Repo.update()
      |> case do
        {:ok, _} -> recompute_and_return(user)
        error -> error
      end
    end
  end

  def update_set_rpe(_user, _), do: {:error, :invalid_rpe}

  def skip_exercise(%User{} = user) do
    with {:ok, workout} <- get_active(user) do
      workout
      |> Workout.changeset(%{
        current_exercise: (workout.current_exercise || 0) + 1,
        current_set: 0
      })
      |> Repo.update()
    end
  end

  def update_rest_timer(%User{} = user, seconds)
      when is_number(seconds) and seconds > 0 do
    with {:ok, workout} <- get_active(user) do
      ends_at =
        DateTime.utc_now()
        |> DateTime.truncate(:second)
        |> DateTime.add(seconds, :second)

      workout
      |> Workout.changeset(%{rest_timer_end: ends_at})
      |> Repo.update()
    end
  end

  def update_rest_timer(_user, _), do: {:error, :invalid_rest_time}

  def update_workout_notes(%User{} = user, notes) when is_binary(notes) do
    with {:ok, workout} <- get_active(user) do
      workout
      |> Workout.changeset(%{notes: notes})
      |> Repo.update()
    end
  end

  def update_exercise_targets(%User{} = user, %{"target_weight" => w, "target_reps" => r}) do
    with {:ok, workout} <- get_active(user),
         {:ok, exercise} <- current_exercise(workout) do
      exercise
      |> Exercise.changeset(%{target_weight: w, target_reps: r})
      |> Repo.update()
    end
  end

  def update_exercise_targets(_user, _), do: {:error, :invalid_targets}

  @doc """
  Marks the active workout as completed, sets end_time, and updates the source
  template's per-exercise target_weight/previous_weight with the max weight
  lifted in each completed set group.
  """
  def end_workout(%User{} = user) do
    with {:ok, workout} <- get_active(user) do
      now = DateTime.utc_now() |> DateTime.truncate(:second)

      Multi.new()
      |> Multi.update(:workout,
        Workout.changeset(workout, %{status: "completed", end_time: now})
      )
      |> Multi.run(:template_update, fn _repo, _changes ->
        update_template_from_workout(user, workout)
      end)
      |> Repo.transaction()
      |> case do
        {:ok, %{workout: w}} -> {:ok, Repo.preload(w, exercises: :sets)}
        {:error, _, changeset, _} -> {:error, changeset}
      end
    end
  end

  ## Templates

  def list_templates(%User{} = user) do
    WorkoutTemplate
    |> where(user_id: ^user.id)
    |> order_by([t], asc: t.name)
    |> Repo.all()
  end

  def get_template(%User{} = user, name) do
    case Repo.get_by(WorkoutTemplate, user_id: user.id, name: name) do
      nil -> {:error, :template_not_found}
      t -> {:ok, t}
    end
  end

  def create_template(%User{} = user, attrs) do
    %WorkoutTemplate{}
    |> WorkoutTemplate.changeset(Map.put(stringify(attrs), "user_id", user.id))
    |> Repo.insert()
  end

  def update_template(%WorkoutTemplate{} = template, attrs) do
    template
    |> WorkoutTemplate.changeset(stringify(attrs))
    |> Repo.update()
  end

  def delete_template(%WorkoutTemplate{} = template), do: Repo.delete(template)

  @doc """
  Saves the user's active or most-recent workout as a new template. Captures
  exercise targets only (not actual sets performed).
  """
  def save_workout_as_template(%User{} = user, workout_name) do
    with {:ok, workout} <- find_workout_by_name(user, workout_name) do
      items =
        workout.exercises
        |> Enum.map(fn ex ->
          %{
            "exercise_name" => ex.exercise_name,
            "target_reps" => ex.target_reps,
            "target_weight" => ex.target_weight,
            "target_sets" => length(ex.sets),
            "rest_time" => ex.rest_time,
            "rpe_target" => ex.rpe_target,
            "previous_weight" => ex.previous_weight
          }
        end)

      create_template(user, %{name: workout_name, exercises: %{"items" => items}})
    end
  end

  ## History & summaries

  def get_history(%User{} = user) do
    workouts =
      Workout
      |> join(:inner, [w], l in WorkoutLog, on: w.workout_log_id == l.id)
      |> where([w, l], l.user_id == ^user.id and w.status == "completed")
      |> order_by([w], desc: w.date_worked_out)
      |> preload(exercises: :sets)
      |> Repo.all()

    Enum.map(workouts, fn w ->
      %{
        name: w.workout_name,
        date: w.date_worked_out,
        duration: Workout.length_seconds(w),
        volume: total_volume(w),
        exercises: summarize_exercises(w.exercises)
      }
    end)
  end

  def get_summary(%User{} = user, workout_name, %Date{} = date) do
    with {:ok, workout} <- get_workout(user, workout_name, date) do
      summary = %{
        workout_name: workout.workout_name,
        date: workout.date_worked_out,
        duration: Workout.length_seconds(workout),
        total_volume: total_volume(workout),
        average_rpe: workout.average_rpe,
        start_time: workout.start_time,
        end_time: workout.end_time,
        exercises_summary:
          Enum.map(workout.exercises, fn ex ->
            completed = Enum.filter(ex.sets, & &1.completed_at)

            %{
              name: ex.exercise_name,
              sets_completed: length(completed),
              total_sets: length(ex.sets),
              volume: exercise_volume(ex),
              set_details:
                Enum.map(completed, fn s ->
                  %{
                    reps: s.reps,
                    weight: s.weight,
                    rpe: s.rpe,
                    completed_at: s.completed_at
                  }
                end),
              notes: ex.notes
            }
          end)
      }

      {:ok, summary}
    end
  end

  def get_stats(%User{} = user) do
    with {:ok, workout} <- get_active(user) do
      all_sets = Enum.flat_map(workout.exercises, & &1.sets)
      completed = Enum.filter(all_sets, & &1.completed_at)

      {:ok,
       %{
         total_volume: total_volume(workout),
         sets_completed: length(completed),
         total_sets: length(all_sets),
         average_rpe: workout.average_rpe || 0,
         current_exercise: workout.current_exercise || 0,
         current_set: workout.current_set || 0
       }}
    end
  end

  ## Private helpers

  defp template_exercise_items(%WorkoutTemplate{exercises: %{"items" => items}}) when is_list(items),
    do: items

  defp template_exercise_items(_), do: []

  defp extract_set_params(%{"reps" => r, "weight" => w, "rpe" => rpe})
       when is_number(r) and is_number(w) and is_number(rpe),
       do: {:ok, r, w * 1.0, rpe * 1.0}

  defp extract_set_params(_), do: {:error, :missing_set_params}

  defp current_exercise(%Workout{exercises: exercises, current_exercise: idx}) do
    case Enum.at(exercises || [], idx || 0) do
      nil -> {:error, :no_current_exercise}
      ex -> {:ok, ex}
    end
  end

  defp current_set_record(%Exercise{sets: sets}, idx) do
    sets_sorted = Enum.sort_by(sets, & &1.id)

    case Enum.at(sets_sorted, idx || 0) do
      nil -> {:error, :no_current_set}
      set -> {:ok, set}
    end
  end

  defp next_indices(%Workout{exercises: exercises, current_exercise: ex_i, current_set: s_i}) do
    ex_i = ex_i || 0
    s_i = s_i || 0
    current_ex = Enum.at(exercises, ex_i)

    cond do
      current_ex == nil ->
        {ex_i, s_i}

      s_i + 1 < length(current_ex.sets) ->
        {ex_i, s_i + 1}

      ex_i + 1 < length(exercises) ->
        {ex_i + 1, 0}

      true ->
        {ex_i, s_i}
    end
  end

  defp recompute_and_return(user) do
    with {:ok, workout} <- get_active(user) do
      avg = average_rpe(workout)

      workout
      |> Workout.changeset(%{average_rpe: avg})
      |> Repo.update()
    end
  end

  defp average_rpe(%Workout{exercises: exercises}) do
    sets =
      exercises
      |> Enum.flat_map(& &1.sets)
      |> Enum.filter(&(&1.completed_at && is_number(&1.rpe)))

    case sets do
      [] -> 0.0
      _ -> Enum.sum(Enum.map(sets, & &1.rpe)) / length(sets)
    end
  end

  defp total_volume(%Workout{exercises: exercises}) do
    Enum.reduce(exercises, 0.0, fn ex, acc -> acc + exercise_volume(ex) end)
  end

  defp exercise_volume(%Exercise{sets: sets}) do
    sets
    |> Enum.filter(& &1.completed_at)
    |> Enum.reduce(0.0, fn s, acc ->
      acc + (s.reps || 0) * (s.weight || 0.0)
    end)
  end

  defp summarize_exercises(exercises) do
    Enum.map(exercises, fn ex ->
      completed = Enum.filter(ex.sets, & &1.completed_at)

      best =
        completed
        |> Enum.max_by(fn s -> (s.weight || 0.0) * (s.reps || 0) end, fn -> nil end)

      %{
        name: ex.exercise_name,
        sets_completed: length(completed),
        total_sets: length(ex.sets),
        best_set: best && %{reps: best.reps, weight: best.weight, rpe: best.rpe},
        volume: exercise_volume(ex)
      }
    end)
  end

  defp update_template_from_workout(%User{} = user, %Workout{template_name: name} = workout)
       when is_binary(name) do
    case get_template(user, name) do
      {:ok, template} ->
        items = template_exercise_items(template)
        completed_exercises = Repo.preload(workout, exercises: :sets).exercises

        updated_items =
          items
          |> Enum.zip(completed_exercises)
          |> Enum.map(fn {item, ex} ->
            case max_weight(ex.sets) do
              nil -> item
              max -> Map.merge(item, %{"target_weight" => max, "previous_weight" => max})
            end
          end)

        update_template(template, %{exercises: %{"items" => updated_items}})

      {:error, :template_not_found} ->
        {:ok, :no_template}
    end
  end

  defp update_template_from_workout(_user, _workout), do: {:ok, :no_template}

  defp max_weight(sets) do
    sets
    |> Enum.filter(& &1.completed_at)
    |> Enum.map(& &1.weight)
    |> case do
      [] -> nil
      weights -> Enum.max(weights)
    end
  end

  defp find_workout_by_name(%User{} = user, name) do
    Workout
    |> join(:inner, [w], l in WorkoutLog, on: w.workout_log_id == l.id)
    |> where([w, l], l.user_id == ^user.id and w.workout_name == ^name)
    |> order_by([w], desc: w.inserted_at)
    |> limit(1)
    |> preload(exercises: :sets)
    |> Repo.one()
    |> case do
      nil -> {:error, :not_found}
      w -> {:ok, w}
    end
  end

  defp stringify(map) when is_map(map) do
    Map.new(map, fn {k, v} -> {to_string(k), v} end)
  end
end
