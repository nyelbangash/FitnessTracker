defmodule FitnessTracker.Schemas.Date do
  defstruct [:day, :month, :year]

  def new(day, month, year) do
    with true <- is_valid_date?(day, month, year) do
      {:ok, %__MODULE__{day: day, month: month, year: year}}
    else
      false -> {:error, "Invalid date"}
    end
  end

  defp is_valid_date?(day, month, year) do
    day in 1..31 and month in 1..12 and year >= 1900 and year <= current_year()
  end

  defp current_year, do: DateTime.utc_now().year
end
