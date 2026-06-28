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

  # Meals are editable for 24h after they were eaten. After that we lock
  # them so the daily log stays a faithful record of what was actually
  # consumed. Toggles (favorite, quick-access, recurring) and deletes are
  # NOT affected — only the macro/ingredient edit form.

  @edit_window_seconds 24 * 60 * 60

  @doc """
  The UTC DateTime at which this meal becomes uneditable. Anchors on
  `time_eaten` when set, otherwise on the start of the meal's date.
  """
  def editable_until(%__MODULE__{} = meal) do
    case anchor_datetime(meal) do
      nil -> nil
      anchor -> DateTime.add(anchor, @edit_window_seconds, :second)
    end
  end

  @doc """
  True if `now` is within the editable window. `now` defaults to UTC now.
  """
  def editable?(meal, now \\ DateTime.utc_now())

  def editable?(%__MODULE__{} = meal, %DateTime{} = now) do
    case editable_until(meal) do
      nil -> true
      deadline -> DateTime.compare(now, deadline) != :gt
    end
  end

  defp anchor_datetime(%__MODULE__{date: %Date{} = d, time_eaten: %Time{} = t}) do
    case DateTime.new(d, t, "Etc/UTC") do
      {:ok, dt} -> dt
      _ -> nil
    end
  end

  defp anchor_datetime(%__MODULE__{date: %Date{} = d}) do
    case DateTime.new(d, ~T[00:00:00], "Etc/UTC") do
      {:ok, dt} -> dt
      _ -> nil
    end
  end

  defp anchor_datetime(_), do: nil
end
