defmodule GymBroWeb.Api.SessionControllerTest do
  use GymBroWeb.ConnCase, async: true

  import GymBro.AccountsFixtures

  describe "POST /api/login" do
    test "returns a bearer token for valid credentials", %{conn: conn} do
      user = user_fixture()
      attrs = %{credentials: %{email: user.email, password: valid_user_password()}}

      conn = post(conn, ~p"/api/login", attrs)
      body = json_response(conn, 201)

      assert is_binary(body["token"])
      assert body["user"]["email"] == user.email
      assert body["user"]["first_name"] == "Test"
    end

    test "401 on bad credentials", %{conn: conn} do
      user = user_fixture()

      conn =
        post(conn, ~p"/api/login", %{credentials: %{email: user.email, password: "wrongpass"}})

      assert %{"error" => "invalid_credentials"} = json_response(conn, 401)
    end
  end

  describe "DELETE /api/logout" do
    test "revokes the API token", %{conn: _conn} do
      user = user_fixture()
      conn = authed_api_conn(user)

      delete_conn = delete(conn, ~p"/api/logout")
      assert delete_conn.status == 204

      # Same token can't be reused
      retry = get(conn, ~p"/api/me")
      assert json_response(retry, 401) == %{"error" => "unauthorized"}
    end
  end

  describe "Unauthenticated access" do
    test "GET /api/me without token returns 401", %{conn: conn} do
      conn = get(conn, ~p"/api/me")
      assert json_response(conn, 401) == %{"error" => "unauthorized"}
    end
  end
end
