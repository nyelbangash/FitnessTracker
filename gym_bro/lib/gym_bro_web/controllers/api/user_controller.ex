defmodule GymBroWeb.Api.UserController do
  use GymBroWeb, :controller

  alias GymBro.Accounts

  action_fallback GymBroWeb.Api.FallbackController

  def create(conn, params) do
    attrs = params["user"] || params

    with {:ok, user} <- Accounts.register_user(attrs) do
      token = Accounts.create_user_api_token(user)

      conn
      |> put_status(:created)
      |> json(%{token: token, user: render_user(user)})
    end
  end

  def show(conn, _params) do
    json(conn, %{user: render_user(conn.assigns.current_user)})
  end

  def update(conn, params) do
    attrs = params["user"] || params

    with {:ok, user} <- Accounts.update_profile(conn.assigns.current_user, attrs) do
      json(conn, %{user: render_user(user)})
    end
  end

  defp render_user(user) do
    %{
      id: user.id,
      email: user.email,
      first_name: user.first_name,
      last_name: user.last_name,
      height_cm: user.height_cm,
      weight_kg: user.weight_kg,
      dob: user.dob,
      nutrition_goals: user.nutrition_goals,
      theme: user.theme
    }
  end
end
