use Mix.Config

config :goth,
  json:
    System.get_env
      |> Map.get("GOOGLE_APPLICATION_CREDENTIALS", "#{System.user_home}/.config/gcloud/application_default_credentials.json")
      |> File.read!
