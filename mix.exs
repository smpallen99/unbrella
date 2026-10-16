defmodule Unbrella.Mixfile do
  use Mix.Project

  def project do
    [
      app: :unbrella,
      version: "1.1.0",
      elixir: "~> 1.20",
      start_permanent: Mix.env() == :prod,
      dialyzer: [plt_add_apps: [:mix]],
      elixirc_paths: elixirc_paths(Mix.env()),
      test_coverage: [tool: ExCoveralls],
      aliases: aliases(),
      deps: deps()
    ]
  end

  def cli do
    [
      preferred_envs: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        "coveralls.json": :test
      ]
    ]
  end

  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [extra_applications: [:logger]]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp aliases do
    [commit: ["deps.get --only #{Mix.env()}", "dialyzer", "credo --strict"]]
  end

  defp deps do
    [
      {:phoenix, "~> 1.8.15"},
      {:phoenix_ecto, "~> 4.7"},
      {:ecto_sql, "~> 3.14"},
      {:dialyxir, "~> 1.4.8", only: [:dev], runtime: false},
      {:excoveralls, "~> 0.18.5", only: :test},
      {:credo, "~> 1.7.19", only: [:dev, :test], runtime: false}
    ]
  end
end
