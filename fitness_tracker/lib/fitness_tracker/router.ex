alias FitnessTracker.Schemas.Profile

defmodule FitnessTracker.Router do
  use Plug.Router
  alias FitnessTracker.Schemas.{Profile, Workout, Exercise, Set, Ingredient, Meal}
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
        # Check if profile already exists
        case Mongo.find_one(:mongo, "profiles", %{username: profile.username}) do
          # if username doesn't exist, insert profile
          nil ->
            case Mongo.insert_one(:mongo, "profiles", Profile.to_json(profile)) do
              {:ok, _} ->
                send_resp(conn, 201, Jason.encode!(%{message: "Profile created successfully"}))

              {:error, error} ->
                send_resp(conn, 500, "Failed to create profile: #{inspect(error)}")
            end

          # if username exists, send 400 response
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

  # Enhanced post workout endpoint with better validation
  post "/ft/profile/:username/workout" do
    with {:ok, workout_params} <- Map.fetch(conn.body_params, "workout"),
         # Validate exercises and sets exist
         true <- is_list(workout_params["exercises"]) || {:error, "exercises must be a list"},
         exercises <-
           Enum.map(workout_params["exercises"], fn exercise_params ->
             case exercise_params do
               %{"sets" => sets, "exercise_name" => _name} when is_list(sets) ->
                 sets = Enum.map(exercise_params["sets"], &Set.new/1)

                 {:ok, exercise} =
                   Exercise.new(%{sets: sets, exercise_name: exercise_params["exercise_name"]})

                 exercise

               _ ->
                 {:error, "each exercise must have sets and exercise_name"}
             end
           end),
         false <- Enum.any?(exercises, &match?({:error, _}, &1)),
         # Validate required workout fields
         true <-
           is_binary(workout_params["workout_name"]) || {:error, "workout_name is required"},
         true <-
           is_number(workout_params["length_of_workout"]) ||
             {:error, "length_of_workout must be a number"},
         true <-
           is_binary(workout_params["date_worked_out"]) || {:error, "date_worked_out is required"},
         {:ok, workout} <-
           Workout.new(%{
             exercises: exercises,
             workout_name: workout_params["workout_name"],
             length_of_workout: workout_params["length_of_workout"],
             date_worked_out: workout_params["date_worked_out"]
           }),
         profile when not is_nil(profile) <-
           Mongo.find_one(:mongo, "profiles", %{username: username}),
         # Check if workout already exists for this date
         nil <-
           Enum.find(profile["workout_log"] || [], fn existing ->
             existing["workout_name"] == workout_params["workout_name"] &&
               existing["date_worked_out"] == workout_params["date_worked_out"]
           end),
         {:ok, _} <-
           Mongo.update_one(:mongo, "profiles", %{username: username}, %{
             "$push": %{"workout_log" => Workout.to_json(workout)}
           }) do
      send_resp(conn, 201, Jason.encode!(%{message: "Workout added successfully"}))
    else
      {:error, message} when is_binary(message) ->
        send_resp(conn, 400, message)

      nil ->
        send_resp(conn, 404, "Profile not found")

      {:error, _} ->
        send_resp(conn, 400, "Invalid workout parameters")

      _ ->
        send_resp(conn, 409, "Workout already exists for this date")
    end
  end

  # Enhanced post meal endpoint with better validation
  post "/ft/profile/:username/meal" do
    with {:ok, meal_params} <- Map.fetch(conn.body_params, "meal"),
         # Validate required meal fields
         true <- is_binary(meal_params["meal_name"]) || {:error, "meal_name is required"},
         true <- is_number(meal_params["calories"]) || {:error, "calories must be a number"},
         true <- is_number(meal_params["protein"]) || {:error, "protein must be a number"},
         true <- is_number(meal_params["carbs"]) || {:error, "carbs must be a number"},
         true <- is_number(meal_params["fat"]) || {:error, "fat must be a number"},
         true <- is_binary(meal_params["date_eaten"]) || {:error, "date_eaten is required"},
         true <- is_list(meal_params["ingredients"]) || {:error, "ingredients must be a list"},

         # Enhanced ingredient validation
         {:ok, ingredients} <- validate_ingredients(meal_params["ingredients"]),
         {:ok, meal} <-
           Meal.new(%{
             meal_name: meal_params["meal_name"],
             calories: meal_params["calories"],
             protein: meal_params["protein"],
             carbs: meal_params["carbs"],
             fat: meal_params["fat"],
             ingredients: ingredients,
             date_eaten: meal_params["date_eaten"]
           }),
         profile when not is_nil(profile) <-
           Mongo.find_one(:mongo, "profiles", %{username: username}),
         # Check if meal already exists for this date
         nil <-
           Enum.find(profile["meal_log"] || [], fn existing ->
             existing["meal_name"] == meal_params["meal_name"] &&
               existing["date_eaten"] == meal_params["date_eaten"]
           end),
         {:ok, _} <-
           Mongo.update_one(:mongo, "profiles", %{username: username}, %{
             "$push": %{"meal_log" => Meal.to_json(meal)}
           }) do
      send_resp(conn, 201, Jason.encode!(%{message: "Meal added successfully"}))
    else
      {:error, message} when is_binary(message) ->
        send_resp(conn, 400, message)

      nil ->
        send_resp(conn, 404, "Profile not found")

      {:error, _} ->
        send_resp(conn, 400, "Invalid meal parameters")

      _ ->
        send_resp(conn, 409, "Meal already exists for this date")
    end
  end

  # Add this helper function
  defp validate_ingredients(ingredients) when is_list(ingredients) do
    results =
      Enum.map(ingredients, fn ingredient ->
        case ingredient do
          %{"name" => name} when is_binary(name) and name != "" ->
            FitnessTracker.Schemas.Ingredient.new(ingredient)

          _ ->
            {:error, "each ingredient must have a valid name"}
        end
      end)

    case Enum.find(results, &match?({:error, _}, &1)) do
      nil -> {:ok, results}
      {:error, message} -> {:error, message}
    end
  end

  defp validate_ingredients(_), do: {:error, "ingredients must be a list"}

  delete "/ft/profile/:username/workout/:workout_name/:date" do
    case Mongo.update_one(:mongo, "profiles", %{username: username}, %{
           "$pull": %{
             workout_log: %{
               workout_name: workout_name,
               date_worked_out: date
             }
           }
         }) do
      {:ok, %{modified_count: 1}} ->
        send_resp(conn, 200, Jason.encode!(%{message: "Workout deleted successfully"}))

      {:ok, %{modified_count: 0}} ->
        send_resp(conn, 404, "Workout not found")

      {:error, error} ->
        send_resp(conn, 500, "Failed to delete workout: #{inspect(error)}")
    end
  end

  # Update or create a workout
  put "/ft/profile/:username/workout/:workout_name/:date" do
    with {:ok, workout_params} <- Map.fetch(conn.body_params, "workout"),
         exercises <-
           Enum.map(workout_params["exercises"], fn exercise_params ->
             sets = Enum.map(exercise_params["sets"], &Set.new/1)

             {:ok, exercise} =
               Exercise.new(%{sets: sets, exercise_name: exercise_params["exercise_name"]})

             exercise
           end),
         {:ok, updated_workout} <-
           Workout.new(%{
             exercises: exercises,
             workout_name: workout_params["workout_name"],
             length_of_workout: workout_params["length_of_workout"],
             date_worked_out: workout_params["date_worked_out"]
           }) do
      # First try to update
      case Mongo.update_one(
             :mongo,
             "profiles",
             %{
               username: username,
               workout_log: %{
                 "$elemMatch": %{
                   workout_name: workout_name,
                   date_worked_out: date
                 }
               }
             },
             %{
               "$set": %{
                 "workout_log.$": Workout.to_json(updated_workout)
               }
             }
           ) do
        {:ok, %{modified_count: 1}} ->
          send_resp(conn, 200, Jason.encode!(%{message: "Workout updated successfully"}))

        # If not found, try to create new
        {:ok, %{modified_count: 0}} ->
          case Mongo.update_one(:mongo, "profiles", %{username: username}, %{
                 "$push": %{
                   workout_log: Workout.to_json(updated_workout)
                 }
               }) do
            {:ok, %{modified_count: 1}} ->
              send_resp(conn, 201, Jason.encode!(%{message: "Workout created successfully"}))

            {:error, error} ->
              send_resp(conn, 500, "Failed to create workout: #{inspect(error)}")
          end

        {:error, error} ->
          send_resp(conn, 500, "Failed to update workout: #{inspect(error)}")
      end
    else
      error -> send_resp(conn, 400, "Invalid workout parameters: #{inspect(error)}")
    end
  end

  # Update or create a meal
  put "/ft/profile/:username/meal/:meal_name/:date" do
    with {:ok, meal_params} <- Map.fetch(conn.body_params, "meal"),
         ingredients <-
           Enum.map(meal_params["ingredients"], &Ingredient.new/1),
         {:ok, updated_meal} <-
           Meal.new(%{
             meal_name: meal_params["meal_name"],
             calories: meal_params["calories"],
             protein: meal_params["protein"],
             carbs: meal_params["carbs"],
             fat: meal_params["fat"],
             ingredients: ingredients,
             date_eaten: meal_params["date_eaten"]
           }) do
      # First try to update
      case Mongo.update_one(
             :mongo,
             "profiles",
             %{
               username: username,
               meal_log: %{
                 "$elemMatch": %{
                   meal_name: meal_name,
                   date_eaten: date
                 }
               }
             },
             %{
               "$set": %{
                 "meal_log.$": Meal.to_json(updated_meal)
               }
             }
           ) do
        {:ok, %{modified_count: 1}} ->
          send_resp(conn, 200, Jason.encode!(%{message: "Meal updated successfully"}))

        # If not found, try to create new
        {:ok, %{modified_count: 0}} ->
          case Mongo.update_one(:mongo, "profiles", %{username: username}, %{
                 "$push": %{
                   meal_log: Meal.to_json(updated_meal)
                 }
               }) do
            {:ok, %{modified_count: 1}} ->
              send_resp(conn, 201, Jason.encode!(%{message: "Meal created successfully"}))

            {:error, error} ->
              send_resp(conn, 500, "Failed to create meal: #{inspect(error)}")
          end

        {:error, error} ->
          send_resp(conn, 500, "Failed to update meal: #{inspect(error)}")
      end
    else
      error -> send_resp(conn, 400, "Invalid meal parameters: #{inspect(error)}")
    end
  end

  delete "/ft/profile/:username/meal/:meal_name/:date" do
    case Mongo.update_one(:mongo, "profiles", %{username: username}, %{
           "$pull": %{
             meal_log: %{
               meal_name: meal_name,
               date_eaten: date
             }
           }
         }) do
      {:ok, %{modified_count: 1}} ->
        send_resp(conn, 200, Jason.encode!(%{message: "Meal deleted successfully"}))

      {:ok, %{modified_count: 0}} ->
        send_resp(conn, 404, "Meal not found")

      {:error, error} ->
        send_resp(conn, 500, "Failed to delete meal: #{inspect(error)}")
    end
  end

  # Get all workouts for a user
  get "/ft/profile/:username/workout" do
    case Mongo.find_one(:mongo, "profiles", %{username: username}) do
      nil ->
        send_resp(conn, 404, "Profile not found")

      profile ->
        case Map.get(profile, "workout_log", []) do
          workout_log when is_list(workout_log) ->
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(200, Jason.encode!(%{workouts: workout_log}))

          _ ->
            send_resp(conn, 500, "Error retrieving workout log")
        end
    end
  end

  # Get specific workout by name and date
  get "/ft/profile/:username/workout/:workout_name/:date" do
    case Mongo.find_one(:mongo, "profiles", %{username: username}) do
      nil ->
        send_resp(conn, 404, "Profile not found")

      profile ->
        workout =
          profile
          |> Map.get("workout_log", [])
          |> Enum.find(fn workout ->
            workout["workout_name"] == workout_name &&
              workout["date_worked_out"] == date
          end)

        case workout do
          nil ->
            send_resp(conn, 404, "Workout not found")

          workout ->
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(200, Jason.encode!(workout))
        end
    end
  end

  # Get all meals for a user
  get "/ft/profile/:username/meal" do
    case Mongo.find_one(:mongo, "profiles", %{username: username}) do
      nil ->
        send_resp(conn, 404, "Profile not found")

      profile ->
        case Map.get(profile, "meal_log", []) do
          meal_log when is_list(meal_log) ->
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(200, Jason.encode!(%{meals: meal_log}))

          _ ->
            send_resp(conn, 500, "Error retrieving meal log")
        end
    end
  end

  # Get specific meal by name and date
  get "/ft/profile/:username/meal/:meal_name/:date" do
    case Mongo.find_one(:mongo, "profiles", %{username: username}) do
      nil ->
        send_resp(conn, 404, "Profile not found")

      profile ->
        meal =
          profile
          |> Map.get("meal_log", [])
          |> Enum.find(fn meal ->
            meal["meal_name"] == meal_name &&
              meal["date_eaten"] == date
          end)

        case meal do
          nil ->
            send_resp(conn, 404, "Meal not found")

          meal ->
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(200, Jason.encode!(meal))
        end
    end
  end

  # Delete entire workout log
  delete "/ft/profile/:username/workout/all" do
    case Mongo.update_one(:mongo, "profiles", %{username: username}, %{
           "$set": %{
             workout_log: []
           }
         }) do
      {:ok, %{modified_count: 1}} ->
        send_resp(conn, 200, Jason.encode!(%{message: "Workout log cleared successfully"}))

      {:ok, %{modified_count: 0}} ->
        send_resp(conn, 404, "Profile not found")

      {:error, error} ->
        send_resp(conn, 500, "Failed to clear workout log: #{inspect(error)}")
    end
  end

  # Delete entire meal log
  delete "/ft/profile/:username/meal/all" do
    case Mongo.update_one(:mongo, "profiles", %{username: username}, %{
           "$set": %{
             meal_log: []
           }
         }) do
      {:ok, %{modified_count: 1}} ->
        send_resp(conn, 200, Jason.encode!(%{message: "Meal log cleared successfully"}))

      {:ok, %{modified_count: 0}} ->
        send_resp(conn, 404, "Profile not found")

      {:error, error} ->
        send_resp(conn, 500, "Failed to clear meal log: #{inspect(error)}")
    end
  end

  match _ do
    send_resp(conn, 404, "Not found")
  end
end
