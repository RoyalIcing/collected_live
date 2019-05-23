# This file is responsible for configuring your umbrella
# and **all applications** and their dependencies with the
# help of Mix.Config.
#
# Note that all applications in your umbrella share the
# same configuration and dependencies, which is why they
# all use the same configuration file. If you want different
# configurations or dependencies per app, it is best to
# move said applications out of the umbrella.
use Mix.Config



config :collected_live_web,
  generators: [context_app: :collected_live]

# Configures the endpoint
config :collected_live_web, CollectedLiveWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "GIQzLogQXRdH7r9im+a6kEsZIbX6FmAvCt8bj+BYSkBahfkl6u9oRHSPs7Go81at",
  render_errors: [view: CollectedLiveWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: CollectedLiveWeb.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
