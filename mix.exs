defmodule LoggerStackdriverBackend.MixProject do
  use Mix.Project

  def project do
    [
      app: :logger_stackdriver_backend,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      applications: []
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:google_api_logging, "~> 0.0.1"},
      {:goth, "~> 0.8"},
      {:timex, "~> 3.0"}
    ]
  end
end
