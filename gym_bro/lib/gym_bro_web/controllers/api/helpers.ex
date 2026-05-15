defmodule GymBroWeb.Api.Helpers do
  @moduledoc """
  Helpers shared across API controllers.
  """

  def parse_date(%Date{} = d), do: {:ok, d}
  def parse_date(s) when is_binary(s) do
    case Date.from_iso8601(s) do
      {:ok, d} -> {:ok, d}
      _ -> {:error, :invalid_date}
    end
  end
  def parse_date(_), do: {:error, :invalid_date}
end
