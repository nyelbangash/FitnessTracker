defmodule GymBro.Meals.MealTemplate do
  use Ecto.Schema
  import Ecto.Changeset

  @meal_types ~w(breakfast lunch dinner snack)

  schema "meal_templates" do
    field :name, :string
    field :meal_type, :string
    field :calories, :integer
    field :protein, :float
    field :carbs, :float
    field :fat, :float
    field :ingredients, :map, default: %{"items" => []}
    field :notes, :string

    belongs_to :user, GymBro.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def changeset(template, attrs) do
    template
    |> cast(attrs, [:name, :meal_type, :calories, :protein, :carbs, :fat,
                    :ingredients, :notes, :user_id])
    |> validate_required([:name, :user_id])
    |> validate_inclusion(:meal_type, @meal_types)
    |> foreign_key_constraint(:user_id)
    |> unique_constraint([:user_id, :name])
  end
end
