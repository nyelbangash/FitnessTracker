defmodule GymBro.Meal do
  use Ecto.Schema
  import Ecto.Changeset

  schema "meals" do
    field :name, :string
    field :time_eaten, :time
    field :meal_type, :string
    field :date, :date, virtual: true
    field :calories, :integer
    field :protein, :float
    field :carbs, :float
    field :fat, :float
    field :is_favorite, :boolean, default: false
    field :is_recurring, :boolean, default: false
    field :is_quick_access, :boolean, default: false
    field :template_name, :string
    field :notes, :string
    field :schedule, :string

    belongs_to :meal_log, GymBro.MealLog
    many_to_many :ingredients, GymBro.Ingredient, join_through: "meal_ingredients"

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(meal, attrs) do
    meal
    |> cast(attrs, [:name, :time_eaten, :meal_type, :calories, :protein, :carbs, :fat, :is_favorite, :is_recurring, :is_quick_access, :template_name, :notes, :schedule, :meal_log_id])
    |> validate_required([:name, :meal_type])
    |> validate_inclusion(:meal_type, ~w(breakfast lunch dinner snack))
    |> foreign_key_constraint(:meal_log_id)
  end
end
