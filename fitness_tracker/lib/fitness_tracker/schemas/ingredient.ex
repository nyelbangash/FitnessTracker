defmodule FitnessTracker.Schemas.Ingredient do
  @derive Jason.Encoder
  defstruct [:name]

  def new(attrs) do
    attrs = Enum.map(attrs, fn {key, value} -> {String.to_atom(key), value} end)
    struct(__MODULE__, attrs)
  end

  def to_json(%__MODULE__{} = ingredient) do
    %{
      name: ingredient.name
    }
  end

  def from_json(json) when is_map(json) do
    %__MODULE__{
      name: json["name"]
    }
  end
end
