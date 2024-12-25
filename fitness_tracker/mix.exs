defmodule FitnessTracker.MixProject do
  use Mix.Project

  def project do
    [
      app: :fitness_tracker,
      version: "0.1.0",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :mongodb_driver],  # This is correct
      mod: {FitnessTracker.Application, []}
    ]
  end

  defp deps do
    [
      {:mongodb_driver, "~> 1.5.0"},  # Changed this line back to mongodb_driver
      {:poolboy, "~> 1.5"},
      {:plug, "~> 1.14"},
      {:plug_cowboy, "~> 2.6"},
      {:jason, "~> 1.2"},
      {:argon2_elixir, "~> 3.0"}
    ]
  end
end
