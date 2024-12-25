defmodule FitnessTracker.Schemas.Meal do
  defstruct [:meal_name, :calories, :protein, :carbs, :fat, :ingredients, :date_eaten]

  def new(meal_name, calories, protein, carbs, fat, ingredients) when is_binary(meal_name) and
                                                                     meal_name != "" and
                                                                     is_number(calories) and
                                                                     is_number(protein) and
                                                                     is_number(carbs) and
                                                                     is_number(fat) and
                                                                     length(ingredients) > 0 do
    {:ok, %__MODULE__{
      meal_name: meal_name,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      ingredients: ingredients,
      date_eaten: DateTime.utc_now()
    }}
  end

  def new(_, _, _, _, _, _), do: {:error, "Invalid meal parameters"}
end
