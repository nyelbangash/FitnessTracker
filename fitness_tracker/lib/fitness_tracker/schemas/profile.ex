# lib/fitness_tracker/schemas/profile.ex
defmodule FitnessTracker.Schemas.Profile do
  @moduledoc """
  Schema and functions for handling user profiles.
  """

  defstruct [
    :first_name,
    :last_name,
    :username,
    :password,
    :date_of_birth,
    :height,
    :weight,
    :date_account_created,
    workout_log: [],
    meal_log: []
  ]

  def new(%{
        "firstName" => first_name,
        "lastName" => last_name,
        "username" => username,
        "password" => password,
        "dateOfBirth" => date_of_birth,
        "height" => height,
        "weight" => weight
      }) do
    attrs = %{
      first_name: first_name,
      last_name: last_name,
      username: username,
      password: password,
      date_of_birth: date_of_birth,
      height: height,
      weight: weight
    }

    with {:ok, profile} <- validate_profile(attrs) do
      {:ok,
       %__MODULE__{
         first_name: first_name,
         last_name: last_name,
         username: username,
         password: password,
         date_of_birth: date_of_birth,
         height: height,
         weight: weight,
         date_account_created: DateTime.utc_now(),
         workout_log: [],
         meal_log: []
       }}
    end
  end

  def new(_) do
    {:error, "Invalid profile parameters"}
  end

  defp validate_profile(attrs) do
    with {:ok, _} <- validate_required_fields(attrs),
         {:ok, _} <- validate_measurements(attrs) do
      {:ok, attrs}
    end
  end

  defp validate_required_fields(attrs) do
    required_fields = [
      :first_name,
      :last_name,
      :username,
      :password,
      :date_of_birth,
      :height,
      :weight
    ]

    case Enum.filter(required_fields, &is_nil(Map.get(attrs, &1))) do
      [] -> {:ok, attrs}
      missing_fields -> {:error, "Missing required fields: #{inspect(missing_fields)}"}
    end
  end

  defp validate_measurements(%{height: height, weight: weight} = attrs)
       when is_number(height) and height > 0 and
              is_number(weight) and weight > 0 do
    {:ok, attrs}
  end

  defp validate_measurements(_attrs) do
    {:error, "Height and weight must be positive numbers"}
  end

  def to_json(%__MODULE__{} = profile) do
    %{
      firstName: profile.first_name,
      lastName: profile.last_name,
      username: profile.username,
      dateOfBirth: profile.date_of_birth,
      height: profile.height,
      weight: profile.weight,
      dateAccountCreated: profile.date_account_created
    }
  end

  def from_json(json) when is_map(json) do
    %__MODULE__{
      first_name: json["firstName"],
      last_name: json["lastName"],
      username: json["username"],
      password: json["password"],
      date_of_birth: json["dateOfBirth"],
      height: json["height"],
      weight: json["weight"],
      date_account_created: json["dateAccountCreated"]
    }
  end
end
