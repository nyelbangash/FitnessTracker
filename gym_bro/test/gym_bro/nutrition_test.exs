defmodule GymBro.NutritionTest do
  use GymBro.DataCase, async: true

  alias GymBro.{Meals, Nutrition}

  import GymBro.AccountsFixtures

  setup do
    %{user: user_fixture()}
  end

  describe "goals" do
    test "new users get the default goals", %{user: user} do
      goals = Nutrition.get_goals(user)
      assert goals["calories"] == 2000
      assert goals["protein"] == 150
    end

    test "update_goals/2 merges partial updates", %{user: user} do
      {:ok, user} = Nutrition.update_goals(user, %{"protein" => 180})
      assert user.nutrition_goals["protein"] == 180
      assert user.nutrition_goals["calories"] == 2000
    end

    test "update_goals/2 rejects negative values", %{user: user} do
      assert {:error, _} = Nutrition.update_goals(user, %{"calories" => -100})
    end
  end

  describe "daily_report/2" do
    test "returns totals, goals, and per-macro progress ratios", %{user: user} do
      {:ok, _} =
        Meals.create_meal(user, %{
          "name" => "Steak Plate",
          "date" => "2026-05-14",
          "meal_type" => "dinner",
          "calories" => 1000,
          "protein" => 75.0,
          "carbs" => 40.0,
          "fat" => 30.0,
          "ingredients" => []
        })

      report = Nutrition.daily_report(user, ~D[2026-05-14])
      assert report.totals.calories == 1000
      assert report.goals["calories"] == 2000
      assert_in_delta report.progress.calories, 0.5, 0.001
      assert_in_delta report.progress.protein, 0.5, 0.001
      assert length(report.meals) == 1
    end
  end
end
