defmodule FitnessTracker.Schemas.Set do
  @derive Jason.Encoder
  defstruct [:reps, :weight]

  def new(attrs) do
    attrs = Enum.map(attrs, fn {key, value} -> {String.to_atom(key), value} end)
    struct(__MODULE__, attrs)
  end

  def to_json(%__MODULE__{} = set) do
    %{
      reps: set.reps,
      weight: set.weight
    }
  end

  def from_json(json) when is_map(json) do
    %__MODULE__{
      reps: json["reps"],
      weight: json["weight"]
    }
  end
end
