defmodule CollectedLive.MixProject do
  use Mix.Project

  def project do
    [
      app: :collected_live,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.5",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:rustler] ++ Mix.compilers(),
      rustler_crates: [
        collectedlive_syntaxhighlighter: [
          path: "../../native/collectedlive_syntaxhighlighter"
        ]
      ],
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {CollectedLive.Application, []},
      extra_applications: [:logger, :runtime_tools, :rustler]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:tesla, "~> 1.3.0"},
      {:hackney, "~> 1.14.0"},
      {:mox, "~> 0.5", only: :test},
      {:cachex, "~> 3.1"},
      {:ecto, "~> 3.1.4"},
      {:httpotion, "~> 3.1.0"},
      {:jason, "~> 1.0"},
      {:rustler, "~> 0.21.0"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    []
  end
end
