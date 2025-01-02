defmodule FitnessTracker.Schemas.Profile do
  @moduledoc """
  Schema and functions for handling user profiles, including authentication,
  nutrition goals, templates, and profile settings.
  """

  @derive Jason.Encoder
  defstruct [
    :first_name,
    :last_name,
    :username,
    :password,
    :date_of_birth,
    :height,
    :weight,
    :date_account_created,
    # Daily nutrition targets
    :nutrition_goals,
    # Saved workout templates
    :workout_templates,
    # Saved meal templates
    :meal_templates,
    # Favorite meals
    :favorite_meals,
    # Scheduled recurring meals
    :recurring_meals,
    # Quick access meals
    :quick_access_meals,
    # Currently active workout
    :active_workout,
    workout_log: [],
    meal_log: []
  ]

  # ----------------------
  # Core Profile Functions
  # ----------------------

  def new(attrs) do
    attrs =
      Map.new(attrs, fn
        {key, value} when is_binary(key) -> {String.to_atom(key), value}
        {key, value} when is_atom(key) -> {key, value}
      end)

    case validate_profile(attrs) do
      {:ok, valid_attrs} ->
        {:ok,
         struct(
           __MODULE__,
           Map.merge(valid_attrs, %{
             date_account_created: DateTime.utc_now(),
             nutrition_goals: default_nutrition_goals(),
             workout_templates: [],
             meal_templates: [],
             favorite_meals: [],
             recurring_meals: [],
             quick_access_meals: [],
             active_workout: nil,
             workout_log: [],
             meal_log: []
           })
         )}

      error ->
        error
    end
  end

  def create(attrs) do
    IO.inspect(attrs, label: "Received attributes")

    case new(attrs) do
      {:ok, profile} ->
        IO.inspect(profile, label: "Created profile struct")

        case Mongo.find_one(:mongo, "profiles", %{username: profile.username}) do
          nil ->
            IO.inspect("Inserting new profile")

            case Mongo.insert_one(:mongo, "profiles", to_json(profile)) do
              {:ok, result} ->
                IO.inspect(result, label: "Insertion result")
                {:ok, profile}

              {:error, error} ->
                IO.inspect(error, label: "Insertion error")
                {:error, error}
            end

          _ ->
            IO.inspect("Username already exists")
            {:error, :username_exists}
        end

      {:error, message} ->
        IO.inspect(message, label: "Error creating profile struct")
        {:error, message}
    end
  end

  def get_all do
    case Mongo.find(:mongo, "profiles", %{}) |> Enum.to_list() do
      profiles when is_list(profiles) ->
        Enum.map(profiles, fn profile ->
          profile |> Map.drop(["_id", "password"]) |> from_json()
        end)

      _ ->
        {:error, :retrieval_failed}
    end
  end

  def get_by_username(username) do
    case Mongo.find_one(:mongo, "profiles", %{username: username}) do
      nil -> {:error, :not_found}
      profile -> {:ok, profile |> Map.drop(["_id", "password"]) |> from_json()}
    end
  end

  def update(username, attrs) do
    case Mongo.find_one(:mongo, "profiles", %{username: username}) do
      nil ->
        {:error, :not_found}

      existing_profile ->
        # Convert the MongoDB document to a Profile struct
        existing_struct = from_json(existing_profile)

        # Convert incoming attributes and merge them
        attrs_with_atoms = Map.new(attrs, fn {k, v} -> {String.to_atom(k), v} end)
        updated_struct = Map.merge(existing_struct, attrs_with_atoms)

        # Convert back to JSON for MongoDB
        updated_json = to_json(updated_struct)

        case Mongo.update_one(:mongo, "profiles", %{username: username}, %{"$set": updated_json}) do
          {:ok, _} -> {:ok, updated_struct}
          {:error, error} -> {:error, error}
        end
    end
  end

  def delete(username) do
    case Mongo.delete_one(:mongo, "profiles", %{username: username}) do
      {:ok, %{deleted_count: 1}} -> :ok
      {:ok, %{deleted_count: 0}} -> {:error, :not_found}
      {:error, error} -> {:error, error}
    end
  end

  # ----------------------
  # Authentication
  # ----------------------

  def authenticate(username, password) do
    case Mongo.find_one(:mongo, "profiles", %{username: username}) do
      nil ->
        {:error, :not_found}

      profile ->
        case profile["password"] do
          ^password -> {:ok, profile |> Map.drop(["_id", "password"]) |> from_json()}
          _ -> {:error, :invalid_credentials}
        end
    end
  end

  # ----------------------
  # Nutrition Goals
  # ----------------------

  def get_nutrition_goals(username) do
    case Mongo.find_one(:mongo, "profiles", %{username: username}) do
      nil ->
        {:error, :not_found}

      profile ->
        case profile["nutrition_goals"] do
          nil -> {:ok, default_nutrition_goals()}
          goals -> {:ok, goals}
        end
    end
  end

  def update_nutrition_goals(username, new_goals) do
    # Fetch the profile
    case get_by_username(username) do
      {:ok, profile} ->
        existing_goals = profile.nutrition_goals || default_nutrition_goals()

        # Merge existing goals with new ones
        updated_goals = Map.merge(existing_goals, new_goals)

        # Validate the updated goals
        case validate_nutrition_goals(updated_goals) do
          true ->
            # Persist the updated goals
            result =
              Mongo.update_one(:mongo, "profiles", %{username: username}, %{
                "$set": %{nutrition_goals: updated_goals}
              })

            case result do
              {:ok, _} ->
                {:ok, updated_goals}

              {:error, error} ->
                nil
            end

          false ->
            {:error, "Invalid nutrition goals"}
        end

      {:error, :not_found} ->
        {:error, "Profile not found"}
    end
  end

  # ----------------------
  # Profile Stats & Settings
  # ----------------------

  def get_profile_stats(username) do
    case get_by_username(username) do
      {:ok, profile} ->
        {:ok,
         %{
           weight: profile.weight,
           height: profile.height,
           nutrition_goals: profile.nutrition_goals || default_nutrition_goals()
         }}

      error ->
        error
    end
  end

  def update_profile_stats(username, stats) do
    with {:ok, _} <- validate_measurements(stats),
         {:ok, _} <-
           Mongo.update_one(:mongo, "profiles", %{username: username}, %{
             "$set": %{
               weight: stats.weight,
               height: stats.height
             }
           }) do
      {:ok, stats}
    else
      error -> error
    end
  end

  def update_profile_settings(username, settings) do
    with {:ok, _profile} <- get_by_username(username),
         {:ok, updated_profile} <- validate_settings(settings),
         {:ok, _} <-
           Mongo.update_one(:mongo, "profiles", %{username: username}, %{"$set": updated_profile}) do
      {:ok, updated_profile}
    else
      error -> error
    end
  end

  # ----------------------
  # JSON Conversion
  # ----------------------

  def to_json(%__MODULE__{} = profile) do
    %{
      firstName: profile.first_name,
      lastName: profile.last_name,
      username: profile.username,
      password: profile.password,
      dateOfBirth: profile.date_of_birth,
      height: profile.height,
      weight: profile.weight,
      dateAccountCreated: profile.date_account_created,
      nutritionGoals: profile.nutrition_goals,
      workoutTemplates: profile.workout_templates,
      mealTemplates: profile.meal_templates,
      favoriteMeals: profile.favorite_meals,
      recurringMeals: profile.recurring_meals,
      quickAccessMeals: profile.quick_access_meals,
      activeWorkout: profile.active_workout,
      workoutLog: profile.workout_log,
      mealLog: profile.meal_log
    }
  end

  def from_json(json) when is_map(json) do
    %__MODULE__{
      first_name: json["firstName"],
      last_name: json["lastName"],
      username: json["username"],
      password: json["password"],
      date_of_birth: json["dateOfBirth"],
      height: json["height"],
      weight: json["weight"],
      date_account_created: json["dateAccountCreated"],
      nutrition_goals: json["nutritionGoals"],
      workout_templates: json["workoutTemplates"],
      meal_templates: json["mealTemplates"],
      favorite_meals: json["favoriteMeals"],
      recurring_meals: json["recurringMeals"],
      quick_access_meals: json["quickAccessMeals"],
      active_workout: json["activeWorkout"],
      workout_log: json["workoutLog"],
      meal_log: json["mealLog"]
    }
  end

  # ----------------------
  # Private Helper Functions
  # ----------------------

  defp default_nutrition_goals do
    %{
      calories: 2000,
      protein: 150,
      carbs: 200,
      fat: 65
    }
  end

  defp validate_profile(attrs) do
    with {:ok, _} <- validate_required_fields(attrs),
         {:ok, _} <- validate_measurements(attrs) do
      {:ok, attrs}
    end
  end

  defp validate_required_fields(attrs) do
    required_fields = [
      :first_name,
      :last_name,
      :username,
      :password,
      :date_of_birth,
      :height,
      :weight
    ]

    case Enum.filter(required_fields, &is_nil(Map.get(attrs, &1))) do
      [] -> {:ok, attrs}
      missing_fields -> {:error, "Missing required fields: #{inspect(missing_fields)}"}
    end
  end

  defp validate_measurements(%{height: height, weight: weight})
       when is_number(height) and height > 0 and
              is_number(weight) and weight > 0 do
    {:ok, %{height: height, weight: weight}}
  end

  defp validate_measurements(_), do: {:error, "Height and weight must be positive numbers"}

  defp validate_nutrition_goals(goals) do
    with true <- is_map(goals),
         true <- is_number(goals["calories"]),
         true <- is_number(goals["protein"]),
         true <- is_number(goals["carbs"]),
         true <- is_number(goals["fat"]) do
      true
    else
      _ -> false
    end
  end

  defp validate_settings(settings) do
    with true <- validate_optional_measurements(settings),
         true <- validate_optional_nutrition_goals(settings) do
      {:ok, settings}
    else
      {:error, message} -> {:error, message}
    end
  end

  defp validate_optional_measurements(%{height: height, weight: weight} = _settings)
       when is_number(height) and height > 0 and
              is_number(weight) and weight > 0 do
    true
  end

  defp validate_optional_measurements(_), do: true

  defp validate_optional_nutrition_goals(%{nutrition_goals: goals}) do
    validate_nutrition_goals(goals)
  end

  defp validate_optional_nutrition_goals(_), do: true
end
