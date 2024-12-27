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
      # This is correct
      extra_applications: [:logger, :mongodb_driver, :cors_plug],
      mod: {FitnessTracker.Application, []}
    ]
  end

  defp deps do
    [
      # Changed this line back to mongodb_driver
      {:mongodb_driver, "~> 1.5.0"},
      {:poolboy, "~> 1.5"},
      {:plug, "~> 1.14"},
      {:plug_cowboy, "~> 2.6"},
      {:jason, "~> 1.2"},
      {:argon2_elixir, "~> 3.0"},
      {:cors_plug, "~> 3.0"}
    ]
  end
end
