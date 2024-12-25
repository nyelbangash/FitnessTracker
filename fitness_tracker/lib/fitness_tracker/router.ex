alias FitnessTracker.Schemas.Profile

defmodule FitnessTracker.Router do
  use Plug.Router
  alias FitnessTracker.Schemas.Profile
  require Logger

  plug(:match)

  plug(Plug.Parsers,
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: Jason
  )

  plug(:dispatch)

  # Create profile
  post "/ft/profile" do
    case Profile.new(conn.body_params) do
      {:ok, profile} ->
        case Mongo.find_one(:mongo, "profiles", %{username: profile.username}) do
          nil ->
            case Mongo.insert_one(:mongo, "profiles", Profile.to_json(profile)) do
              {:ok, _} ->
                send_resp(conn, 201, Jason.encode!(%{message: "Profile created successfully"}))

              {:error, error} ->
                send_resp(conn, 500, "Failed to create profile: #{inspect(error)}")
            end

          _ ->
            send_resp(conn, 400, "Username already exists")
        end

      {:error, message} ->
        send_resp(conn, 400, message)
    end
  end

  # Get all profiles
  get "/ft/profile" do
    case Mongo.find(:mongo, "profiles", %{}) |> Enum.to_list() do
      profiles when is_list(profiles) ->
        # Remove _id and password from each profile
        profiles =
          Enum.map(profiles, fn profile ->
            profile
            |> Map.drop(["_id", "password"])
          end)

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{profiles: profiles}))

      _ ->
        send_resp(conn, 500, "Failed to retrieve profiles")
    end
  end

  # Get profile by username
  get "/ft/profile/:username" do
    case Mongo.find_one(:mongo, "profiles", %{username: username}) do
      nil ->
        send_resp(conn, 404, "Profile not found")

      profile ->
        # Remove sensitive fields
        profile = Map.drop(profile, ["_id", "password"])

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(profile))
    end
  end

  # Update profile
  put "/ft/profile/:username" do
    with {:ok, profile} <- Profile.new(conn.body_params),
         existing_profile when not is_nil(existing_profile) <-
           Mongo.find_one(:mongo, "profiles", %{username: username}),
         {:ok, _} <-
           Mongo.update_one(:mongo, "profiles", %{username: username}, %{
             "$set": Profile.to_json(profile)
           }) do
      send_resp(conn, 200, Jason.encode!(%{message: "Profile updated successfully"}))
    else
      nil -> send_resp(conn, 404, "Profile not found")
      {:error, message} -> send_resp(conn, 400, message)
    end
  end

  # Delete profile
  delete "/ft/profile/:username" do
    case Mongo.delete_one(:mongo, "profiles", %{username: username}) do
      {:ok, %{deleted_count: 1}} ->
        send_resp(conn, 200, Jason.encode!(%{message: "Profile deleted successfully"}))

      {:ok, %{deleted_count: 0}} ->
        send_resp(conn, 404, "Profile not found")

      {:error, error} ->
        send_resp(conn, 500, "Failed to delete profile: #{inspect(error)}")
    end
  end

  match _ do
    send_resp(conn, 404, "Not found")
  end
end
