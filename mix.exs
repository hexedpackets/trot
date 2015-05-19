defmodule Trot.Mixfile do
  use Mix.Project

  @version "0.0.1"

  def project do
    [app: :trot,
     version: @version,
     elixir: "~> 1.0",
     deps: deps]
  end

  def application do
    [applications: [:logger, :plug, :cowboy]]
  end

  defp deps do
    [
      {:plug, "~> 0.12"},
      {:cowboy, "~> 1.0"},
      {:poison, "~> 1.4"},
    ]
  end
end
