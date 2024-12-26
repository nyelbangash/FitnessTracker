alias FitnessTracker.Schemas.Profile

defmodule FitnessTracker.Router do
  use Plug.Router
  alias FitnessTracker.Schemas.{Profile, Workout, Meal}
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
    case Profile.create(conn.body_params) do
      {:ok, _profile} ->
        send_resp(conn, 201, Jason.encode!(%{message: "Profile created successfully"}))

      {:error, :username_exists} ->
        send_resp(conn, 400, "Username already exists")

      {:error, message} ->
        send_resp(conn, 400, message)
    end
  end

  # Get all profiles
  get "/ft/profile" do
    case Profile.get_all() do
      profiles when is_list(profiles) ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{profiles: profiles}))

      {:error, _} ->
        send_resp(conn, 500, "Failed to retrieve profiles")
    end
  end

  get "/ft/profile/:username" do
    case Profile.get_by_username(username) do
      {:ok, profile} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(profile))

      {:error, :not_found} ->
        send_resp(conn, 404, "Profile not found")
    end
  end

  # Delete profile
  put "/ft/profile/:username" do
    case Profile.update(username, conn.body_params) do
      {:ok, _profile} ->
        send_resp(conn, 200, Jason.encode!(%{message: "Profile updated successfully"}))

      {:error, :not_found} ->
        send_resp(conn, 404, "Profile not found")

      {:error, message} ->
        send_resp(conn, 400, message)
    end
  end

  delete "/ft/profile/:username" do
    case Profile.delete(username) do
      :ok ->
        send_resp(conn, 200, Jason.encode!(%{message: "Profile deleted successfully"}))

      {:error, :not_found} ->
        send_resp(conn, 404, "Profile not found")

      {:error, error} ->
        send_resp(conn, 500, "Failed to delete profile: #{inspect(error)}")
    end
  end

  # Enhanced post workout endpoint with better validation
  post "/ft/profile/:username/workout" do
    case Workout.create(username, conn.body_params) do
      {:ok, _workout} ->
        send_resp(conn, 201, Jason.encode!(%{message: "Workout added successfully"}))

      {:error, :profile_not_found} ->
        send_resp(conn, 404, "Profile not found")

      {:error, :workout_exists} ->
        send_resp(conn, 409, "Workout already exists for this date")

      {:error, message} ->
        send_resp(conn, 400, message)
    end
  end

  get "/ft/profile/:username/workout" do
    case Workout.get_all(username) do
      {:ok, workouts} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{workouts: workouts}))

      {:error, :profile_not_found} ->
        send_resp(conn, 404, "Profile not found")

      {:error, :workout_log_not_found} ->
        send_resp(conn, 500, "Error retrieving workout log")
    end
  end

  get "/ft/profile/:username/workout/:workout_name/:date" do
    case Workout.get(username, workout_name, date) do
      {:ok, workout} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(workout))

      {:error, :profile_not_found} ->
        send_resp(conn, 404, "Profile not found")

      {:error, :not_found} ->
        send_resp(conn, 404, "Workout not found")
    end
  end

  put "/ft/profile/:username/workout/:workout_name/:date" do
    case Workout.update(username, workout_name, date, conn.body_params) do
      {:ok, _workout} ->
        send_resp(conn, 200, Jason.encode!(%{message: "Workout updated successfully"}))

      {:error, :profile_not_found} ->
        send_resp(conn, 404, "Profile not found")

      {:error, message} ->
        send_resp(conn, 400, "Invalid workout parameters: #{message}")
    end
  end

  delete "/ft/profile/:username/workout/:workout_name/:date" do
    case Workout.delete(username, workout_name, date) do
      :ok ->
        send_resp(conn, 200, Jason.encode!(%{message: "Workout deleted successfully"}))

      {:error, :not_found} ->
        send_resp(conn, 404, "Workout not found")

      {:error, error} ->
        send_resp(conn, 500, "Failed to delete workout: #{inspect(error)}")
    end
  end

  delete "/ft/profile/:username/workout/all" do
    case Workout.clear_log(username) do
      :ok ->
        send_resp(conn, 200, Jason.encode!(%{message: "Workout log cleared successfully"}))

      {:error, :profile_not_found} ->
        send_resp(conn, 404, "Profile not found")

      {:error, error} ->
        send_resp(conn, 500, "Failed to clear workout log: #{inspect(error)}")
    end
  end

  post "/ft/profile/:username/meal" do
    case Meal.create(username, conn.body_params) do
      {:ok, _meal} ->
        send_resp(conn, 201, Jason.encode!(%{message: "Meal added successfully"}))

      {:error, :profile_not_found} ->
        send_resp(conn, 404, "Profile not found")

      {:error, :meal_exists} ->
        send_resp(conn, 409, "Meal already exists for this date")

      {:error, message} ->
        send_resp(conn, 400, message)
    end
  end

  get "/ft/profile/:username/meal" do
    case Meal.get_all(username) do
      {:ok, meals} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{meals: meals}))

      {:error, :profile_not_found} ->
        send_resp(conn, 404, "Profile not found")

      {:error, :meal_log_not_found} ->
        send_resp(conn, 500, "Error retrieving meal log")
    end
  end

  get "/ft/profile/:username/meal/:meal_name/:date" do
    case Meal.get(username, meal_name, date) do
      {:ok, meal} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(meal))

      {:error, :profile_not_found} ->
        send_resp(conn, 404, "Profile not found")

      {:error, :not_found} ->
        send_resp(conn, 404, "Meal not found")
    end
  end

  put "/ft/profile/:username/meal/:meal_name/:date" do
    case Meal.update(username, meal_name, date, conn.body_params) do
      {:ok, _meal} ->
        send_resp(conn, 200, Jason.encode!(%{message: "Meal updated successfully"}))

      {:error, :profile_not_found} ->
        send_resp(conn, 404, "Profile not found")

      {:error, message} ->
        send_resp(conn, 400, "Invalid meal parameters: #{message}")
    end
  end

  delete "/ft/profile/:username/meal/:meal_name/:date" do
    case Meal.delete(username, meal_name, date) do
      :ok ->
        send_resp(conn, 200, Jason.encode!(%{message: "Meal deleted successfully"}))

      {:error, :not_found} ->
        send_resp(conn, 404, "Meal not found")

      {:error, error} ->
        send_resp(conn, 500, "Failed to delete meal: #{inspect(error)}")
    end
  end

  delete "/ft/profile/:username/meal/all" do
    case Meal.clear_log(username) do
      :ok ->
        send_resp(conn, 200, Jason.encode!(%{message: "Meal log cleared successfully"}))

      {:error, :profile_not_found} ->
        send_resp(conn, 404, "Profile not found")

      {:error, error} ->
        send_resp(conn, 500, "Failed to clear meal log: #{inspect(error)}")
    end
  end

  match _ do
    send_resp(conn, 404, "Not found")
  end
end
