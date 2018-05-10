defmodule Unbrella.Mixfile do
  use Mix.Project

  def project do
    [app: :unbrella,
     version: "0.1.2",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     dialyzer: [plt_add_apps: [:mix]],
     elixirc_paths: elixirc_paths(Mix.env),
     test_coverage: [tool: ExCoveralls],
     preferred_cli_env: ["coveralls": :test, "coveralls.detail": :test, "coveralls.post": :test, "coveralls.html": :test],
     aliases: aliases(),
     deps: deps()]
  end

  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [extra_applications: [:logger]]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp aliases do
    ["commit": ["deps.get --only #{Mix.env}", "dialyzer", "credo --strict"]]
  end

  defp deps do
    [{:phoenix, "~> 1.3"},
     {:phoenix_ecto, "~> 3.2"},
     {:dialyxir, "~> 0.0", only: [:dev], runtime: false},
     {:excoveralls, "~> 0.7", only: :test},
     {:credo, "~> 0.8", only: [:dev, :test], runtime: false}]
  end
end
