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
    attrs = Enum.map(attrs, fn {k, v} -> {String.to_atom(k), v} end) |> Enum.into(%{})
    with {:ok, valid_attrs} <- validate_profile(attrs) do
      {:ok,
       struct(
         __MODULE__,
         Map.merge(attrs, %{
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
    end
  end

  def create(attrs) do
    case new(attrs) do
      {:ok, profile} ->
        case Mongo.find_one(:mongo, "profiles", %{username: profile.username}) do
          nil ->
            case Mongo.insert_one(:mongo, "profiles", to_json(profile)) do
              {:ok, _} -> {:ok, profile}
              {:error, error} -> {:error, error}
            end

          _ ->
            {:error, :username_exists}
        end

      {:error, message} ->
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
    with {:ok, profile} <- new(attrs),
         profile_json when not is_nil(profile_json) <-
           Mongo.find_one(:mongo, "profiles", %{username: username}),
         {:ok, _} <-
           Mongo.update_one(:mongo, "profiles", %{username: username}, %{"$set": to_json(profile)}) do
      {:ok, profile}
    else
      nil -> {:error, :not_found}
      {:error, message} -> {:error, message}
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

  def update_nutrition_goals(username, goals) do
    with true <- validate_nutrition_goals(goals),
         {:ok, _} <-
           Mongo.update_one(:mongo, "profiles", %{username: username}, %{
             "$set": %{nutrition_goals: goals}
           }) do
      {:ok, goals}
    else
      false -> {:error, "Invalid nutrition goals"}
      error -> error
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
    with {:ok, profile} <- get_by_username(username),
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
         true <- is_number(goals.calories) and goals.calories > 0,
         true <- is_number(goals.protein) and goals.protein > 0,
         true <- is_number(goals.carbs) and goals.carbs > 0,
         true <- is_number(goals.fat) and goals.fat > 0 do
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

  defp validate_optional_measurements(%{height: height, weight: weight} = settings)
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
