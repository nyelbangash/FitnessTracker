defmodule GymBro.MealLog do
  use Ecto.Schema
  import Ecto.Changeset
  alias GymBro.Meal

  schema "meal_logs" do
    field :date, :date
    field :notes, :string

    belongs_to :profile, GymBro.Profile
    has_many :meals, Meal

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(meal_log, attrs) do
    meal_log
    |> cast(attrs, [:date, :notes])
    |> validate_required([:date, :notes])
    |> unique_constraint(:profile_id)
    |> foreign_key_constraint(:profile_id)
    |> cast_assoc(:meals)
  end
end
