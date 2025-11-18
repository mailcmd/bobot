# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :bobot,
  generators: [timestamp_type: :utc_datetime],
  bots_dir: "dynamic/bots/",
  apis_dir: "dynamic/apis/",
  libs_dir: "dynamic/libs/"

# Configures the endpoint
config :bobot, BobotWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: BobotWeb.ErrorHTML, json: BobotWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Bobot.PubSub,
  live_view: [signing_salt: "wBCoDokh"]

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  bobot: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.4.3",
  bobot: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"

config :logger,
  level: :debug

config :logger, :console, metadata: [:bot, :chat_id]

config :logger, :default_formatter,
  format: "$date $time - [$level] $message $metadata\n"

config :tesla, disable_deprecated_builder_warning: true

config :tesla, :adapter, {Tesla.Adapter.Finch, name: Bobot.Finch, receive_timeout: 40_000}

config :telegram, :webserver, Telegram.WebServer.Bandit

config :telegram, :get_updates_poll_timeout_s, 20

Path.wildcard("config/local/*.exs")
  |> Enum.each( fn file -> "local/" <> (file |> Path.basename()) |> import_config() end )

Path.wildcard("config/local/bots/*.exs")
  |> Enum.each( fn file -> "local/bots/" <> (file |> Path.basename()) |> import_config() end )
