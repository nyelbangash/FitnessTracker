defmodule GymBro.Profile do
  use Ecto.Schema
  import Ecto.Changeset

  schema "profiles" do
    field :name, :string
    field :password, :string
    field :email, :string
    field :height, :integer
    field :weight, :float
    field :dob, :date
    field :active_workout, :boolean

    has_one :meal_log, GymBro.MealLog

    timestamps(type: :utc_datetime)
  end


  @doc false
  def changeset(profile, attrs) do
    profile
    |> cast(attrs, [:name, :email, :height, :weight, :password, :dob])
    |> validate_required([:name, :email, :height, :weight, :password, :dob])
  end
end
