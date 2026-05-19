import Config

config :pleroma, Pleroma.Web.Endpoint,
  url: [host: System.get_env("DOMAIN"), scheme: "https", port: 443],
  http: [ip: {0,0,0,0}, port: 4000]

config :pleroma, :instance,
  name: System.get_env("INSTANCE_NAME"),
  email: System.get_env("ADMIN_EMAIL"),
  limit: 5000,
  registrations_open: true

config :pleroma, Pleroma.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: System.get_env("POSTGRES_USER"),
  password: System.get_env("POSTGRES_PASSWORD"),
  database: System.get_env("POSTGRES_DB"),
  hostname: "pleroma-db",
  pool_size: 10

config :pleroma, :database, rum_enabled: false

config :pleroma, :media_proxy,
  enabled: false,
  redirect_on_failure: true

config :pleroma, :frontends,
  primary: "pleroma-fe",
  admin: "admin-fe"