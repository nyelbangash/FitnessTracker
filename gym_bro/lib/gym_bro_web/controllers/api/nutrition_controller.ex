defmodule GymBroWeb.Api.NutritionController do
  use GymBroWeb, :controller

  alias GymBro.Nutrition
  alias GymBroWeb.Api.Helpers

  action_fallback GymBroWeb.Api.FallbackController

  def goals(conn, _params) do
    json(conn, %{goals: Nutrition.get_goals(conn.assigns.current_user)})
  end

  def update_goals(conn, params) do
    attrs = params["goals"] || Map.take(params, ~w(calories protein carbs fat))

    with {:ok, user} <- Nutrition.update_goals(conn.assigns.current_user, attrs) do
      json(conn, %{goals: user.nutrition_goals})
    end
  end

  def daily(conn, %{"date" => date_str}) do
    with {:ok, date} <- Helpers.parse_date(date_str) do
      json(conn, Nutrition.daily_report(conn.assigns.current_user, date))
    end
  end
end
