defmodule GymBro.Nutrition do
  @moduledoc """
  The Nutrition context: wraps nutrition goals (stored on the user) and
  computes daily totals + adherence by combining goals with logged meals.
  """

  alias GymBro.Accounts
  alias GymBro.Accounts.User
  alias GymBro.Meals

  def get_goals(%User{} = user), do: Accounts.get_nutrition_goals(user)

  def update_goals(%User{} = user, attrs), do: Accounts.update_nutrition_goals(user, attrs)

  @doc """
  Returns daily macro totals plus the user's targets and per-macro progress
  ratios (0.0–1.0+).
  """
  def daily_report(%User{} = user, %Date{} = date) do
    totals = Meals.daily_totals(user, date)
    goals = get_goals(user) || %{}

    progress = %{
      calories: progress_ratio(totals.calories, goals["calories"]),
      protein: progress_ratio(totals.protein, goals["protein"]),
      carbs: progress_ratio(totals.carbs, goals["carbs"]),
      fat: progress_ratio(totals.fat, goals["fat"])
    }

    %{
      date: date,
      totals: Map.delete(totals, :meals),
      goals: goals,
      progress: progress,
      meals: totals.meals
    }
  end

  defp progress_ratio(_, nil), do: 0.0
  defp progress_ratio(_, 0), do: 0.0
  defp progress_ratio(value, target) when is_number(target) and target > 0 do
    value / target
  end

  defp progress_ratio(_, _), do: 0.0
end
