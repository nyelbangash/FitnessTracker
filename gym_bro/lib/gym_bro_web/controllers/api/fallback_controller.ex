defmodule GymBroWeb.Api.FallbackController do
  use GymBroWeb, :controller

  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(%{errors: changeset_errors(changeset)})
  end

  def call(conn, {:error, :not_found}), do: send_error(conn, :not_found, "not_found")
  def call(conn, {:error, :no_active_workout}),
    do: send_error(conn, :not_found, "no_active_workout")
  def call(conn, {:error, :template_not_found}),
    do: send_error(conn, :not_found, "template_not_found")
  def call(conn, {:error, :invalid_credentials}),
    do: send_error(conn, :unauthorized, "invalid_credentials")
  def call(conn, {:error, :invalid_date}),
    do: send_error(conn, :bad_request, "invalid_date")
  def call(conn, {:error, :invalid_rpe}),
    do: send_error(conn, :bad_request, "invalid_rpe")
  def call(conn, {:error, :invalid_rest_time}),
    do: send_error(conn, :bad_request, "invalid_rest_time")
  def call(conn, {:error, :invalid_targets}),
    do: send_error(conn, :bad_request, "invalid_targets")
  def call(conn, {:error, :missing_set_params}),
    do: send_error(conn, :bad_request, "missing_set_params")
  def call(conn, {:error, :no_current_exercise}),
    do: send_error(conn, :unprocessable_entity, "no_current_exercise")
  def call(conn, {:error, :no_current_set}),
    do: send_error(conn, :unprocessable_entity, "no_current_set")
  def call(conn, {:error, :locked}),
    do: send_error(conn, :forbidden, "meal_locked")
  def call(conn, {:error, reason}) when is_atom(reason) do
    send_error(conn, :bad_request, Atom.to_string(reason))
  end

  defp send_error(conn, status, message) do
    conn
    |> put_status(status)
    |> json(%{error: message})
  end

  defp changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
