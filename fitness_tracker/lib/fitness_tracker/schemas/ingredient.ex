defmodule FitnessTracker.Schemas.Ingredient do
  @derive Jason.Encoder
  defstruct [
    :name,
    # New: Amount of ingredient
    :amount,
    # New: Unit of measurement
    :unit,
    # New: Calories per serving
    :calories,
    # New: Protein content
    :protein,
    # New: Carb content
    :carbs,
    # New: Fat content
    :fat,
    # New: Mark as favorite ingredient
    :is_favorite
  ]

  def new(attrs) do
    attrs = Enum.map(attrs, fn {key, value} -> {String.to_atom(key), value} end)
    {:ok, struct(__MODULE__, attrs)}
  end

  def to_json(%__MODULE__{} = ingredient) do
    Map.take(ingredient, [:name, :amount, :unit, :calories, :protein, :carbs, :fat, :is_favorite])
  end

  def from_json(json) when is_map(json) do
    %__MODULE__{
      name: json["name"],
      amount: json["amount"],
      unit: json["unit"],
      calories: json["calories"],
      protein: json["protein"],
      carbs: json["carbs"],
      fat: json["fat"],
      is_favorite: json["is_favorite"]
    }
  end
end
