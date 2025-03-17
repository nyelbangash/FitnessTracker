defmodule GymBro.Ingredient do
  use Ecto.Schema
  import Ecto.Changeset

  schema "ingredients" do
    field :name, :string
    field :unit, :string
    field :amount, :integer
    field :calories, :integer
    field :protein, :integer
    field :carbs, :integer
    field :fat, :integer
    field :is_favorite, :boolean, default: false

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(ingredient, attrs) do
    ingredient
    |> cast(attrs, [:name, :amount, :unit, :calories, :protein, :carbs, :fat, :is_favorite])
    |> validate_required([:name, :amount, :unit, :calories, :protein, :carbs, :fat, :is_favorite])
  end
end
