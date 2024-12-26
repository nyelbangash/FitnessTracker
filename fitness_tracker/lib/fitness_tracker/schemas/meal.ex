defmodule FitnessTracker.Schemas.Meal do
  alias FitnessTracker.Schemas.Ingredient
  @derive Jason.Encoder
  defstruct [:meal_name, :calories, :protein, :carbs, :fat, :ingredients, :date_eaten]

  def new(attrs) do
    attrs =
      Enum.map(attrs, fn
        {key, value} when is_atom(key) -> {key, value}
        {key, value} when is_binary(key) -> {String.to_atom(key), value}
      end)

    {:ok, struct(__MODULE__, attrs)}
  end

  def to_json(%__MODULE__{} = meal) do
    %{
      meal_name: meal.meal_name,
      calories: meal.calories,
      protein: meal.protein,
      carbs: meal.carbs,
      fat: meal.fat,
      ingredients: Enum.map(meal.ingredients, &Ingredient.to_json/1),
      date_eaten: meal.date_eaten
    }
  end

  def create(username, attrs) do
    with {:ok, meal_params} <- Map.fetch(attrs, "meal"),
         true <- is_binary(meal_params["meal_name"]) || {:error, "meal_name is required"},
         true <- is_number(meal_params["calories"]) || {:error, "calories must be a number"},
         true <- is_number(meal_params["protein"]) || {:error, "protein must be a number"},
         true <- is_number(meal_params["carbs"]) || {:error, "carbs must be a number"},
         true <- is_number(meal_params["fat"]) || {:error, "fat must be a number"},
         true <- is_binary(meal_params["date_eaten"]) || {:error, "date_eaten is required"},
         true <- is_list(meal_params["ingredients"]) || {:error, "ingredients must be a list"},
         {:ok, ingredients} <- validate_ingredients(meal_params["ingredients"]),
         {:ok, meal} <-
           new(%{
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
         nil <- Enum.find(profile["meal_log"] || [], &matching_meal?(&1, meal_params)),
         {:ok, _} <-
           Mongo.update_one(:mongo, "profiles", %{username: username}, %{
             "$push": %{"meal_log" => to_json(meal)}
           }) do
      {:ok, meal}
    else
      {:error, message} -> {:error, message}
      nil -> {:error, :profile_not_found}
      _ -> {:error, :meal_exists}
    end
  end

  def get_all(username) do
    case Mongo.find_one(:mongo, "profiles", %{username: username}) do
      nil ->
        {:error, :profile_not_found}

      %{"meal_log" => meal_log} ->
        {:ok, Enum.map(meal_log, &from_json/1)}

      _ ->
        {:error, :meal_log_not_found}
    end
  end

  def get(username, meal_name, date) do
    case Mongo.find_one(:mongo, "profiles", %{username: username}) do
      nil ->
        {:error, :profile_not_found}

      profile ->
        case find_meal(profile["meal_log"], meal_name, date) do
          nil -> {:error, :not_found}
          meal -> {:ok, from_json(meal)}
        end
    end
  end

  def update(username, meal_name, date, attrs) do
    with {:ok, meal_params} <- Map.fetch(attrs, "meal"),
         {:ok, ingredients} <- validate_ingredients(meal_params["ingredients"]),
         {:ok, updated_meal} <-
           new(%{
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
         true <- has_meal?(profile["meal_log"], meal_name, date) do
      update_meal(username, meal_name, date, to_json(updated_meal))
    else
      false -> create(username, attrs)
      nil -> {:error, :profile_not_found}
      error -> error
    end
  end

  def delete(username, meal_name, date) do
    case Mongo.update_one(:mongo, "profiles", %{username: username}, %{
           "$pull": %{
             meal_log: %{
               meal_name: meal_name,
               date_eaten: date
             }
           }
         }) do
      {:ok, %{modified_count: 1}} -> :ok
      {:ok, %{modified_count: 0}} -> {:error, :not_found}
      {:error, error} -> {:error, error}
    end
  end

  def clear_log(username) do
    case Mongo.update_one(:mongo, "profiles", %{username: username}, %{
           "$set": %{
             meal_log: []
           }
         }) do
      {:ok, %{modified_count: 1}} -> :ok
      {:ok, %{modified_count: 0}} -> {:error, :profile_not_found}
      {:error, error} -> {:error, error}
    end
  end

  # ... helper functions ...
  def from_json(json) when is_map(json) do
    %__MODULE__{
      meal_name: json["meal_name"],
      calories: json["calories"],
      protein: json["protein"],
      carbs: json["carbs"],
      fat: json["fat"],
      ingredients: Enum.map(json["ingredients"] || [], &Ingredient.from_json/1),
      date_eaten: json["date_eaten"]
    }
  end

  defp validate_ingredients(ingredients) when is_list(ingredients) do
    results = Enum.map(ingredients, &parse_ingredient/1)

    case Enum.find(results, &match?({:error, _}, &1)) do
      nil -> {:ok, results}
      {:error, message} -> {:error, message}
    end
  end

  defp validate_ingredients(_), do: {:error, "ingredients must be a list"}

  defp parse_ingredient(ingredient) do
    case ingredient do
      %{"name" => name} when is_binary(name) and name != "" ->
        Ingredient.new(ingredient)

      _ ->
        {:error, "each ingredient must have a valid name"}
    end
  end

  defp matching_meal?(meal, meal_params) do
    meal["meal_name"] == meal_params["meal_name"] &&
      meal["date_eaten"] == meal_params["date_eaten"]
  end

  defp find_meal(meal_log, meal_name, date) do
    Enum.find(meal_log, fn meal ->
      meal["meal_name"] == meal_name &&
        meal["date_eaten"] == date
    end)
  end

  defp has_meal?(meal_log, meal_name, date) do
    meal_log |> find_meal(meal_name, date) |> is_map()
  end

  defp update_meal(username, meal_name, date, updated_meal) do
    Mongo.update_one(
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
          "meal_log.$": updated_meal
        }
      }
    )
  end
end
