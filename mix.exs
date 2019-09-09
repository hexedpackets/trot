defmodule Trot.Mixfile do
  use Mix.Project

  @version File.read!("VERSION") |> String.trim

  def project do
    [app: :trot,
     version: @version,
     elixir: "~> 1.4",
     deps: deps(),
     name: "Trot",
     docs: [main: "readme",
            extras: ["README.md"],
            source_ref: "v#{@version}",
            source_url: "https://github.com/hexedpackets/trot"],

     # Hex
     description: description(),
     package: package()]
  end

  def application do
    [applications: [:logger, :plug, :cowboy, :plug_heartbeat, :slime],
     mod: {Trot, []}]
  end

  defp deps do
    [
      {:plug_cowboy, "~> 2.0"},
      {:cowboy, "~> 2.5"},
      {:poison, "~> 3.1"},
      {:calliope, "~> 0.4.2"},
      {:plug_heartbeat, "~> 0.2"},
      {:earmark, "~> 1.2", only: :dev},
      {:ex_doc, "~> 0.16", only: :dev, runtime: false},
      {:inch_ex, ">= 0.0.0", only: :docs},
      {:credo, "~> 0.8", only: [:dev, :test]},
      {:slime, "~> 1.1.0"},
    ]
  end

  defp description do
    """
    A web micro-framework based on Plug and Cowboy.
    """
  end

  defp package do
    [maintainers: ["William Huba"],
     licenses: ["Apache 2.0"],
     links: %{"GitHub" => "https://github.com/hexedpackets/trot"},
     files: ~w(mix.exs README.md LICENSE lib VERSION)]
  end
end
