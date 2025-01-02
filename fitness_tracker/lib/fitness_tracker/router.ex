alias FitnessTracker.Schemas.Profile

defmodule FitnessTracker.Router do
  use Plug.Router
  # Add this line
  require Protocol
  alias FitnessTracker.Schemas.{Profile, Workout, Meal}
  require Logger

  Protocol.derive(Jason.Encoder, Mongo.UpdateResult, only: [:acknowledged])

  plug(CORSPlug, origin: ["http://localhost:4001"])
  plug(:match)

  plug(Plug.Parsers,
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: Jason
  )

  plug(:dispatch)

  # Add this with your other workout endpoints
  get "/ft/profile/:username/workout/:workout_name/:date/summary" do
    case Workout.get_workout_summary(username, workout_name, date) do
      {:ok, summary} -> send_json_response(conn, 200, summary)
      {:error, :not_found} -> send_json_response(conn, 404, %{message: "Workout not found"})
      {:error, message} -> send_json_response(conn, 400, %{message: message})
    end
  end

  post "/ft/profile" do
    case Profile.create(conn.body_params) do
      {:ok, _profile} ->
        send_json_response(conn, 201, %{message: "Profile created successfully"})

      {:error, :username_exists} ->
        send_json_response(conn, 400, %{message: "Username already exists"})

      {:error, message} ->
        send_json_response(conn, 400, %{message: message})
    end
  end

  post "/ft/login" do
    with {:ok, %{"username" => username, "password" => password}} <-
           Map.fetch(conn.body_params, "credentials"),
         {:ok, profile} <- Profile.authenticate(username, password) do
      send_json_response(conn, 200, %{success: true, profile: profile})
    else
      {:error, :not_found} ->
        send_json_response(conn, 404, %{success: false, message: "User not found"})

      {:error, :invalid_credentials} ->
        send_json_response(conn, 401, %{success: false, message: "Invalid credentials"})

      _ ->
        send_json_response(conn, 400, %{success: false, message: "Invalid request"})
    end
  end

  post "/ft/logout" do
    send_json_response(conn, 200, %{success: true, message: "Logged out successfully"})
  end

  get "/ft/profile" do
    case Profile.get_all() do
      profiles when is_list(profiles) -> send_json_response(conn, 200, %{profiles: profiles})
      {:error, _} -> send_json_response(conn, 500, %{message: "Failed to retrieve profiles"})
    end
  end

  get "/ft/profile/:username" do
    case Profile.get_by_username(username) do
      {:ok, profile} -> send_json_response(conn, 200, profile)
      {:error, :not_found} -> send_json_response(conn, 404, %{message: "Profile not found"})
    end
  end

  put "/ft/profile/:username" do
    case Profile.update(username, conn.body_params) do
      {:ok, _profile} -> send_json_response(conn, 200, %{message: "Profile updated successfully"})
      {:error, :not_found} -> send_json_response(conn, 404, %{message: "Profile not found"})
      {:error, message} -> send_json_response(conn, 400, %{message: message})
    end
  end

  delete "/ft/profile/:username" do
    case Profile.delete(username) do
      :ok ->
        send_json_response(conn, 200, %{message: "Profile deleted successfully"})

      {:error, :not_found} ->
        send_json_response(conn, 404, %{message: "Profile not found"})

      {:error, error} ->
        send_json_response(conn, 500, %{message: "Failed to delete profile: #{inspect(error)}"})
    end
  end

  post "/ft/profile/:username/workout" do
    case Workout.create(username, conn.body_params) do
      {:ok, _workout} ->
        send_json_response(conn, 201, %{message: "Workout added successfully"})

      {:error, :profile_not_found} ->
        send_json_response(conn, 404, %{message: "Profile not found"})

      {:error, message} when is_binary(message) ->
        send_json_response(conn, 400, %{message: message})
    end
  end

  get "/ft/profile/:username/workout" do
    case Workout.get_all(username) do
      {:ok, workouts} ->
        send_json_response(conn, 200, %{workouts: workouts})

      {:error, :profile_not_found} ->
        send_json_response(conn, 404, %{message: "Profile not found"})

      {:error, :workout_log_not_found} ->
        send_json_response(conn, 500, %{message: "Error retrieving workout log"})
    end
  end

  post "/ft/profile/:username/workout/end" do
    case Workout.end_workout(username) do
      {:ok, workout} ->
        send_resp(
          conn,
          200,
          Jason.encode!(%{
            message: "Workout completed successfully",
            workout: workout
          })
        )

      _ ->
        send_resp(conn, 404, Jason.encode!(%{message: "No active workout found"}))
    end
  end

  get "/ft/profile/:username/workout/active/stats" do
    case Workout.get_workout_stats(username) do
      {:ok, stats} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(stats))

      error ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(404, Jason.encode!(%{message: "No active workout found"}))
    end
  end

  put "/ft/profile/:username/workout/active/rest" do
    rest_time = Map.get(conn.body_params, "rest_time")

    case rest_time do
      time when is_number(time) and time > 0 ->
        case Workout.update_rest_timer(username, time) do
          {:ok, workout} ->
            send_json_response(conn, 200, %{workout: workout})

          _ ->
            send_json_response(conn, 400, %{message: "Failed to update rest timer"})
        end

      time when is_binary(time) ->
        case Integer.parse(time) do
          {num, ""} when num > 0 ->
            case Workout.update_rest_timer(username, num) do
              {:ok, workout} ->
                send_json_response(conn, 200, %{workout: workout})

              _ ->
                send_json_response(conn, 400, %{message: "Failed to update rest timer"})
            end

          _ ->
            send_json_response(conn, 400, %{message: "Invalid rest_time parameter"})
        end

      _ ->
        send_json_response(conn, 400, %{message: "Invalid rest_time parameter"})
    end
  end

  put "/ft/profile/:username/workout/active/notes" do
    with %{"notes" => notes} <- conn.body_params,
         {:ok, workout} <- Workout.update_workout_notes(username, notes) do
      conn
      |> put_resp_content_type("application/json")
      |> send_resp(
        200,
        Jason.encode!(%{
          message: "Notes updated successfully",
          workout: workout
        })
      )
    else
      error ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(400, Jason.encode!(%{message: "Invalid notes parameter"}))
    end
  end

  get "/ft/profile/:username/workout/:workout_name/:date" do
    case Workout.get(username, workout_name, date) do
      {:ok, workout} ->
        send_json_response(conn, 200, workout)

      {:error, :profile_not_found} ->
        send_json_response(conn, 404, %{message: "Profile not found"})

      {:error, :not_found} ->
        send_json_response(conn, 404, %{message: "Workout not found"})
    end
  end

  put "/ft/profile/:username/workout/:workout_name/:date" do
    case Workout.update(username, workout_name, date, conn.body_params) do
      {:ok, _workout} ->
        send_json_response(conn, 200, %{message: "Workout updated successfully"})

      {:error, :profile_not_found} ->
        send_json_response(conn, 404, %{message: "Profile not found"})

      {:error, message} ->
        send_json_response(conn, 400, %{message: message})
    end
  end

  delete "/ft/profile/:username/workout/:workout_name/:date" do
    case Workout.delete(username, workout_name, date) do
      :ok ->
        send_json_response(conn, 200, %{message: "Workout deleted successfully"})

      {:error, :not_found} ->
        send_json_response(conn, 404, %{message: "Workout not found"})

      {:error, error} ->
        send_json_response(conn, 500, %{message: "Failed to delete workout: #{inspect(error)}"})
    end
  end

  delete "/ft/profile/:username/workout/all" do
    case Workout.clear_log(username) do
      :ok ->
        send_json_response(conn, 200, %{message: "Workout log cleared successfully"})

      {:error, :profile_not_found} ->
        send_json_response(conn, 404, %{message: "Profile not found"})

      {:error, error} ->
        send_json_response(conn, 500, %{message: "Failed to clear workout log: #{inspect(error)}"})
    end
  end

  # Template Operations
  post "/ft/profile/:username/workout/template" do
    case Workout.save_as_template(username, conn.body_params["workout_name"]) do
      {:ok, template} ->
        send_json_response(conn, 201, %{
          message: "Workout template created successfully",
          template: template
        })

      {:error, message} ->
        send_json_response(conn, 400, %{message: message})
    end
  end

  get "/ft/profile/:username/workout/templates" do
    case Workout.get_templates(username) do
      {:ok, templates} -> send_json_response(conn, 200, %{templates: templates})
      {:error, message} -> send_json_response(conn, 400, %{message: message})
    end
  end

  put "/ft/profile/:username/workout/template/:template_name" do
    case Workout.save_template(username, template_name, conn.body_params) do
      {:ok, template} -> send_json_response(conn, 200, %{template: template})
      {:error, message} -> send_json_response(conn, 400, %{message: message})
    end
  end

  delete "/ft/profile/:username/workout/template/:template_name" do
    case Workout.delete_template(username, template_name) do
      :ok -> send_json_response(conn, 200, %{message: "Template deleted successfully"})
      {:error, message} -> send_json_response(conn, 404, %{message: message})
    end
  end

  # Active Workout Operations
  post "/ft/profile/:username/workout/start" do
    case Workout.start_workout(username, conn.body_params["workout_name"]) do
      {:ok, workout} ->
        send_json_response(conn, 200, %{message: "Workout started successfully", workout: workout})

      {:error, :template_not_found} ->
        send_json_response(conn, 404, %{message: "Workout template not found"})

      {:error, message} ->
        send_json_response(conn, 400, %{message: message})
    end
  end

  get "/ft/profile/:username/workout/active" do
    case Workout.get_active_workout(username) do
      {:ok, workout} ->
        send_json_response(conn, 200, workout)

      {:error, :no_active_workout} ->
        send_json_response(conn, 404, %{message: "No active workout found"})

      {:error, message} ->
        send_json_response(conn, 400, %{message: message})
    end
  end

  post "/ft/profile/:username/workout/active/set" do
    case Workout.complete_set(username, conn.body_params) do
      {:ok, updated_workout} ->
        send_json_response(conn, 200, %{
          message: "Set completed successfully",
          workout: updated_workout
        })

      {:error, message} ->
        send_json_response(conn, 400, %{message: message})
    end
  end

  post "/ft/profile/:username/workout/active/skip" do
    case Workout.skip_exercise(username) do
      {:ok, workout} ->
        send_json_response(conn, 200, %{message: "Exercise skipped", workout: workout})

      {:error, :no_active_workout} ->
        send_json_response(conn, 404, %{message: "No active workout found"})

      {:error, message} ->
        send_json_response(conn, 400, %{message: message})
    end
  end

  put "/ft/profile/:username/workout/active/set/rpe" do
    case Workout.update_set_rpe(username, conn.body_params) do
      {:ok, workout} -> send_json_response(conn, 200, %{workout: workout})
      {:error, message} -> send_json_response(conn, 400, %{message: message})
    end
  end

  # Stats & History
  get "/ft/profile/:username/workout/history" do
    case Workout.get_history(username) do
      {:ok, history} -> send_json_response(conn, 200, %{history: history})
      {:error, message} -> send_json_response(conn, 404, %{message: message})
    end
  end

  put "/ft/profile/:username/workout/active/exercise/targets" do
    case Workout.update_exercise_targets(username, conn.body_params) do
      {:ok, workout} -> send_json_response(conn, 200, %{workout: workout})
      {:error, message} -> send_json_response(conn, 400, %{message: message})
    end
  end

  # Create meal
  post "/ft/profile/:username/meal" do
    case Meal.create(username, conn.body_params) do
      {:ok, _meal} ->
        send_json_response(conn, 201, %{message: "Meal added successfully"})

      {:error, :profile_not_found} ->
        send_json_response(conn, 404, %{message: "Profile not found"})

      {:error, :meal_exists} ->
        send_json_response(conn, 409, %{message: "Meal already exists for this date"})

      {:error, message} ->
        send_json_response(conn, 400, %{message: message})
    end
  end

  # Create meal template
  post "/ft/profile/:username/meal/template" do
    case Meal.create_template(username, conn.body_params) do
      {:ok, template} ->
        send_json_response(conn, 201, %{
          message: "Meal template created successfully",
          template: template
        })

      {:error, message} ->
        send_json_response(conn, 400, %{message: message})
    end
  end

  # Get meal templates
  get "/ft/profile/:username/meal/templates" do
    case Meal.get_templates(username) do
      {:ok, templates} -> send_json_response(conn, 200, %{templates: templates})
      {:error, message} -> send_json_response(conn, 400, %{message: message})
    end
  end

  # Toggle favorite meal
  post "/ft/profile/:username/meal/:meal_name/:date/favorite" do
    case Meal.toggle_favorite(username, meal_name, date) do
      {:ok, meal} ->
        send_json_response(conn, 200, %{message: "Favorite status updated", meal: meal})

      {:error, message} ->
        send_json_response(conn, 400, %{message: message})
    end
  end

  # Get favorite meals
  get "/ft/profile/:username/meal/favorites" do
    case Meal.get_favorites(username) do
      {:ok, meals} -> send_json_response(conn, 200, %{meals: meals})
      {:error, message} -> send_json_response(conn, 400, %{message: message})
    end
  end

  # Set recurring meal
  post "/ft/profile/:username/meal/:meal_name/:date/recurring" do
    case Meal.set_recurring(username, meal_name, date, conn.body_params["schedule"]) do
      {:ok, meal} ->
        send_json_response(conn, 200, %{message: "Recurring schedule set", meal: meal})

      {:error, message} ->
        send_json_response(conn, 400, %{message: message})
    end
  end

  # Get recurring meals
  get "/ft/profile/:username/meal/recurring" do
    case Meal.get_recurring(username) do
      {:ok, meals} -> send_json_response(conn, 200, %{meals: meals})
      {:error, message} -> send_json_response(conn, 400, %{message: message})
    end
  end

  # Toggle quick access meal
  post "/ft/profile/:username/meal/:meal_name/:date/quick-access" do
    case Meal.toggle_quick_access(username, meal_name, date) do
      {:ok, meal} ->
        send_json_response(conn, 200, %{message: "Quick access status updated", meal: meal})

      {:error, message} ->
        send_json_response(conn, 400, %{message: message})
    end
  end

  # Get quick access meals
  get "/ft/profile/:username/meal/quick-access" do
    case Meal.get_quick_access(username) do
      {:ok, meals} -> send_json_response(conn, 200, %{meals: meals})
      {:error, message} -> send_json_response(conn, 400, %{message: message})
    end
  end

  # Regular meal CRUD operations
  get "/ft/profile/:username/meal" do
    case Meal.get_all(username) do
      {:ok, meals} ->
        send_json_response(conn, 200, %{meals: meals})

      {:error, :profile_not_found} ->
        send_json_response(conn, 404, %{message: "Profile not found"})

      {:error, :meal_log_not_found} ->
        send_json_response(conn, 500, %{message: "Error retrieving meal log"})
    end
  end

  get "/ft/profile/:username/meal/:meal_name/:date" do
    case Meal.get(username, meal_name, date) do
      {:ok, meal} ->
        send_json_response(conn, 200, meal)

      {:error, :profile_not_found} ->
        send_json_response(conn, 404, %{message: "Profile not found"})

      {:error, :not_found} ->
        send_json_response(conn, 404, %{message: "Meal not found"})
    end
  end

  # Get nutrition goals
  get "/ft/profile/:username/nutrition/goals" do
    case Profile.get_nutrition_goals(username) do
      {:ok, goals} -> send_json_response(conn, 200, goals)
      {:error, message} -> send_json_response(conn, 400, %{message: message})
    end
  end

  get "/ft/profile/:username/nutrition/daily/:date" do
    case Meal.get_daily_totals(username, date) do
      {:ok, totals} -> send_json_response(conn, 200, totals)
      {:error, message} -> send_json_response(conn, 400, %{message: message})
    end
  end

  # Update nutrition goals
  put "/ft/profile/:username/nutrition/goals" do
    case Profile.update_nutrition_goals(username, conn.body_params) do
      {:ok, goals} ->
        send_json_response(conn, 200, %{message: "Goals updated successfully", goals: goals})

      {:error, message} ->
        send_json_response(conn, 400, %{message: message})
    end
  end

  put "/ft/profile/:username/meal/:meal_name/:date" do
    case Meal.update(username, meal_name, date, conn.body_params) do
      {:ok, _meal} ->
        send_json_response(conn, 200, %{message: "Meal updated successfully"})

      {:error, :profile_not_found} ->
        send_json_response(conn, 404, %{message: "Profile not found"})

      {:error, message} ->
        send_json_response(conn, 400, %{message: "Invalid meal parameters: #{message}"})
    end
  end

  delete "/ft/profile/:username/meal/:meal_name/:date" do
    case Meal.delete(username, meal_name, date) do
      :ok ->
        send_json_response(conn, 200, %{message: "Meal deleted successfully"})

      {:error, :not_found} ->
        send_json_response(conn, 404, %{message: "Meal not found"})

      {:error, error} ->
        send_json_response(conn, 500, %{message: "Failed to delete meal: #{inspect(error)}"})
    end
  end

  delete "/ft/profile/:username/meal/all" do
    case Meal.clear_log(username) do
      :ok ->
        send_json_response(conn, 200, %{message: "Meal log cleared successfully"})

      {:error, :profile_not_found} ->
        send_json_response(conn, 404, %{message: "Profile not found"})

      {:error, error} ->
        send_json_response(conn, 500, %{message: "Failed to clear meal log: #{inspect(error)}"})
    end
  end

  # ----------------------
  # Catch-all Route
  # ----------------------
  match _ do
    send_resp(conn, 404, "Not found")
  end

  # ----------------------
  # Helper Functions
  # ----------------------

  defp parse_rest_time(%{"rest_time" => time}) when is_binary(time) do
    case Integer.parse(time) do
      {num, ""} when num > 0 -> {:ok, num}
      _ -> :error
    end
  end

  defp parse_rest_time(%{"rest_time" => time}) when is_number(time) and time > 0, do: {:ok, time}
  defp parse_rest_time(_), do: :error

  # Update send_json_response function:
  defp send_json_response(conn, status, body) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, Jason.encode!(body))
  end
end
