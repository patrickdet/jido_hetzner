defmodule JidoHetzner.MixProject do
  use Mix.Project

  def project do
    [
      app: :jido_hetzner,
      version: "0.1.0",
      elixir: "~> 1.18",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [extra_applications: [:logger, :crypto, :public_key]]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:jido_shell, path: "../jido_shell"},
      {:req, "~> 0.5"},
      {:jason, "~> 1.4"},
      {:bypass, "~> 2.1", only: :test},
      {:mimic, "~> 2.0", only: :test},
      {:plug_cowboy, "~> 2.7", only: :test},
      {:excoveralls, "~> 0.18", only: [:dev, :test]},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false}
    ]
  end
end
