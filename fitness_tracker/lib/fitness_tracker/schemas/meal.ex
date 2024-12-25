defmodule FitnessTracker.Schemas.Meal do
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
      ingredients: Enum.map(meal.ingredients, &FitnessTracker.Schemas.Ingredient.to_json/1),
      date_eaten: meal.date_eaten
    }
  end

  def from_json(json) when is_map(json) do
    struct(__MODULE__, json)
  end
end
