defmodule GymBro.Meal do
  use Ecto.Schema
  import Ecto.Changeset

  schema "meals" do
    field :name, :string
    field :date, :date
    field :time_eaten, :time
    field :meal_type, :string
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
    |> cast(attrs, [:name, :date, :time_eaten, :meal_type, :calories, :protein, :carbs, :fat, :ingredients, :is_favorite, :is_recurring, :is_quick_access, :template_name, :notes, :schedule])
    |> validate_required([:name, :date, :time_eaten, :meal_type, :calories, :protein, :carbs, :fat, :ingredients, :is_favorite, :is_recurring, :is_quick_access, :template_name, :notes, :schedule])
  end
end
