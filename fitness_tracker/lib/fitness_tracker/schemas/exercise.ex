defmodule FitnessTracker.Schemas.Exercise do
  alias FitnessTracker.Schemas.Set
  @derive Jason.Encoder
  defstruct [
    :exercise_name,
    :target_reps,
    :target_weight,
    :rest_time,
    :rpe_target,
    :notes,
    :previous_weight,
    :personal_record,
    :completed_sets,
    sets: []
  ]

  defimpl Enumerable do
    def count(_), do: {:error, __MODULE__}
    def member?(_, _), do: {:error, __MODULE__}

    def reduce(%{sets: sets}, acc, fun) when is_list(sets),
      do: Enumerable.List.reduce(sets, acc, fun)

    def slice(_), do: {:error, __MODULE__}
  end

  def new(attrs) do
    with {:ok, valid_attrs} <- validate_exercise(attrs) do
      {:ok, struct(__MODULE__, valid_attrs)}
    end
  end

  # In Exercise module
  def to_json(%__MODULE__{} = exercise) do
    %{
      exercise_name: exercise.exercise_name,
      sets: Enum.map(exercise.sets || [], &Set.to_json/1),
      target_reps: exercise.target_reps,
      target_weight: exercise.target_weight,
      rest_time: exercise.rest_time,
      rpe_target: exercise.rpe_target,
      notes: exercise.notes,
      previous_weight: exercise.previous_weight,
      personal_record: exercise.personal_record,
      completed_sets: exercise.completed_sets
    }
  end

  def from_json(json) when is_map(json) do
    %__MODULE__{
      exercise_name: json["exercise_name"],
      sets: Enum.map(json["sets"] || [], &Set.from_json/1),
      target_reps: json["target_reps"],
      target_weight: json["target_weight"],
      rest_time: json["rest_time"],
      rpe_target: json["rpe_target"],
      notes: json["notes"],
      previous_weight: json["previous_weight"],
      personal_record: json["personal_record"],
      completed_sets: json["completed_sets"]
    }
  end

  defp validate_exercise(attrs) do
    with true <- is_binary(attrs["exercise_name"]) || {:error, "exercise_name is required"},
         true <- is_list(attrs["sets"]) || {:error, "sets must be a list"} do
      {:ok, attrs}
    end
  end
end
