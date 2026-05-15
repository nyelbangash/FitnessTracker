defmodule GymBroWeb.Api.SessionController do
  use GymBroWeb, :controller

  alias GymBro.Accounts

  action_fallback GymBroWeb.Api.FallbackController

  def create(conn, params) do
    creds = params["credentials"] || params

    case Accounts.get_user_by_email_and_password(creds["email"], creds["password"]) do
      nil ->
        {:error, :invalid_credentials}

      user ->
        token = Accounts.create_user_api_token(user)

        conn
        |> put_status(:created)
        |> json(%{token: token, user: render_user(user)})
    end
  end

  def delete(conn, _params) do
    if token = conn.assigns[:api_token], do: Accounts.delete_user_api_token(token)
    send_resp(conn, :no_content, "")
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
