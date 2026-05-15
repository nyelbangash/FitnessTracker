defmodule GymBroWeb.Api.UserControllerTest do
  use GymBroWeb.ConnCase, async: true

  import GymBro.AccountsFixtures

  describe "POST /api/users (signup)" do
    test "creates a user and returns a token", %{conn: conn} do
      attrs = %{
        user: %{
          email: unique_user_email(),
          password: valid_user_password(),
          first_name: "Alice",
          last_name: "Andrews"
        }
      }

      conn = post(conn, ~p"/api/users", attrs)
      body = json_response(conn, 201)

      assert is_binary(body["token"])
      assert body["user"]["first_name"] == "Alice"
    end

    test "422 with errors on invalid input", %{conn: conn} do
      conn = post(conn, ~p"/api/users", %{user: %{email: "bad", password: "x"}})
      body = json_response(conn, 422)
      assert Map.has_key?(body["errors"], "email") or Map.has_key?(body["errors"], "password")
    end
  end

  describe "GET /api/me" do
    test "returns the current user", %{conn: _conn} do
      user = user_fixture()
      conn = authed_api_conn(user)

      conn = get(conn, ~p"/api/me")
      body = json_response(conn, 200)
      assert body["user"]["email"] == user.email
      assert body["user"]["nutrition_goals"]["calories"] == 2000
    end
  end

  describe "PUT /api/me" do
    test "updates profile fields", %{conn: _conn} do
      user = user_fixture()
      conn = authed_api_conn(user)

      conn = put(conn, ~p"/api/me", %{user: %{height_cm: 180, weight_kg: 80.0}})
      body = json_response(conn, 200)
      assert body["user"]["height_cm"] == 180
      assert body["user"]["weight_kg"] == 80.0
    end
  end
end
