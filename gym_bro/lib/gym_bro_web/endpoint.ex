defmodule GymBroWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :gym_bro

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  @session_options [
    store: :cookie,
    key: "_gym_bro_key",
    signing_salt: "XRKCSuC/",
    same_site: "Lax"
  ]

  socket "/live", Phoenix.LiveView.Socket,
    websocket: [connect_info: [session: @session_options]],
    longpoll: [connect_info: [session: @session_options]]

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phx.digest
  # when deploying your static files in production.
  plug Plug.Static,
    at: "/",
    from: :gym_bro,
    gzip: false,
    only: GymBroWeb.static_paths()

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
    plug Phoenix.Ecto.CheckRepoStatus, otp_app: :gym_bro
  end

  plug Phoenix.LiveDashboard.RequestLogger,
    param_key: "request_logger",
    cookie_key: "request_logger"

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options
  plug CORSPlug, origin: &__MODULE__.cors_origins/0
  plug GymBroWeb.Router

  # CORS allowed origins. Always includes localhost dev; in prod we also
  # accept any origin listed in the CORS_ORIGIN env var (comma-separated)
  # and any *.vercel.app origin (covers preview + production deploys).
  def cors_origins do
    base = [
      ~r/^https?:\/\/localhost(:\d+)?$/,
      # Capacitor iOS WKWebView origin (bundled assets).
      "capacitor://localhost",
      # Capacitor Android scheme (in case we ever add Android).
      ~r/^https?:\/\/[a-z0-9-]+\.local(:\d+)?$/,
      # mDNS hostnames like Nyels-MacBook-Pro.local when iPhone connects over LAN.
      ~r/^https:\/\/[a-z0-9-]+\.vercel\.app$/
    ]

    extra =
      case System.get_env("CORS_ORIGIN") do
        nil -> []
        "" -> []
        s -> s |> String.split(",") |> Enum.map(&String.trim/1) |> Enum.reject(&(&1 == ""))
      end

    base ++ extra
  end
end
