defmodule FitnessTracker.Schemas.Meal do
  use FitnessTracker.Schemas.BaseLog,
    log_type: "meal_log",
    name_field: "name",
    date_field: "date"

  alias FitnessTracker.Schemas.Ingredient
  @derive Jason.Encoder
  defstruct [
    :name,
    :date,
    # New: Time the meal was eaten
    :time_eaten,
    # New: breakfast/lunch/dinner/snack
    :meal_type,
    :calories,
    :protein,
    :carbs,
    :fat,
    :ingredients,
    # New: Marked as favorite
    :is_favorite,
    # New: Part of recurring meals
    :is_recurring,
    # New: Shows in quick access
    :is_quick_access,
    # New: If saved as template
    :template_name,
    # New: Any notes about the meal
    :notes,
    # New: For recurring meals (e.g., "Weekdays, 8:00 AM")
    :schedule
  ]

  def new(attrs), do: {:ok, struct(__MODULE__, attrs)}

  def create(username, attrs) do
    with {:ok, meal_params} <- extract_meal_params(attrs),
         {:ok, ingredients} <- validate_ingredients(meal_params["ingredients"]),
         {:ok, meal} <- build_meal(meal_params, ingredients),
         :ok <- validate_unique_meal(username, meal_params),
         {:ok, _} <- save_meal(username, meal) do
      {:ok, meal}
    end
  end

  def create_template(username, attrs) do
    with {:ok, meal} <- create(username, attrs),
         :ok <- save_as_template(username, meal) do
      {:ok, meal}
    end
  end

  # In Meal.ex
  def get_templates(username) do
    case get_profile(username) do
      {:ok, profile} -> {:ok, profile["meal_templates"] || []}
      error -> error
    end
  end

  def toggle_favorite(username, meal_name, date) do
    with {:ok, _profile} <- get_profile(username),
         {:ok, meal} <- get(username, meal_name, date) do
      updated_meal = %{meal | is_favorite: !meal.is_favorite}

      case update_meal(username, meal_name, date, to_json(updated_meal)) do
        {:ok, _} -> {:ok, updated_meal}
        error -> error
      end
    end
  end

  def set_recurring(username, meal_name, date, schedule) do
    with {:ok, _profile} <- get_profile(username),
         {:ok, meal} <- get(username, meal_name, date) do
      updated_meal = %{meal | is_recurring: true, schedule: schedule}

      case update_meal(username, meal_name, date, to_json(updated_meal)) do
        {:ok, _} -> {:ok, updated_meal}
        error -> error
      end
    end
  end

  def toggle_quick_access(username, meal_name, date) do
    with {:ok, _profile} <- get_profile(username),
         {:ok, meal} <- get(username, meal_name, date) do
      updated_meal = %{meal | is_quick_access: !meal.is_quick_access}

      case update_meal(username, meal_name, date, to_json(updated_meal)) do
        {:ok, _} -> {:ok, updated_meal}
        error -> error
      end
    end
  end

  def get_favorites(username) do
    with {:ok, meals} <- get_all(username) do
      {:ok, Enum.filter(meals, & &1.is_favorite)}
    end
  end

  def get_quick_access(username) do
    with {:ok, meals} <- get_all(username) do
      {:ok, Enum.filter(meals, & &1.is_quick_access)}
    end
  end

  def get_recurring(username) do
    with {:ok, meals} <- get_all(username) do
      {:ok, Enum.filter(meals, & &1.is_recurring)}
    end
  end

  def update(username, meal_name, date, attrs) do
    with {:ok, meal_params} <- extract_meal_params(attrs),
         {:ok, ingredients} <- validate_ingredients(meal_params["ingredients"]),
         {:ok, updated_meal} <- build_meal(meal_params, ingredients),
         {:ok, profile} <- get_profile(username) do
      update_existing_or_create(username, profile, meal_name, date, updated_meal, attrs)
    end
  end

  # Private functions specific to Meal
  defp extract_meal_params(attrs) do
    case Map.fetch(attrs, "meal") do
      {:ok, params} -> {:ok, params}
      :error -> {:error, "Missing meal parameters"}
    end
  end

  defp validate_ingredients(ingredients) when is_list(ingredients) do
    results = Enum.map(ingredients, &parse_ingredient/1)

    case Enum.find(results, &match?({:error, _}, &1)) do
      nil -> {:ok, Enum.map(results, fn {:ok, ingredient} -> ingredient end)}
      {:error, message} -> {:error, message}
    end
  end

  defp validate_ingredients(_), do: {:error, "ingredients must be a list"}

  defp parse_ingredient(ingredient) do
    case ingredient do
      %{"name" => name} when is_binary(name) and name != "" ->
        {:ok, Ingredient.new(ingredient)}

      _ ->
        {:error, "each ingredient must have a valid name"}
    end
  end

  defp build_meal(params, ingredients) do
    with true <- is_binary(params["name"]) || {:error, "name is required"},
         true <- is_binary(params["meal_type"]) || {:error, "meal_type is required"},
         # Make time_eaten optional for templates
         true <- !params["time_eaten"] || is_binary(params["time_eaten"]),
         true <- is_number(params["calories"]) || {:error, "calories must be a number"},
         true <- is_number(params["protein"]) || {:error, "protein must be a number"},
         true <- is_number(params["carbs"]) || {:error, "carbs must be a number"},
         true <- is_number(params["fat"]) || {:error, "fat must be a number"} do
      new(%{
        name: params["name"],
        date: params["date"],
        time_eaten: params["time_eaten"],
        meal_type: params["meal_type"],
        calories: params["calories"],
        protein: params["protein"],
        carbs: params["carbs"],
        fat: params["fat"],
        ingredients: ingredients,
        is_favorite: params["is_favorite"] || false,
        is_recurring: params["is_recurring"] || false,
        is_quick_access: params["is_quick_access"] || false,
        template_name: params["template_name"],
        notes: params["notes"],
        schedule: params["schedule"]
      })
    end
  end

  defp save_as_template(username, meal) do
    case get_profile(username) do
      {:ok, _profile} ->
        template = Map.put(meal, :template_name, meal.name)

        Mongo.update_one(:mongo, "profiles", %{username: username}, %{
          "$push": %{meal_templates: to_json(template)}
        })

      error ->
        error
    end
  end

  defp validate_unique_meal(username, meal_params) do
    case get_profile(username) do
      {:ok, profile} ->
        case Enum.find(profile["meal_log"] || [], &matching_meal?(&1, meal_params)) do
          nil -> :ok
          _ -> {:error, :meal_exists}
        end

      error ->
        error
    end
  end

  defp matching_meal?(meal, meal_params) do
    matches_criteria?(meal, meal_params["name"], meal_params["date"])
  end

  defp save_meal(username, meal) do
    Mongo.update_one(:mongo, "profiles", %{username: username}, %{
      "$push": %{meal_log: to_json(meal)}
    })
  end

  defp update_existing_or_create(username, profile, meal_name, date, updated_meal, attrs) do
    if has_meal?(profile["meal_log"], meal_name, date) do
      update_meal(username, meal_name, date, to_json(updated_meal))
    else
      create(username, attrs)
    end
  end

  defp has_meal?(meal_log, meal_name, date) do
    meal_log |> find_item(meal_name, date) |> is_map()
  end

  defp update_meal(username, meal_name, date, updated_meal) do
    Mongo.update_one(
      :mongo,
      "profiles",
      %{
        username: username,
        meal_log: %{
          "$elemMatch": %{
            name: meal_name,
            date: date
          }
        }
      },
      %{
        "$set": %{
          "meal_log.$": updated_meal
        }
      }
    )
  end

  # Add these functions to your Meal module:

  def get_daily_totals(username, date) do
    with {:ok, meals} <- get_all(username) do
      daily_meals = Enum.filter(meals, &(&1.date == date))

      totals =
        Enum.reduce(
          daily_meals,
          %{
            calories: 0,
            protein: 0,
            carbs: 0,
            fat: 0,
            meals: []
          },
          fn meal, acc ->
            %{
              calories: acc.calories + meal.calories,
              protein: acc.protein + meal.protein,
              carbs: acc.carbs + meal.carbs,
              fat: acc.fat + meal.fat,
              meals: [meal_summary(meal) | acc.meals]
            }
          end
        )

      {:ok, %{totals | meals: Enum.reverse(totals.meals)}}
    end
  end

  # Fix JSON handling to include all fields
  def to_json(%__MODULE__{} = meal) do
    %{
      name: meal.name,
      date: meal.date,
      time_eaten: meal.time_eaten,
      meal_type: meal.meal_type,
      calories: meal.calories,
      protein: meal.protein,
      carbs: meal.carbs,
      fat: meal.fat,
      ingredients: Enum.map(meal.ingredients, &Ingredient.to_json/1),
      is_favorite: meal.is_favorite,
      is_recurring: meal.is_recurring,
      is_quick_access: meal.is_quick_access,
      template_name: meal.template_name,
      notes: meal.notes,
      schedule: meal.schedule
    }
  end

  def from_json(json) when is_map(json) do
    %__MODULE__{
      name: json["name"],
      date: json["date"],
      time_eaten: json["time_eaten"],
      meal_type: json["meal_type"],
      calories: json["calories"],
      protein: json["protein"],
      carbs: json["carbs"],
      fat: json["fat"],
      ingredients: Enum.map(json["ingredients"] || [], &Ingredient.from_json/1),
      is_favorite: json["is_favorite"],
      is_recurring: json["is_recurring"],
      is_quick_access: json["is_quick_access"],
      template_name: json["template_name"],
      notes: json["notes"],
      schedule: json["schedule"]
    }
  end

  # Add these private helper functions:

  defp meal_summary(meal) do
    %{
      name: meal.name,
      time: meal.time_eaten,
      type: meal.meal_type,
      calories: meal.calories,
      macros: %{
        protein: meal.protein,
        carbs: meal.carbs,
        fat: meal.fat
      },
      ingredients: Enum.map(meal.ingredients, & &1.name)
    }
  end
end
