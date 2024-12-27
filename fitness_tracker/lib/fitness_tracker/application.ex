defmodule FitnessTracker.Application do
  use Application
  require Logger

  def start(_type, _args) do
    children = [
      # Start Mongo first
      {Mongo,
       [
         name: :mongo,
         database: "fitness_tracker",
         pool_size: 2
       ]},
      # Then your other services
      {
        Plug.Cowboy,
        scheme: :http,
        plug: FitnessTracker.Router,
        options: [
          port: 4001,
          dispatch: [
            {:_,
             [
               {"/ws", MyApp.WebSocketHandler, []},
               {:_, Plug.Cowboy.Handler,
                {FitnessTracker.Router,
                 [
                   cors_plug_opts: [origin: ["http://localhost:3001"]]
                 ]}}
             ]}
          ]
        ]
      }
    ]

    opts = [strategy: :one_for_one, name: FitnessTracker.Supervisor]

    Logger.info("Starting application...")
    Supervisor.start_link(children, opts)
  end
end
