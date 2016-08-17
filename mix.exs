defmodule Aprb.Mixfile do
  use Mix.Project

  def project do
    [app: :aprb,
     version: "0.1.0",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     aliases: [test: "test --no-start"],
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [ mod: {Aprb, []},
      applications: [:logger, :maru, :kafka_ex, :slack, :postgrex, :ecto]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [ {:maru, github: "falood/maru"},
      {:kafka_ex, "~> 0.5.0"},
      {:poison, "~> 2.0"},
      {:slack, "~> 0.7.0"},
      {:websocket_client, github: "jeremyong/websocket_client"},
      {:postgrex, ">= 0.0.0"},
      {:ecto, "~> 2.0.0"} ]
  end
end
