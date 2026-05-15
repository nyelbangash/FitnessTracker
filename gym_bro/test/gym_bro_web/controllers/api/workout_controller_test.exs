defmodule GymBroWeb.Api.WorkoutControllerTest do
  use GymBroWeb.ConnCase, async: true

  import GymBro.AccountsFixtures
  alias GymBro.Workouts

  setup do
    user = user_fixture()
    conn = authed_api_conn(user)

    {:ok, _template} =
      Workouts.create_template(user, %{
        name: "Push Day",
        exercises: %{
          "items" => [
            %{
              "exercise_name" => "Bench Press",
              "target_reps" => 5,
              "target_weight" => 100.0,
              "target_sets" => 3,
              "rest_time" => 90
            }
          ]
        }
      })

    %{conn: conn, user: user}
  end

  describe "active workout lifecycle" do
    test "start, complete sets, end", %{conn: conn} do
      conn = post(conn, ~p"/api/workouts/active/start", %{workout_name: "Push Day"})
      body = json_response(conn, 201)
      assert body["workout"]["status"] == "in_progress"
      assert length(body["workout"]["exercises"]) == 1
      assert length(hd(body["workout"]["exercises"])["sets"]) == 3

      Enum.reduce(1..3, conn, fn _i, c ->
        c = post(c, ~p"/api/workouts/active/set", %{reps: 5, weight: 100, rpe: 8})
        assert json_response(c, 200)
        c
      end)

      conn = post(conn, ~p"/api/workouts/active/end")
      body = json_response(conn, 200)
      assert body["workout"]["status"] == "completed"
    end

    test "GET /api/workouts/active 404s with no active workout", %{conn: conn} do
      conn = get(conn, ~p"/api/workouts/active")
      assert json_response(conn, 404) == %{"error" => "no_active_workout"}
    end

    test "starting a non-existent template returns 404", %{conn: conn} do
      conn = post(conn, ~p"/api/workouts/active/start", %{workout_name: "Doesnt Exist"})
      assert json_response(conn, 404) == %{"error" => "template_not_found"}
    end
  end

  describe "templates" do
    test "GET /api/workouts/templates lists templates", %{conn: conn} do
      conn = get(conn, ~p"/api/workouts/templates")
      body = json_response(conn, 200)
      assert [%{"name" => "Push Day"}] = body["templates"]
    end
  end

  describe "history" do
    test "GET /api/workouts/history returns completed workouts", %{conn: conn, user: _user} do
      conn = post(conn, ~p"/api/workouts/active/start", %{workout_name: "Push Day"})
      assert json_response(conn, 201)

      Enum.reduce(1..3, conn, fn _i, c ->
        post(c, ~p"/api/workouts/active/set", %{reps: 5, weight: 100, rpe: 8})
      end)

      _ = post(conn, ~p"/api/workouts/active/end")

      conn = get(conn, ~p"/api/workouts/history")
      body = json_response(conn, 200)
      assert [%{"name" => "Push Day"}] = body["history"]
    end
  end
end
