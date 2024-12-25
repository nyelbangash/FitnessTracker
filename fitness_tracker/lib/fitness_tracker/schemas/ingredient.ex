defmodule FitnessTracker.Schemas.Ingredient do
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
end
