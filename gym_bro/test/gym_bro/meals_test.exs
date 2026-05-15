defmodule GymBro.MealsTest do
  use GymBro.DataCase, async: true

  alias GymBro.Meals

  import GymBro.AccountsFixtures

  setup do
    %{user: user_fixture()}
  end

  defp meal_attrs(overrides \\ %{}) do
    Map.merge(
      %{
        "name" => "Oatmeal",
        "date" => "2026-05-14",
        "meal_type" => "breakfast",
        "calories" => 350,
        "protein" => 12.0,
        "carbs" => 60.0,
        "fat" => 5.0,
        "ingredients" => [%{"name" => "rolled oats", "amount" => 60, "unit" => "g"}]
      },
      overrides
    )
  end

  describe "create_meal/2" do
    test "creates a meal and auto-creates the meal_log for the date", %{user: user} do
      assert {:ok, meal} = Meals.create_meal(user, meal_attrs())
      assert meal.name == "Oatmeal"
      assert meal.date == ~D[2026-05-14]
      assert [%{name: "rolled oats"}] = meal.ingredients
    end

    test "reuses an existing meal_log for the same date", %{user: user} do
      {:ok, _} = Meals.create_meal(user, meal_attrs(%{"name" => "Eggs"}))
      {:ok, _} = Meals.create_meal(user, meal_attrs(%{"name" => "Oatmeal"}))
      assert length(Meals.list_meals(user)) == 2
    end

    test "rejects invalid meal_type", %{user: user} do
      assert {:error, changeset} = Meals.create_meal(user, meal_attrs(%{"meal_type" => "elevenses"}))
      assert "is invalid" in errors_on(changeset).meal_type
    end
  end

  describe "flags" do
    setup %{user: user} do
      {:ok, meal} = Meals.create_meal(user, meal_attrs())
      %{meal: meal}
    end

    test "toggle_favorite/3 flips is_favorite", %{user: user} do
      assert {:ok, m1} = Meals.toggle_favorite(user, "Oatmeal", ~D[2026-05-14])
      assert m1.is_favorite == true
      assert [_] = Meals.list_favorites(user)

      assert {:ok, m2} = Meals.toggle_favorite(user, "Oatmeal", ~D[2026-05-14])
      assert m2.is_favorite == false
      assert Meals.list_favorites(user) == []
    end

    test "set_recurring/4 stores schedule and flags meal", %{user: user} do
      assert {:ok, m} = Meals.set_recurring(user, "Oatmeal", ~D[2026-05-14], "Weekdays 8am")
      assert m.is_recurring == true
      assert m.schedule == "Weekdays 8am"
      assert [_] = Meals.list_recurring(user)
    end
  end

  describe "daily_totals/2" do
    test "sums macros and includes per-meal summaries", %{user: user} do
      {:ok, _} = Meals.create_meal(user, meal_attrs())
      {:ok, _} =
        Meals.create_meal(
          user,
          meal_attrs(%{"name" => "Chicken Rice", "meal_type" => "lunch", "calories" => 600, "protein" => 45.0, "carbs" => 80.0, "fat" => 10.0})
        )

      totals = Meals.daily_totals(user, ~D[2026-05-14])
      assert totals.calories == 950
      assert totals.protein == 57.0
      assert totals.carbs == 140.0
      assert totals.fat == 15.0
      assert length(totals.meals) == 2
    end

    test "returns zeros when no meals on date", %{user: user} do
      totals = Meals.daily_totals(user, ~D[2026-05-14])
      assert totals.calories == 0
      assert totals.meals == []
    end
  end
end
