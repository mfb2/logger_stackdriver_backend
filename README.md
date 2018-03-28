# LoggerStackdriverBackend

Backend integration for Stackdriver logging

## Installation

1.  Add `:goth` `:timex`, and `:logger_stackdriver_backend` to your dependencies and applications in `mix.exs`

```Elixir
  # No need to add :goth or :timex here.  :goth will be started with the logger startup
  def application do
    [
      applications: [:logger, :logger_stackdriver_backend],
      extra_applications: [:logger],
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:timex, "~> 3.0"},
      {:goth, "~> 0.8"},
      {:logger_stackdriver_backend, github: "mfb2/logger_stackdriver_backend"}
    ]
  end
```

2.  Add configuration to your `config.exs`

```Elixir
config :goth,
  json: System.get_env("GOOGLE_APPLICATION_CREDENTIALS") |> File.read!

config :logger,
  level: System.get_env("LOG_LEVEL", :info),
  backends: [{Logger.Backends.Stackdriver, :stackdriver}]

config :logger, :stackdriver,
  project: System.get_env("GCP_PROJECT"),
  logname: "my-gcp-project"
```

3.  Log away!

## Contributing

PRs welcome!  Here's some functionality that has yet to be implemented:
 - [ ] Multiple logging resource types (only Global is currently implemented)
 - [ ] Unit tests
 - [ ] ExDoc / Hex Documentation
 - [ ] Better handling of `:goth` bootstrap / configuration
 - [ ] A more complete feature list
