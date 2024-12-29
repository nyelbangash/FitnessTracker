defmodule FitnessTracker.Schemas.Set do
  @derive Jason.Encoder
  defstruct [
    :reps,
    :weight,
    # New: Rate of Perceived Exertion
    :rpe,
    # New: Timestamp of completion
    :completed_at,
    # New: Any notes about the set
    :notes
  ]

  def new(attrs) do
    attrs = Enum.map(attrs, fn {key, value} -> {String.to_atom(key), value} end)
    struct(__MODULE__, attrs)
  end

  def to_json(%__MODULE__{} = set) do
    Map.take(set, [:reps, :weight, :rpe, :completed_at, :notes])
  end

  def from_json(json) when is_map(json) do
    %__MODULE__{
      reps: json["reps"],
      weight: json["weight"],
      rpe: json["rpe"],
      completed_at: json["completed_at"],
      notes: json["notes"]
    }
  end
end
