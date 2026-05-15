defmodule GymBroWeb.Api.WorkoutController do
  use GymBroWeb, :controller

  alias GymBro.Workouts
  alias GymBro.Workout
  alias GymBroWeb.Api.Helpers

  action_fallback GymBroWeb.Api.FallbackController

  ## Workouts

  def index(conn, _params) do
    json(conn, %{workouts: Enum.map(Workouts.list_workouts(conn.assigns.current_user), &render_workout/1)})
  end

  def show(conn, %{"workout_name" => name, "date" => date_str}) do
    with {:ok, date} <- Helpers.parse_date(date_str),
         {:ok, workout} <- Workouts.get_workout(conn.assigns.current_user, name, date) do
      json(conn, %{workout: render_workout(workout)})
    end
  end

  def delete(conn, %{"workout_name" => name, "date" => date_str}) do
    with {:ok, date} <- Helpers.parse_date(date_str),
         {:ok, _} <- Workouts.delete_workout(conn.assigns.current_user, name, date) do
      send_resp(conn, :no_content, "")
    end
  end

  ## Active workout lifecycle

  def active(conn, _params) do
    with {:ok, workout} <- Workouts.get_active(conn.assigns.current_user) do
      json(conn, %{workout: render_workout(workout)})
    end
  end

  def start(conn, params) do
    name = params["workout_name"] || params["template_name"]

    with {:ok, workout} <- Workouts.start_workout(conn.assigns.current_user, name) do
      conn
      |> put_status(:created)
      |> json(%{workout: render_workout(workout)})
    end
  end

  def complete_set(conn, params) do
    with {:ok, workout} <- Workouts.complete_set(conn.assigns.current_user, params) do
      json(conn, %{workout: render_workout(workout)})
    end
  end

  def update_set_rpe(conn, %{"rpe" => rpe}) do
    with {:ok, workout} <- Workouts.update_set_rpe(conn.assigns.current_user, rpe) do
      json(conn, %{workout: render_workout(workout)})
    end
  end

  def skip_exercise(conn, _params) do
    with {:ok, workout} <- Workouts.skip_exercise(conn.assigns.current_user) do
      json(conn, %{workout: render_workout(workout)})
    end
  end

  def update_rest_timer(conn, %{"rest_time" => seconds}) do
    with {:ok, workout} <- Workouts.update_rest_timer(conn.assigns.current_user, seconds) do
      json(conn, %{workout: render_workout(workout)})
    end
  end

  def update_notes(conn, %{"notes" => notes}) do
    with {:ok, workout} <- Workouts.update_workout_notes(conn.assigns.current_user, notes) do
      json(conn, %{workout: render_workout(workout)})
    end
  end

  def update_exercise_targets(conn, params) do
    with {:ok, _exercise} <- Workouts.update_exercise_targets(conn.assigns.current_user, params),
         {:ok, workout} <- Workouts.get_active(conn.assigns.current_user) do
      json(conn, %{workout: render_workout(workout)})
    end
  end

  def end_active(conn, _params) do
    with {:ok, workout} <- Workouts.end_workout(conn.assigns.current_user) do
      json(conn, %{workout: render_workout(workout)})
    end
  end

  def stats(conn, _params) do
    with {:ok, stats} <- Workouts.get_stats(conn.assigns.current_user) do
      json(conn, %{stats: stats})
    end
  end

  ## History & summary

  def history(conn, _params) do
    json(conn, %{history: Workouts.get_history(conn.assigns.current_user)})
  end

  def summary(conn, %{"workout_name" => name, "date" => date_str}) do
    with {:ok, date} <- Helpers.parse_date(date_str),
         {:ok, summary} <- Workouts.get_summary(conn.assigns.current_user, name, date) do
      json(conn, %{summary: summary})
    end
  end

  ## Templates

  def list_templates(conn, _params) do
    templates = Workouts.list_templates(conn.assigns.current_user)
    json(conn, %{templates: Enum.map(templates, &render_template/1)})
  end

  def create_template(conn, params) do
    attrs = params["template"] || params

    with {:ok, template} <- Workouts.create_template(conn.assigns.current_user, attrs) do
      conn
      |> put_status(:created)
      |> json(%{template: render_template(template)})
    end
  end

  def save_as_template(conn, %{"workout_name" => name}) do
    with {:ok, template} <- Workouts.save_workout_as_template(conn.assigns.current_user, name) do
      conn
      |> put_status(:created)
      |> json(%{template: render_template(template)})
    end
  end

  def update_template(conn, %{"template_name" => name} = params) do
    attrs = params["template"] || params

    with {:ok, template} <- Workouts.get_template(conn.assigns.current_user, name),
         {:ok, updated} <- Workouts.update_template(template, attrs) do
      json(conn, %{template: render_template(updated)})
    end
  end

  def delete_template(conn, %{"template_name" => name}) do
    with {:ok, template} <- Workouts.get_template(conn.assigns.current_user, name),
         {:ok, _} <- Workouts.delete_template(template) do
      send_resp(conn, :no_content, "")
    end
  end

  ## Rendering

  defp render_workout(%Workout{} = w) do
    %{
      id: w.id,
      workout_name: w.workout_name,
      date_worked_out: w.date_worked_out,
      status: w.status,
      start_time: w.start_time,
      end_time: w.end_time,
      length_seconds: Workout.length_seconds(w),
      current_exercise: w.current_exercise,
      current_set: w.current_set,
      rest_timer_end: w.rest_timer_end,
      total_volume: w.total_volume,
      target_volume: w.target_volume,
      average_rpe: w.average_rpe,
      target_rpe: w.target_rpe,
      notes: w.notes,
      template_name: w.template_name,
      exercises: render_exercises(w.exercises)
    }
  end

  defp render_exercises(%Ecto.Association.NotLoaded{}), do: []
  defp render_exercises(exercises) when is_list(exercises) do
    Enum.map(exercises, fn ex ->
      %{
        id: ex.id,
        exercise_name: ex.exercise_name,
        target_reps: ex.target_reps,
        target_weight: ex.target_weight,
        rest_time: ex.rest_time,
        rpe_target: ex.rpe_target,
        previous_weight: ex.previous_weight,
        personal_record: ex.personal_record,
        notes: ex.notes,
        sets: render_sets(ex.sets)
      }
    end)
  end

  defp render_sets(%Ecto.Association.NotLoaded{}), do: []
  defp render_sets(sets) when is_list(sets) do
    sets
    |> Enum.sort_by(& &1.id)
    |> Enum.map(fn s ->
      %{
        id: s.id,
        reps: s.reps,
        weight: s.weight,
        rpe: s.rpe,
        completed_at: s.completed_at,
        notes: s.notes
      }
    end)
  end

  defp render_template(t) do
    %{
      id: t.id,
      name: t.name,
      exercises: t.exercises,
      notes: t.notes,
      inserted_at: t.inserted_at,
      updated_at: t.updated_at
    }
  end
end
