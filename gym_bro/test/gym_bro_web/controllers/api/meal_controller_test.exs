defmodule GymBroWeb.Api.MealControllerTest do
  use GymBroWeb.ConnCase, async: true

  import GymBro.AccountsFixtures

  setup do
    user = user_fixture()
    %{conn: authed_api_conn(user), user: user}
  end

  defp meal_attrs(overrides \\ %{}) do
    Map.merge(
      %{
        name: "Oatmeal",
        date: "2026-05-14",
        meal_type: "breakfast",
        calories: 350,
        protein: 12.0,
        carbs: 60.0,
        fat: 5.0,
        ingredients: [%{name: "rolled oats", amount: 60, unit: "g"}]
      },
      overrides
    )
  end

  describe "POST /api/meals" do
    test "creates a meal", %{conn: conn} do
      conn = post(conn, ~p"/api/meals", %{meal: meal_attrs()})
      body = json_response(conn, 201)
      assert body["meal"]["name"] == "Oatmeal"
      assert body["meal"]["date"] == "2026-05-14"
      assert [%{"name" => "rolled oats"}] = body["meal"]["ingredients"]
    end

    test "422 on invalid meal_type", %{conn: conn} do
      conn = post(conn, ~p"/api/meals", %{meal: meal_attrs(%{meal_type: "elevenses"})})
      body = json_response(conn, 422)
      assert Map.has_key?(body["errors"], "meal_type")
    end
  end

  describe "GET /api/meals" do
    test "lists user's meals", %{conn: conn} do
      _ = post(conn, ~p"/api/meals", %{meal: meal_attrs()})

      conn = get(conn, ~p"/api/meals")
      body = json_response(conn, 200)
      assert length(body["meals"]) == 1
    end
  end

  describe "favorite toggle" do
    test "POST /api/meals/:name/:date/favorite flips flag", %{conn: conn} do
      _ = post(conn, ~p"/api/meals", %{meal: meal_attrs()})

      conn = post(conn, ~p"/api/meals/Oatmeal/2026-05-14/favorite")
      body = json_response(conn, 200)
      assert body["meal"]["is_favorite"] == true

      conn = get(conn, ~p"/api/meals/favorites")
      assert [_] = json_response(conn, 200)["meals"]
    end
  end
end
