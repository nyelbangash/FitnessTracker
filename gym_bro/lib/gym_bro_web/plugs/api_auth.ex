defmodule GymBroWeb.Plugs.ApiAuth do
  @moduledoc """
  Plug that authenticates API requests via the `Authorization: Bearer <token>`
  header. On success, assigns `:current_user` and `:api_token` on the conn.
  On failure, halts with a 401 JSON response.
  """

  import Plug.Conn
  alias GymBro.Accounts

  def init(opts), do: opts

  def call(conn, _opts) do
    with [header] <- get_req_header(conn, "authorization"),
         "Bearer " <> token <- header,
         %_{} = user <- Accounts.get_user_by_api_token(token) do
      conn
      |> assign(:current_user, user)
      |> assign(:api_token, token)
    else
      _ -> unauthorized(conn)
    end
  end

  defp unauthorized(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(401, Jason.encode!(%{error: "unauthorized"}))
    |> halt()
  end
end
