defmodule Unbrella.Mixfile do
  use Mix.Project

  def project do
    [app: :unbrella,
     version: "0.1.0",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     elixirc_paths: elixirc_paths(Mix.env),
     deps: deps()]
  end

  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [extra_applications: [:logger]]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]


  defp deps do
    [{:phoenix, "~> 1.3.0-rc"},
     {:phoenix_ecto, "~> 3.2"}]
  end
end
