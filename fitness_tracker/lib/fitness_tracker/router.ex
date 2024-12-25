defmodule FitnessTracker.Router do
  use Plug.Router
  require Logger

  plug :match
  plug Plug.Parsers,
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: Jason
  plug :dispatch

  # Create profile
  post "/workout-api/profile" do
    case conn.body_params do
      %{
        "firstName" => first_name,
        "lastName" => last_name,
        "username" => username,
        "password" => password,
        "dateOfBirth" => dob,
        "height" => height,
        "weight" => weight
      } ->
        profile_doc = %{
          firstName: first_name,
          lastName: last_name,
          username: username,
          password: password,
          dateOfBirth: dob,
          height: height,
          weight: weight,
          dateAccountCreated: DateTime.utc_now()
        }

        case FitnessTracker.Repos.MongoRepo.insert_one("profiles", profile_doc) do
          {:ok, _} ->
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(201, Jason.encode!(%{message: "Profile created successfully"}))
          {:error, error} ->
            conn
            |> send_resp(500, "Failed to create profile: #{inspect(error)}")
        end
      _ ->
        send_resp(conn, 400, "Invalid profile data")
    end
  end

  match _ do
    send_resp(conn, 404, "Not found")
  end
  # Add workout
  put "/workout-api/workoutlog" do
    with username <- conn.params["username"],
         password <- conn.params["password"] do
      # Add workout logging logic here
      conn
      |> put_resp_content_type("application/json")
      |> send_resp(200, Jason.encode!(%{message: "Workout logged successfully"}))
    else
      _ -> send_resp(conn, 400, "Missing required parameters")
    end
  end

  # Get workouts
  get "/workout-api/workout/:date" do
    with username <- conn.params["username"],
         password <- conn.params["password"] do
      # Add workout retrieval logic here
      workouts = [
        %{
          workoutName: "Push Day",
          exercises: [
            %{
              exerciseName: "Bench Press",
              sets: [
                %{reps: 10, weight: 135}
              ]
            }
          ]
        }
      ]

      conn
      |> put_resp_content_type("application/json")
      |> send_resp(200, Jason.encode!(%{workouts: workouts}))
    else
      _ -> send_resp(conn, 400, "Missing required parameters")
    end
  end
end
