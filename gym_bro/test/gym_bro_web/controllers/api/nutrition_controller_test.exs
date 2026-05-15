defmodule GymBroWeb.Api.NutritionControllerTest do
  use GymBroWeb.ConnCase, async: true

  import GymBro.AccountsFixtures

  setup do
    user = user_fixture()
    %{conn: authed_api_conn(user), user: user}
  end

  describe "GET /api/nutrition/goals" do
    test "returns default goals for a new user", %{conn: conn} do
      conn = get(conn, ~p"/api/nutrition/goals")
      body = json_response(conn, 200)
      assert body["goals"]["calories"] == 2000
      assert body["goals"]["protein"] == 150
    end
  end

  describe "PUT /api/nutrition/goals" do
    test "merges partial updates", %{conn: conn} do
      conn = put(conn, ~p"/api/nutrition/goals", %{goals: %{protein: 180}})
      body = json_response(conn, 200)
      assert body["goals"]["protein"] == 180
      assert body["goals"]["calories"] == 2000
    end

    test "422 on invalid value", %{conn: conn} do
      conn = put(conn, ~p"/api/nutrition/goals", %{goals: %{calories: -100}})
      assert json_response(conn, 422)
    end
  end

  describe "GET /api/nutrition/daily/:date" do
    test "returns totals, goals, progress, meals", %{conn: conn} do
      _ =
        post(conn, ~p"/api/meals", %{
          meal: %{
            name: "Steak",
            date: "2026-05-14",
            meal_type: "dinner",
            calories: 1000,
            protein: 75.0,
            carbs: 40.0,
            fat: 30.0,
            ingredients: []
          }
        })

      conn = get(conn, ~p"/api/nutrition/daily/2026-05-14")
      body = json_response(conn, 200)
      assert body["totals"]["calories"] == 1000
      assert body["goals"]["calories"] == 2000
      assert_in_delta body["progress"]["calories"], 0.5, 0.001
    end

    test "400 on malformed date", %{conn: conn} do
      conn = get(conn, ~p"/api/nutrition/daily/not-a-date")
      assert json_response(conn, 400) == %{"error" => "invalid_date"}
    end
  end
end
