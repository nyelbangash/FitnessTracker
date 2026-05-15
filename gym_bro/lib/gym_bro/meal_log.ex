defmodule GymBro.MealLog do
  use Ecto.Schema
  import Ecto.Changeset
  alias GymBro.Meal

  schema "meal_logs" do
    field :date, :date
    field :notes, :string

    belongs_to :user, GymBro.Accounts.User
    has_many :meals, Meal

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(meal_log, attrs) do
    meal_log
    |> cast(attrs, [:date, :notes, :user_id])
    |> validate_required([:date, :user_id])
    |> foreign_key_constraint(:user_id)
    |> unique_constraint([:user_id, :date])
    |> cast_assoc(:meals)
  end
end
