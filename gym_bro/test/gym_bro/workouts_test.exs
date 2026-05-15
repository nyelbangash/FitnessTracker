defmodule GymBro.WorkoutsTest do
  use GymBro.DataCase, async: true

  alias GymBro.{Accounts, Workouts}
  alias GymBro.Workouts.WorkoutTemplate

  import GymBro.AccountsFixtures

  setup do
    user = user_fixture()
    {:ok, _log} = Accounts.ensure_workout_log(user)
    %{user: user}
  end

  defp simple_template(user, name \\ "Push Day") do
    {:ok, template} =
      Workouts.create_template(user, %{
        name: name,
        exercises: %{
          "items" => [
            %{
              "exercise_name" => "Bench Press",
              "target_reps" => 5,
              "target_weight" => 100.0,
              "target_sets" => 3,
              "rest_time" => 90
            },
            %{
              "exercise_name" => "Overhead Press",
              "target_reps" => 5,
              "target_weight" => 60.0,
              "target_sets" => 2,
              "rest_time" => 90
            }
          ]
        }
      })

    template
  end

  describe "templates" do
    test "create_template/2 inserts a template", %{user: user} do
      assert {:ok, %WorkoutTemplate{name: "Push Day"}} = simple_template(user) |> then(&{:ok, &1})
    end

    test "list_templates/1 returns user's templates sorted by name", %{user: user} do
      _t1 = simple_template(user, "B Day")
      _t2 = simple_template(user, "A Day")
      assert [%{name: "A Day"}, %{name: "B Day"}] = Workouts.list_templates(user)
    end

    test "create_template/2 rejects duplicate names for the same user", %{user: user} do
      _ = simple_template(user)
      assert {:error, changeset} = Workouts.create_template(user, %{name: "Push Day"})
      assert "has already been taken" in errors_on(changeset).user_id
    end
  end

  describe "start_workout/2" do
    test "creates an in-progress workout with exercises and preallocated sets", %{user: user} do
      _ = simple_template(user)

      assert {:ok, workout} = Workouts.start_workout(user, "Push Day")
      assert workout.status == "in_progress"
      assert workout.workout_name == "Push Day"
      assert workout.template_name == "Push Day"
      assert workout.current_exercise == 0
      assert workout.current_set == 0
      assert length(workout.exercises) == 2

      [bench, ohp] = workout.exercises
      assert bench.exercise_name == "Bench Press"
      assert length(bench.sets) == 3
      assert Enum.all?(bench.sets, &is_nil(&1.completed_at))
      assert ohp.exercise_name == "Overhead Press"
      assert length(ohp.sets) == 2
    end

    test "second start_workout fails because of the partial unique active index", %{user: user} do
      _ = simple_template(user)
      {:ok, _} = Workouts.start_workout(user, "Push Day")
      assert {:error, _} = Workouts.start_workout(user, "Push Day")
    end

    test "returns :template_not_found when template missing", %{user: user} do
      assert {:error, :template_not_found} = Workouts.start_workout(user, "Nope")
    end
  end

  describe "complete_set/2 lifecycle" do
    setup %{user: user} do
      _ = simple_template(user)
      {:ok, workout} = Workouts.start_workout(user, "Push Day")
      %{workout: workout}
    end

    test "advances within an exercise then to the next exercise", %{user: user} do
      {:ok, w1} = Workouts.complete_set(user, %{"reps" => 5, "weight" => 100, "rpe" => 8})
      assert w1.current_exercise == 0
      assert w1.current_set == 1
      assert w1.total_volume == 500.0

      {:ok, w2} = Workouts.complete_set(user, %{"reps" => 5, "weight" => 100, "rpe" => 8})
      assert w2.current_set == 2

      {:ok, w3} = Workouts.complete_set(user, %{"reps" => 5, "weight" => 105, "rpe" => 9})
      assert w3.current_exercise == 1
      assert w3.current_set == 0
      assert w3.total_volume == 500.0 + 500.0 + 525.0
    end

    test "calculates average_rpe from completed sets only", %{user: user} do
      {:ok, _} = Workouts.complete_set(user, %{"reps" => 5, "weight" => 100, "rpe" => 8})
      {:ok, w} = Workouts.complete_set(user, %{"reps" => 5, "weight" => 100, "rpe" => 10})
      assert w.average_rpe == 9.0
    end

    test "sets rest_timer_end on the active workout", %{user: user} do
      {:ok, w} = Workouts.complete_set(user, %{"reps" => 5, "weight" => 100, "rpe" => 8})
      assert %DateTime{} = w.rest_timer_end
    end
  end

  describe "skip_exercise/1" do
    test "advances current_exercise and resets current_set", %{user: user} do
      _ = simple_template(user)
      {:ok, _} = Workouts.start_workout(user, "Push Day")
      {:ok, w} = Workouts.complete_set(user, %{"reps" => 5, "weight" => 100, "rpe" => 8})
      assert w.current_set == 1

      {:ok, skipped} = Workouts.skip_exercise(user)
      assert skipped.current_exercise == 1
      assert skipped.current_set == 0
    end
  end

  describe "end_workout/1" do
    test "completes the workout and writes max weight back into the template", %{user: user} do
      _ = simple_template(user)
      {:ok, _} = Workouts.start_workout(user, "Push Day")

      {:ok, _} = Workouts.complete_set(user, %{"reps" => 5, "weight" => 100, "rpe" => 8})
      {:ok, _} = Workouts.complete_set(user, %{"reps" => 5, "weight" => 110, "rpe" => 9})
      {:ok, _} = Workouts.complete_set(user, %{"reps" => 5, "weight" => 105, "rpe" => 9})
      {:ok, _} = Workouts.complete_set(user, %{"reps" => 5, "weight" => 65, "rpe" => 9})
      {:ok, _} = Workouts.complete_set(user, %{"reps" => 5, "weight" => 70, "rpe" => 10})

      assert {:ok, finished} = Workouts.end_workout(user)
      assert finished.status == "completed"
      assert %DateTime{} = finished.end_time

      {:ok, template} = Workouts.get_template(user, "Push Day")
      [bench_item, ohp_item] = template.exercises["items"]
      assert bench_item["target_weight"] == 110.0
      assert bench_item["previous_weight"] == 110.0
      assert ohp_item["target_weight"] == 70.0
    end
  end

  describe "get_history/1" do
    test "returns completed workouts with computed duration and volume", %{user: user} do
      _ = simple_template(user)
      {:ok, _} = Workouts.start_workout(user, "Push Day")

      for _ <- 1..5 do
        {:ok, _} = Workouts.complete_set(user, %{"reps" => 5, "weight" => 100, "rpe" => 8})
      end

      {:ok, _} = Workouts.end_workout(user)

      assert [entry] = Workouts.get_history(user)
      assert entry.name == "Push Day"
      assert entry.volume == 5 * 5 * 100.0
      assert is_integer(entry.duration)
    end
  end
end
