# In this file, we load production configuration and
# secrets from environment variables. You can also
# hardcode secrets, although such is generally not
# recommended and you have to remember to add this
# file to your .gitignore.
import Config

secret_key_base =
  System.get_env("SECRET_KEY_BASE") ||
    raise """
    environment variable SECRET_KEY_BASE is missing.
    You can generate one by calling: mix phx.gen.secret
    """

host =
  System.get_env("SERVICE_HOSTNAME") || System.get_env("RENDER_EXTERNAL_HOSTNAME") ||
    System.get_env("APP_NAME") <> ".gigalixirapp.com"

config :collected_live_web, CollectedLiveWeb.Endpoint,
  # http: [:inet6, port: String.to_integer(System.get_env("PORT") || "4000")],
  server: true,
  http: [port: {:system, "PORT"}],
  secret_key_base: secret_key_base,
  url: [host: host, port: 443]

config :collected_live_web, CollectedLiveWeb.Endpoint,
  royal_icing: [
    syntax_highlighter: [
      url: System.get_env("SYNTECT_SERVER_URL")
    ]
  ]
