defmodule RouterTest do
  use ExUnit.Case, async: true
  use Plug.Test

  alias FitnessTracker.Router
  alias FitnessTracker.Schemas.{Profile, Workout, Meal}

  @opts Router.init([])

  setup do
    on_exit(fn ->
      Mongo.delete_many(:mongo, "profiles", %{})
    end)
  end

  describe "POST /ft/profile" do
    test "creates a new profile" do
      profile_params = %{
        "first_name" => "John",
        "last_name" => "Doe",
        "username" => "johndoe",
        "password" => "password",
        "date_of_birth" => "1990-01-01",
        "height" => 180,
        "weight" => 75
      }

      conn = conn(:post, "/ft/profile", profile_params)
      conn = Router.call(conn, @opts)

      assert conn.state == :sent
      assert conn.status == 201
      assert Jason.decode!(conn.resp_body) == %{"message" => "Profile created successfully"}
    end

    test "returns 400 when username already exists" do
      Profile.create(%{
        first_name: "Jane",
        last_name: "Doe",
        username: "janedoe",
        password: "password",
        date_of_birth: ~D[1995-01-01],
        height: 165,
        weight: 60
      })

      profile_params = %{
        "first_name" => "Jane",
        "last_name" => "Doe",
        "username" => "janedoe",
        "password" => "password",
        "date_of_birth" => "1995-01-01",
        "height" => 165,
        "weight" => 60
      }

      conn = conn(:post, "/ft/profile", profile_params)
      conn = Router.call(conn, @opts)

      assert conn.state == :sent
      assert conn.status == 400
      assert Jason.decode!(conn.resp_body) == %{"message" => "Username already exists"}
    end
  end

  describe "POST /ft/login" do
    setup do
      Profile.create(%{
        first_name: "John",
        last_name: "Doe",
        username: "johndoe",
        password: "password",
        date_of_birth: ~D[1990-01-01],
        height: 180,
        weight: 75
      })

      :ok
    end

    test "authenticates valid credentials" do
      credentials = %{"username" => "johndoe", "password" => "password"}

      conn = conn(:post, "/ft/login", %{"credentials" => credentials})
      conn = Router.call(conn, @opts)

      assert conn.state == :sent
      assert conn.status == 200

      %{"profile" => profile, "success" => success} = Jason.decode!(conn.resp_body)
      assert success == true
      assert profile["username"] == "johndoe"
    end

    test "returns 404 when user not found" do
      credentials = %{"username" => "nonexistent", "password" => "password"}

      conn = conn(:post, "/ft/login", %{"credentials" => credentials})
      conn = Router.call(conn, @opts)

      assert conn.state == :sent
      assert conn.status == 404
      assert Jason.decode!(conn.resp_body) == %{"message" => "User not found", "success" => false}
    end

    test "returns 401 for invalid credentials" do
      credentials = %{"username" => "johndoe", "password" => "wrongpassword"}

      conn = conn(:post, "/ft/login", %{"credentials" => credentials})
      conn = Router.call(conn, @opts)

      assert conn.state == :sent
      assert conn.status == 401

      assert Jason.decode!(conn.resp_body) == %{
               "message" => "Invalid credentials",
               "success" => false
             }
    end
  end

  describe "GET /ft/profile" do
    test "returns all profiles" do
      Profile.create(%{
        first_name: "John",
        last_name: "Doe",
        username: "johndoe",
        password: "password",
        date_of_birth: ~D[1990-01-01],
        height: 180,
        weight: 75
      })

      Profile.create(%{
        first_name: "Jane",
        last_name: "Doe",
        username: "janedoe",
        password: "password",
        date_of_birth: ~D[1995-01-01],
        height: 165,
        weight: 60
      })

      conn = conn(:get, "/ft/profile")
      conn = Router.call(conn, @opts)

      assert conn.state == :sent
      assert conn.status == 200

      %{"profiles" => profiles} = Jason.decode!(conn.resp_body)
      assert length(profiles) == 2
      assert Enum.map(profiles, & &1["username"]) == ["johndoe", "janedoe"]
    end
  end

  describe "GET /ft/profile/:username" do
    setup do
      Profile.create(%{
        first_name: "John",
        last_name: "Doe",
        username: "johndoe",
        password: "password",
        date_of_birth: ~D[1990-01-01],
        height: 180,
        weight: 75
      })

      :ok
    end

    test "returns profile by username" do
      conn = conn(:get, "/ft/profile/johndoe")
      conn = Router.call(conn, @opts)

      assert conn.state == :sent
      assert conn.status == 200

      profile = Jason.decode!(conn.resp_body)
      assert profile["username"] == "johndoe"
    end

    test "returns 404 when profile not found" do
      conn = conn(:get, "/ft/profile/nonexistent")
      conn = Router.call(conn, @opts)

      assert conn.state == :sent
      assert conn.status == 404
      assert Jason.decode!(conn.resp_body) == %{"message" => "Profile not found"}
    end
  end

  describe "DELETE /ft/profile/:username" do
    setup do
      Profile.create(%{
        first_name: "John",
        last_name: "Doe",
        username: "johndoe",
        password: "password",
        date_of_birth: ~D[1990-01-01],
        height: 180,
        weight: 75
      })

      :ok
    end

    test "deletes a profile" do
      conn = conn(:delete, "/ft/profile/johndoe")
      conn = Router.call(conn, @opts)

      assert conn.state == :sent
      assert conn.status == 200
      assert Jason.decode!(conn.resp_body) == %{"message" => "Profile deleted successfully"}

      assert {:error, :not_found} = Profile.get_by_username("johndoe")
    end

    test "returns 404 when profile not found" do
      conn = conn(:delete, "/ft/profile/nonexistent")
      conn = Router.call(conn, @opts)

      assert conn.state == :sent
      assert conn.status == 404
      assert Jason.decode!(conn.resp_body) == %{"message" => "Profile not found"}
    end
  end

  describe "POST /ft/profile/:username/workout" do
    setup do
      Profile.create(%{
        first_name: "John",
        last_name: "Doe",
        username: "johndoe",
        password: "password",
        date_of_birth: ~D[1990-01-01],
        height: 180,
        weight: 75
      })

      :ok
    end

    test "creates a new workout" do
      workout_params = %{
        "workout" => %{
          "workout_name" => "Chest Day",
          "exercises" => [
            %{
              "exercise_name" => "Bench Press",
              "sets" => [
                %{"reps" => 10, "weight" => 100},
                %{"reps" => 8, "weight" => 110}
              ]
            }
          ],
          "length_of_workout" => 60,
          "date_worked_out" => "2023-06-08"
        }
      }

      conn = conn(:post, "/ft/profile/johndoe/workout", workout_params)
      conn = Router.call(conn, @opts)

      assert conn.state == :sent
      assert conn.status == 201
      assert Jason.decode!(conn.resp_body) == %{"message" => "Workout added successfully"}
    end

    test "returns 404 when profile not found" do
      conn = conn(:post, "/ft/profile/nonexistent/workout", %{})
      conn = Router.call(conn, @opts)

      assert conn.state == :sent
      assert conn.status == 404
      assert Jason.decode!(conn.resp_body) == %{"message" => "Profile not found"}
    end
  end

  describe "PUT /ft/profile/:username" do
    setup do
      {:ok, profile} =
        Profile.create(%{
          "first_name" => "John",
          "last_name" => "Doe",
          "username" => "johndoe",
          "password" => "password",
          "date_of_birth" => ~D[1990-01-01],
          "height" => 180,
          "weight" => 75
        })

      {:ok, profile: profile}
    end

    test "updates a profile", %{profile: profile} do
      update_params = %{
        "first_name" => "Johnny",
        "height" => "185",
        "weight" => "80"
      }

      conn = conn(:put, "/ft/profile/#{profile.username}", update_params)
      conn = Router.call(conn, @opts)

      assert conn.state == :sent
      assert conn.status == 200
      assert Jason.decode!(conn.resp_body) == %{"message" => "Profile updated successfully"}

      {:ok, updated_profile} = Profile.get_by_username(profile.username)
      assert updated_profile.first_name == "Johnny"
      assert updated_profile.height == "185"
      assert updated_profile.weight == "80"
    end

    test "returns 404 when profile not found" do
      conn = conn(:put, "/ft/profile/nonexistent", %{})
      conn = Router.call(conn, @opts)

      assert conn.state == :sent
      assert conn.status == 404
      assert Jason.decode!(conn.resp_body) == %{"message" => "Profile not found"}
    end
  end

  describe "GET /ft/profile/:username/workout" do
    setup do
      {:ok, profile} =
        Profile.create(%{
          "first_name" => "John",
          "last_name" => "Doe",
          "username" => "johndoe",
          "password" => "password",
          "date_of_birth" => ~D[1990-01-01],
          "height" => 180,
          "weight" => 75
        })

      {:ok, _workout} =
        Workout.create(profile.username, %{
          "workout" => %{
            "workout_name" => "Chest Day",
            "exercises" => [
              %{
                "exercise_name" => "Bench Press",
                "sets" => [
                  %{"reps" => 10, "weight" => 100},
                  %{"reps" => 8, "weight" => 110}
                ]
              }
            ],
            "length_of_workout" => 60,
            "date_worked_out" => "2023-06-08"
          }
        })

      {:ok, profile: profile}
    end

    test "returns all workouts for a profile", %{profile: profile} do
      conn = conn(:get, "/ft/profile/#{profile.username}/workout")
      conn = Router.call(conn, @opts)

      assert conn.state == :sent
      assert conn.status == 200

      %{"workouts" => workouts} = Jason.decode!(conn.resp_body)
      assert length(workouts) == 1
      assert List.first(workouts)["workout_name"] == "Chest Day"
    end

    test "returns 404 when profile not found" do
      conn = conn(:get, "/ft/profile/nonexistent/workout")
      conn = Router.call(conn, @opts)

      assert conn.state == :sent
      assert conn.status == 404
      assert Jason.decode!(conn.resp_body) == %{"message" => "Profile not found"}
    end
  end

  describe "GET /ft/profile/:username/workout/active" do
    setup do
      {:ok, profile} =
        Profile.create(%{
          "first_name" => "John",
          "last_name" => "Doe",
          "username" => "johndoe",
          "password" => "password",
          "date_of_birth" => ~D[1990-01-01],
          "height" => 180,
          "weight" => 75
        })

      template_data = %{
        "workout" => %{
          "workout_name" => "Chest Day",
          "exercises" => [
            %{
              "exercise_name" => "Bench Press",
              "sets" => [%{"reps" => 10, "weight" => 100}]
            }
          ],
          "length_of_workout" => 60,
          "date_worked_out" => Date.utc_today() |> Date.to_string()
        }
      }

      # Save the template first
      {:ok, _} = Workout.save_template(profile.username, "Chest Day", template_data)

      {:ok, profile: profile}
    end

    test "returns active workout when one exists", %{profile: profile} do
      {:ok, _} = Workout.start_workout(profile.username, "Chest Day")

      conn = conn(:get, "/ft/profile/#{profile.username}/workout/active")
      conn = Router.call(conn, @opts)

      assert conn.state == :sent
      assert conn.status == 200

      %{"exercises" => _exercises} = Jason.decode!(conn.resp_body)
    end

    test "returns 404 when no active workout", %{profile: profile} do
      conn = conn(:get, "/ft/profile/#{profile.username}/workout/active")
      conn = Router.call(conn, @opts)

      assert conn.state == :sent
      assert conn.status == 404
      assert Jason.decode!(conn.resp_body) == %{"message" => "No active workout found"}
    end
  end

  describe "PUT /ft/profile/:username/workout/active/exercise/targets" do
    setup do
      {:ok, profile} =
        Profile.create(%{
          "first_name" => "John",
          "last_name" => "Doe",
          "username" => "johndoe",
          "password" => "password",
          "date_of_birth" => ~D[1990-01-01],
          "height" => 180,
          "weight" => 75
        })

      template_data = %{
        "workout" => %{
          "workout_name" => "Chest Day",
          "exercises" => [
            %{
              "exercise_name" => "Bench Press",
              "sets" => [%{"reps" => 10, "weight" => 100}]
            }
          ],
          "length_of_workout" => 60,
          "date_worked_out" => Date.utc_today() |> Date.to_string()
        }
      }

      # Save the template first
      {:ok, _} = Workout.save_template(profile.username, "Chest Day", template_data)

      {:ok, _} = Workout.start_workout(profile.username, "Chest Day")
      {:ok, profile: profile}
    end

    test "updates exercise targets", %{profile: profile} do
      targets = %{"target_weight" => 100, "target_reps" => 10}

      conn =
        conn(:put, "/ft/profile/#{profile.username}/workout/active/exercise/targets", targets)

      conn = Router.call(conn, @opts)

      assert conn.state == :sent
      assert conn.status == 200

      {:ok, workout} = Workout.get_active_workout(profile.username)
      [exercise] = workout.exercises
      assert exercise.target_weight == 100
      assert exercise.target_reps == 10
    end
  end

  describe "GET /ft/profile/:username/nutrition/goals" do
    setup do
      {:ok, profile} =
        Profile.create(%{
          "first_name" => "John",
          "last_name" => "Doe",
          "username" => "johndoe",
          "password" => "password",
          "date_of_birth" => ~D[1990-01-01],
          "height" => 180,
          "weight" => 75,
          "nutrition_goals" => %{
            "calories" => 2000,
            "protein" => 150,
            "carbs" => 200,
            "fat" => 65
          }
        })

      {:ok, profile: profile}
    end

    test "gets nutrition goals", %{profile: profile} do
      conn = conn(:get, "/ft/profile/#{profile.username}/nutrition/goals")
      conn = Router.call(conn, @opts)

      assert conn.state == :sent
      assert conn.status == 200

      goals = Jason.decode!(conn.resp_body)
      assert goals["calories"] == 2000
      assert goals["protein"] == 150
      assert goals["carbs"] == 200
      assert goals["fat"] == 65
    end
  end

  describe "PUT /ft/profile/:username/nutrition/goals" do
    setup do
      {:ok, profile} =
        Profile.create(%{
          "first_name" => "John",
          "last_name" => "Doe",
          "username" => "johndoe",
          "password" => "password",
          "date_of_birth" => ~D[1990-01-01],
          "height" => 180,
          "weight" => 75
        })

      {:ok, profile: profile}
    end

    test "updates nutrition goals", %{profile: profile} do
      updated_goals = %{"calories" => 2200, "protein" => 160, "carbs" => 220, "fat" => 65}

      conn = conn(:put, "/ft/profile/#{profile.username}/nutrition/goals", updated_goals)
      conn = Router.call(conn, @opts)

      assert conn.state == :sent
      assert conn.status == 200

      conn = conn(:get, "/ft/profile/#{profile.username}/nutrition/goals")
      conn = Router.call(conn, @opts)

      goals = Jason.decode!(conn.resp_body)
      assert goals["calories"] == 2200
      assert goals["protein"] == 160
      assert goals["carbs"] == 220
      assert goals["fat"] == 65
    end
  end

  describe "GET /ft/profile/:username/nutrition/daily/:date" do
    setup do
      {:ok, profile} =
        Profile.create(%{
          "first_name" => "John",
          "last_name" => "Doe",
          "username" => "johndoe",
          "password" => "password",
          "date_of_birth" => ~D[1990-01-01],
          "height" => 180,
          "weight" => 75
        })

      meal_params = %{
        "meal" => %{
          "name" => "Breakfast",
          "date" => "2023-06-09",
          "time_eaten" => "08:00",
          "meal_type" => "breakfast",
          "calories" => 500,
          "protein" => 30,
          "carbs" => 50,
          "fat" => 15,
          "ingredients" => [%{"name" => "Eggs", "amount" => 2, "unit" => "large"}]
        }
      }

      {:ok, _} = Meal.create(profile.username, meal_params)

      {:ok, profile: profile}
    end

    test "gets daily nutrition totals", %{profile: profile} do
      conn = conn(:get, "/ft/profile/#{profile.username}/nutrition/daily/2023-06-09")
      conn = Router.call(conn, @opts)

      assert conn.state == :sent
      assert conn.status == 200

      totals = Jason.decode!(conn.resp_body)
      assert totals["calories"] == 500
      assert totals["protein"] == 30
      assert totals["carbs"] == 50
      assert totals["fat"] == 15
    end
  end

  describe "POST /ft/profile/:username/meal" do
    setup do
      {:ok, profile} =
        Profile.create(%{
          "first_name" => "John",
          "last_name" => "Doe",
          "username" => "johndoe",
          "password" => "password",
          "date_of_birth" => ~D[1990-01-01],
          "height" => 180,
          "weight" => 75
        })

      {:ok, profile: profile}
    end

    test "creates a new meal", %{profile: profile} do
      meal_params = %{
        "meal" => %{
          "name" => "Breakfast",
          "date" => "2023-06-09",
          "time_eaten" => "08:00",
          "meal_type" => "breakfast",
          "calories" => 500,
          "protein" => 30,
          "carbs" => 50,
          "fat" => 15,
          "ingredients" => [%{"name" => "Eggs", "amount" => 2, "unit" => "large"}]
        }
      }

      conn = conn(:post, "/ft/profile/#{profile.username}/meal", meal_params)
      conn = Router.call(conn, @opts)

      assert conn.state == :sent
      assert conn.status == 201
      assert Jason.decode!(conn.resp_body) == %{"message" => "Meal added successfully"}
    end

    test "returns 400 for invalid meal parameters", %{profile: profile} do
      meal_params = %{"meal" => %{"name" => "Invalid Meal"}}

      conn = conn(:post, "/ft/profile/#{profile.username}/meal", meal_params)
      conn = Router.call(conn, @opts)

      assert conn.state == :sent
      assert conn.status == 400
    end
  end

  describe "POST /ft/profile/:username/meal/template" do
    setup do
      {:ok, profile} =
        Profile.create(%{
          "first_name" => "John",
          "last_name" => "Doe",
          "username" => "johndoe",
          "password" => "password",
          "date_of_birth" => ~D[1990-01-01],
          "height" => 180,
          "weight" => 75
        })

      {:ok, profile: profile}
    end

    test "creates a new meal template", %{profile: profile} do
      meal_params = %{
        "meal" => %{
          "name" => "Breakfast Template",
          "meal_type" => "breakfast",
          "calories" => 500,
          "protein" => 30,
          "carbs" => 50,
          "fat" => 15,
          "ingredients" => [%{"name" => "Eggs", "amount" => 2, "unit" => "large"}]
        }
      }

      conn = conn(:post, "/ft/profile/#{profile.username}/meal/template", meal_params)
      conn = Router.call(conn, @opts)

      assert conn.state == :sent
      assert conn.status == 201

      assert %{"message" => "Meal template created successfully", "template" => _template} =
               Jason.decode!(conn.resp_body)
    end

    test "returns 400 for invalid meal template parameters", %{profile: profile} do
      meal_params = %{"meal" => %{"name" => "Invalid Template"}}

      conn = conn(:post, "/ft/profile/#{profile.username}/meal/template", meal_params)
      conn = Router.call(conn, @opts)

      assert conn.state == :sent
      assert conn.status == 400
    end
  end

  describe "GET /ft/profile/:username/meal/templates" do
    setup do
      {:ok, profile} =
        Profile.create(%{
          "first_name" => "John",
          "last_name" => "Doe",
          "username" => "johndoe",
          "password" => "password",
          "date_of_birth" => ~D[1990-01-01],
          "height" => 180,
          "weight" => 75
        })

      {:ok, _template} =
        Meal.create_template(profile.username, %{
          "meal" => %{
            "name" => "Breakfast Template",
            "meal_type" => "breakfast",
            "calories" => 500,
            "protein" => 30,
            "carbs" => 50,
            "fat" => 15,
            "ingredients" => [%{"name" => "Eggs", "amount" => 2, "unit" => "large"}]
          }
        })

      {:ok, profile: profile}
    end

    test "returns meal templates", %{profile: profile} do
      conn = conn(:get, "/ft/profile/#{profile.username}/meal/templates")
      conn = Router.call(conn, @opts)

      assert conn.state == :sent
      assert conn.status == 200

      %{"templates" => templates} = Jason.decode!(conn.resp_body)
      assert length(templates) == 1
      assert List.first(templates)["name"] == "Breakfast Template"
    end
  end

  describe "POST /ft/profile/:username/meal/:meal_name/:date/favorite" do
    setup do
      {:ok, profile} =
        Profile.create(%{
          "first_name" => "John",
          "last_name" => "Doe",
          "username" => "johndoe",
          "password" => "password",
          "date_of_birth" => ~D[1990-01-01],
          "height" => 180,
          "weight" => 75
        })

      meal_params = %{
        "meal" => %{
          "name" => "Breakfast",
          "date" => "2023-06-09",
          "time_eaten" => "08:00",
          "meal_type" => "breakfast",
          "calories" => 500,
          "protein" => 30,
          "carbs" => 50,
          "fat" => 15,
          "ingredients" => [%{"name" => "Eggs", "amount" => 2, "unit" => "large"}]
        }
      }

      {:ok, _meal} = Meal.create(profile.username, meal_params)

      {:ok, profile: profile}
    end

    test "toggles favorite status of a meal", %{profile: profile} do
      conn = conn(:post, "/ft/profile/#{profile.username}/meal/Breakfast/2023-06-09/favorite")
      conn = Router.call(conn, @opts)

      assert conn.state == :sent
      assert conn.status == 200

      %{"meal" => meal} = Jason.decode!(conn.resp_body)
      assert meal["is_favorite"] == true
    end
  end

  describe "GET /ft/profile/:username/meal/favorites" do
    setup do
      {:ok, profile} =
        Profile.create(%{
          "first_name" => "John",
          "last_name" => "Doe",
          "username" => "johndoe",
          "password" => "password",
          "date_of_birth" => ~D[1990-01-01],
          "height" => 180,
          "weight" => 75
        })

      meal_params = %{
        "meal" => %{
          "name" => "Favorite Meal",
          "date" => "2023-06-09",
          "time_eaten" => "08:00",
          "meal_type" => "breakfast",
          "calories" => 500,
          "protein" => 30,
          "carbs" => 50,
          "fat" => 15,
          "ingredients" => [%{"name" => "Eggs", "amount" => 2, "unit" => "large"}],
          "is_favorite" => true
        }
      }

      {:ok, _meal} = Meal.create(profile.username, meal_params)

      {:ok, profile: profile}
    end

    test "returns favorite meals", %{profile: profile} do
      conn = conn(:get, "/ft/profile/#{profile.username}/meal/favorites")
      conn = Router.call(conn, @opts)

      assert conn.state == :sent
      assert conn.status == 200

      %{"meals" => meals} = Jason.decode!(conn.resp_body)
      assert length(meals) == 1
      assert List.first(meals)["name"] == "Favorite Meal"
    end
  end

  describe "POST /ft/profile/:username/meal/:meal_name/:date/recurring" do
    setup do
      {:ok, profile} =
        Profile.create(%{
          "first_name" => "John",
          "last_name" => "Doe",
          "username" => "johndoe",
          "password" => "password",
          "date_of_birth" => ~D[1990-01-01],
          "height" => 180,
          "weight" => 75
        })

      meal_params = %{
        "meal" => %{
          "name" => "Breakfast",
          "date" => "2023-06-09",
          "time_eaten" => "08:00",
          "meal_type" => "breakfast",
          "calories" => 500,
          "protein" => 30,
          "carbs" => 50,
          "fat" => 15,
          "ingredients" => [%{"name" => "Eggs", "amount" => 2, "unit" => "large"}]
        }
      }

      {:ok, _meal} = Meal.create(profile.username, meal_params)

      {:ok, profile: profile}
    end

    test "sets a meal as recurring", %{profile: profile} do
      schedule = "Every Monday 8am"

      conn =
        conn(:post, "/ft/profile/#{profile.username}/meal/Breakfast/2023-06-09/recurring", %{
          "schedule" => schedule
        })

      conn = Router.call(conn, @opts)

      assert conn.state == :sent
      assert conn.status == 200

      %{"meal" => meal} = Jason.decode!(conn.resp_body)
      assert meal["is_recurring"] == true
      assert meal["schedule"] == schedule
    end
  end

  describe "GET /ft/profile/:username/meal/recurring" do
    setup do
      {:ok, profile} =
        Profile.create(%{
          "first_name" => "John",
          "last_name" => "Doe",
          "username" => "johndoe",
          "password" => "password",
          "date_of_birth" => ~D[1990-01-01],
          "height" => 180,
          "weight" => 75
        })

      meal_params = %{
        "meal" => %{
          "name" => "Recurring Meal",
          "date" => "2023-06-09",
          "time_eaten" => "08:00",
          "meal_type" => "breakfast",
          "calories" => 500,
          "protein" => 30,
          "carbs" => 50,
          "fat" => 15,
          "ingredients" => [%{"name" => "Eggs", "amount" => 2, "unit" => "large"}],
          "is_recurring" => true,
          "schedule" => "Every Monday 8am"
        }
      }

      {:ok, _meal} = Meal.create(profile.username, meal_params)

      {:ok, profile: profile}
    end

    test "returns recurring meals", %{profile: profile} do
      conn = conn(:get, "/ft/profile/#{profile.username}/meal/recurring")
      conn = Router.call(conn, @opts)

      assert conn.state == :sent
      assert conn.status == 200

      %{"meals" => meals} = Jason.decode!(conn.resp_body)
      assert length(meals) == 1
      assert List.first(meals)["name"] == "Recurring Meal"
    end
  end

  describe "POST /ft/profile/:username/meal/:meal_name/:date/quick-access" do
    setup do
      {:ok, profile} =
        Profile.create(%{
          "first_name" => "John",
          "last_name" => "Doe",
          "username" => "johndoe",
          "password" => "password",
          "date_of_birth" => ~D[1990-01-01],
          "height" => 180,
          "weight" => 75
        })

      meal_params = %{
        "meal" => %{
          "name" => "Breakfast",
          "date" => "2023-06-09",
          "time_eaten" => "08:00",
          "meal_type" => "breakfast",
          "calories" => 500,
          "protein" => 30,
          "carbs" => 50,
          "fat" => 15,
          "ingredients" => [%{"name" => "Eggs", "amount" => 2, "unit" => "large"}]
        }
      }

      {:ok, _meal} = Meal.create(profile.username, meal_params)

      {:ok, profile: profile}
    end

    test "toggles quick access status of a meal", %{profile: profile} do
      conn = conn(:post, "/ft/profile/#{profile.username}/meal/Breakfast/2023-06-09/quick-access")
      conn = Router.call(conn, @opts)

      assert conn.state == :sent
      assert conn.status == 200

      %{"meal" => meal} = Jason.decode!(conn.resp_body)
      assert meal["is_quick_access"] == true
    end
  end

  describe "GET /ft/profile/:username/meal/quick-access" do
    setup do
      {:ok, profile} =
        Profile.create(%{
          "first_name" => "John",
          "last_name" => "Doe",
          "username" => "johndoe",
          "password" => "password",
          "date_of_birth" => ~D[1990-01-01],
          "height" => 180,
          "weight" => 75
        })

      meal_params = %{
        "meal" => %{
          "name" => "Quick Access Meal",
          "date" => "2023-06-09",
          "time_eaten" => "08:00",
          "meal_type" => "breakfast",
          "calories" => 500,
          "protein" => 30,
          "carbs" => 50,
          "fat" => 15,
          "ingredients" => [%{"name" => "Eggs", "amount" => 2, "unit" => "large"}],
          "is_quick_access" => true
        }
      }

      {:ok, _meal} = Meal.create(profile.username, meal_params)

      {:ok, profile: profile}
    end

    test "returns quick access meals", %{profile: profile} do
      conn = conn(:get, "/ft/profile/#{profile.username}/meal/quick-access")
      conn = Router.call(conn, @opts)

      assert conn.state == :sent
      assert conn.status == 200

      %{"meals" => meals} = Jason.decode!(conn.resp_body)
      assert length(meals) == 1
      assert List.first(meals)["name"] == "Quick Access Meal"
      assert List.first(meals)["is_quick_access"] == true
    end
  end

  describe "GET /ft/profile/:username/meal" do
    setup do
      {:ok, profile} =
        Profile.create(%{
          "first_name" => "John",
          "last_name" => "Doe",
          "username" => "johndoe",
          "password" => "password",
          "date_of_birth" => ~D[1990-01-01],
          "height" => 180,
          "weight" => 75
        })

      meal_params = %{
        "meal" => %{
          "name" => "Breakfast",
          "date" => "2023-06-09",
          "time_eaten" => "08:00",
          "meal_type" => "breakfast",
          "calories" => 500,
          "protein" => 30,
          "carbs" => 50,
          "fat" => 15,
          "ingredients" => [%{"name" => "Eggs", "amount" => 2, "unit" => "large"}]
        }
      }

      {:ok, _meal} = Meal.create(profile.username, meal_params)

      {:ok, profile: profile}
    end

    test "returns all meals for a profile", %{profile: profile} do
      conn = conn(:get, "/ft/profile/#{profile.username}/meal")
      conn = Router.call(conn, @opts)

      assert conn.state == :sent
      assert conn.status == 200

      %{"meals" => meals} = Jason.decode!(conn.resp_body)
      assert length(meals) == 1
      assert List.first(meals)["name"] == "Breakfast"
    end
  end

  describe "GET /ft/profile/:username/meal/:meal_name/:date" do
    setup do
      {:ok, profile} =
        Profile.create(%{
          "first_name" => "John",
          "last_name" => "Doe",
          "username" => "johndoe",
          "password" => "password",
          "date_of_birth" => ~D[1990-01-01],
          "height" => 180,
          "weight" => 75
        })

      meal_params = %{
        "meal" => %{
          "name" => "Breakfast",
          "date" => "2023-06-09",
          "time_eaten" => "08:00",
          "meal_type" => "breakfast",
          "calories" => 500,
          "protein" => 30,
          "carbs" => 50,
          "fat" => 15,
          "ingredients" => [%{"name" => "Eggs", "amount" => 2, "unit" => "large"}]
        }
      }

      {:ok, meal} = Meal.create(profile.username, meal_params)

      {:ok, profile: profile, meal: meal}
    end

    test "returns a specific meal", %{profile: profile} do
      conn = conn(:get, "/ft/profile/#{profile.username}/meal/Breakfast/2023-06-09")
      conn = Router.call(conn, @opts)

      assert conn.state == :sent
      assert conn.status == 200

      meal = Jason.decode!(conn.resp_body)
      assert meal["name"] == "Breakfast"
      assert meal["date"] == "2023-06-09"
    end
  end

  describe "PUT /ft/profile/:username/meal/:meal_name/:date" do
    setup do
      {:ok, profile} =
        Profile.create(%{
          "first_name" => "John",
          "last_name" => "Doe",
          "username" => "johndoe",
          "password" => "password",
          "date_of_birth" => ~D[1990-01-01],
          "height" => 180,
          "weight" => 75
        })

      meal_params = %{
        "meal" => %{
          "name" => "Breakfast",
          "date" => "2023-06-09",
          "time_eaten" => "08:00",
          "meal_type" => "breakfast",
          "calories" => 500,
          "protein" => 30,
          "carbs" => 50,
          "fat" => 15,
          "ingredients" => [%{"name" => "Eggs", "amount" => 2, "unit" => "large"}]
        }
      }

      {:ok, _meal} = Meal.create(profile.username, meal_params)

      {:ok, profile: profile}
    end

    test "updates a meal", %{profile: profile} do
      update_params = %{
        "meal" => %{
          "name" => "Breakfast",
          "date" => "2023-06-09",
          "time_eaten" => "08:00",
          "meal_type" => "breakfast",
          "calories" => 600,
          "protein" => 35,
          "carbs" => 50,
          "fat" => 15,
          "ingredients" => [%{"name" => "Eggs", "amount" => 2, "unit" => "large"}]
        }
      }

      conn =
        conn(:put, "/ft/profile/#{profile.username}/meal/Breakfast/2023-06-09", update_params)

      conn = Router.call(conn, @opts)

      assert conn.state == :sent
      assert conn.status == 200

      {:ok, updated_meal} = Meal.get(profile.username, "Breakfast", "2023-06-09")
      assert updated_meal.calories == 600
      assert updated_meal.protein == 35
    end

    test "returns 400 for invalid meal parameters", %{profile: profile} do
      update_params = %{
        "meal" => %{
          "calories" => "invalid"
        }
      }

      conn =
        conn(:put, "/ft/profile/#{profile.username}/meal/Breakfast/2023-06-09", update_params)

      conn = Router.call(conn, @opts)

      assert conn.state == :sent
      assert conn.status == 400
    end
  end

  describe "DELETE /ft/profile/:username/meal/:meal_name/:date" do
    setup do
      {:ok, profile} =
        Profile.create(%{
          "first_name" => "John",
          "last_name" => "Doe",
          "username" => "johndoe",
          "password" => "password",
          "date_of_birth" => ~D[1990-01-01],
          "height" => 180,
          "weight" => 75
        })

      meal_params = %{
        "meal" => %{
          "name" => "Breakfast",
          "date" => "2023-06-09",
          "time_eaten" => "08:00",
          "meal_type" => "breakfast",
          "calories" => 500,
          "protein" => 30,
          "carbs" => 50,
          "fat" => 15,
          "ingredients" => [%{"name" => "Eggs", "amount" => 2, "unit" => "large"}]
        }
      }

      {:ok, _meal} = Meal.create(profile.username, meal_params)

      {:ok, profile: profile}
    end

    test "deletes a meal", %{profile: profile} do
      conn = conn(:delete, "/ft/profile/#{profile.username}/meal/Breakfast/2023-06-09")
      conn = Router.call(conn, @opts)

      assert conn.state == :sent
      assert conn.status == 200

      assert {:error, :not_found} = Meal.get(profile.username, "Breakfast", "2023-06-09")
    end
  end

  describe "DELETE /ft/profile/:username/meal/all" do
    setup do
      {:ok, profile} =
        Profile.create(%{
          "first_name" => "John",
          "last_name" => "Doe",
          "username" => "johndoe",
          "password" => "password",
          "date_of_birth" => ~D[1990-01-01],
          "height" => 180,
          "weight" => 75
        })

      meal_params = %{
        "meal" => %{
          "name" => "Breakfast",
          "date" => "2023-06-09",
          "time_eaten" => "08:00",
          "meal_type" => "breakfast",
          "calories" => 500,
          "protein" => 30,
          "carbs" => 50,
          "fat" => 15,
          "ingredients" => [%{"name" => "Eggs", "amount" => 2, "unit" => "large"}]
        }
      }

      {:ok, _meal} = Meal.create(profile.username, meal_params)

      {:ok, profile: profile}
    end

    test "clears the meal log", %{profile: profile} do
      conn = conn(:delete, "/ft/profile/#{profile.username}/meal/all")
      conn = Router.call(conn, @opts)

      assert conn.state == :sent
      assert conn.status == 200

      {:ok, meals} = Meal.get_all(profile.username)
      assert Enum.empty?(meals)
    end
  end

  describe "POST /ft/profile/:username/workout/start" do
    setup do
      {:ok, profile} =
        Profile.create(%{
          "first_name" => "John",
          "last_name" => "Doe",
          "username" => "johndoe",
          "password" => "password",
          "date_of_birth" => ~D[1990-01-01],
          "height" => 180,
          "weight" => 75
        })

      # Create template with proper structure
      template_data = %{
        "workout" => %{
          "workout_name" => "Chest Day",
          "exercises" => [
            %{
              "exercise_name" => "Bench Press",
              "sets" => [%{"reps" => 10, "weight" => 100}]
            }
          ],
          "length_of_workout" => 60,
          "status" => "template"
        }
      }

      {:ok, _} = Workout.save_template(profile.username, "Chest Day", template_data)
      {:ok, profile: profile}
    end

    test "starts a new workout from a template", %{profile: profile} do
      conn =
        conn(:post, "/ft/profile/#{profile.username}/workout/start", %{
          "workout_name" => "Chest Day"
        })

      conn = Router.call(conn, @opts)

      assert conn.state == :sent
      assert conn.status == 200

      {:ok, workout} = Workout.get_active_workout(profile.username)
      assert workout.workout_name == "Chest Day"
      assert workout.status == "in_progress"
    end
  end

  describe "POST /ft/profile/:username/workout/active/set" do
    setup do
      {:ok, profile} =
        Profile.create(%{
          "first_name" => "John",
          "last_name" => "Doe",
          "username" => "johndoe",
          "password" => "password",
          "date_of_birth" => ~D[1990-01-01],
          "height" => 180,
          "weight" => 75
        })

      # First create a workout template
      template_data = %{
        "workout" => %{
          "workout_name" => "Chest Day",
          "exercises" => [
            %{
              "exercise_name" => "Bench Press",
              "sets" => [%{"reps" => 10, "weight" => 100}]
            }
          ],
          "length_of_workout" => 60,
          "date_worked_out" => Date.utc_today() |> Date.to_string()
        }
      }

      # Save the template first
      {:ok, _} = Workout.save_template(profile.username, "Chest Day", template_data)
      # Then start the workout
      {:ok, _} = Workout.start_workout(profile.username, "Chest Day")

      {:ok, profile: profile}
    end

    test "completes a set in the active workout", %{profile: profile} do
      set_params = %{"reps" => 10, "weight" => 100, "rpe" => 8}

      conn = conn(:post, "/ft/profile/#{profile.username}/workout/active/set", set_params)
      conn = Router.call(conn, @opts)

      assert conn.state == :sent
      assert conn.status == 200

      {:ok, workout} = Workout.get_active_workout(profile.username)
      [exercise] = workout.exercises
      [set] = exercise.sets

      assert set.reps == 10
      assert set.weight == 100
      assert set.rpe == 8
    end
  end

  describe "PUT /ft/profile/:username/workout/active/rest" do
    # In RouterTest.ex - Update the setup block for active workout tests
    setup do
      {:ok, profile} =
        Profile.create(%{
          "first_name" => "John",
          "last_name" => "Doe",
          "username" => "johndoe",
          "password" => "password",
          "date_of_birth" => ~D[1990-01-01],
          "height" => 180,
          "weight" => 75
        })

      template_data = %{
        "workout" => %{
          "workout_name" => "Chest Day",
          "exercises" => [
            %{
              "exercise_name" => "Bench Press",
              "sets" => [%{"reps" => 10, "weight" => 100}]
            }
          ],
          "length_of_workout" => 60,
          "date_worked_out" => DateTime.utc_now() |> Date.to_string()
        }
      }

      # First save template
      {:ok, _} = Workout.save_template(profile.username, "Chest Day", template_data)
      # Then start workout
      {:ok, _} = Workout.start_workout(profile.username, "Chest Day")

      {:ok, profile: profile}
    end

    test "updates the rest timer in the active workout", %{profile: profile} do
      # First verify we have an active workout
      {:ok, initial_workout} = Workout.get_active_workout(profile.username)

      # Use simpler params format
      conn =
        conn(:put, "/ft/profile/#{profile.username}/workout/active/rest")
        |> put_req_header("content-type", "application/json")
        |> Map.put(:body_params, %{"rest_time" => 90})

      conn = Router.call(conn, @opts)

      assert conn.state == :sent
      assert conn.status == 200

      # Verify the workout was updated
      {:ok, updated_workout} = Workout.get_active_workout(profile.username)

      assert updated_workout.rest_timer_end != nil
    end
  end

  describe "POST /ft/profile/:username/workout/active/skip" do
    setup do
      {:ok, profile} =
        Profile.create(%{
          "first_name" => "John",
          "last_name" => "Doe",
          "username" => "johndoe",
          "password" => "password",
          "date_of_birth" => ~D[1990-01-01],
          "height" => 180,
          "weight" => 75
        })

      template_data = %{
        "workout" => %{
          "workout_name" => "Chest and Back Day",
          "exercises" => [
            %{
              "exercise_name" => "Bench Press",
              "sets" => [%{"reps" => 10, "weight" => 100}]
            }
          ],
          "length_of_workout" => 60,
          "date_worked_out" => Date.utc_today() |> Date.to_string()
        }
      }

      # Save the template first
      {:ok, _} = Workout.save_template(profile.username, "Chest and Back Day", template_data)

      {:ok, _} = Workout.start_workout(profile.username, "Chest and Back Day")
      {:ok, profile: profile}
    end

    test "skips an exercise in the active workout", %{profile: profile} do
      conn = conn(:post, "/ft/profile/#{profile.username}/workout/active/skip")
      conn = Router.call(conn, @opts)

      assert conn.state == :sent
      assert conn.status == 200

      {:ok, workout} = Workout.get_active_workout(profile.username)
      assert workout.current_exercise == 1
    end
  end

  describe "PUT /ft/profile/:username/workout/active/set/rpe" do
    setup do
      {:ok, profile} =
        Profile.create(%{
          "first_name" => "John",
          "last_name" => "Doe",
          "username" => "johndoe",
          "password" => "password",
          "date_of_birth" => ~D[1990-01-01],
          "height" => 180,
          "weight" => 75
        })

      template_data = %{
        "workout" => %{
          "workout_name" => "Chest Day",
          "exercises" => [
            %{
              "exercise_name" => "Bench Press",
              "sets" => [%{"reps" => 10, "weight" => 100}]
            }
          ],
          "length_of_workout" => 60,
          "date_worked_out" => Date.utc_today() |> Date.to_string()
        }
      }

      {:ok, _} = Workout.save_template(profile.username, "Chest Day", template_data)
      {:ok, _} = Workout.start_workout(profile.username, "Chest Day")

      {:ok, _} =
        Workout.complete_set(profile.username, %{"reps" => 10, "weight" => 100, "rpe" => 0})

      {:ok, profile: profile}
    end

    test "updates the RPE for a set in the active workout", %{profile: profile} do
      conn = conn(:put, "/ft/profile/#{profile.username}/workout/active/set/rpe", %{"rpe" => 8})
      conn = Router.call(conn, @opts)

      assert conn.state == :sent
      assert conn.status == 200

      {:ok, workout} = Workout.get_active_workout(profile.username)
      [exercise] = workout.exercises
      [set] = exercise.sets

      assert set.rpe == 8
    end
  end

  describe "PUT /ft/profile/:username/workout/active/notes" do
    setup do
      {:ok, profile} =
        Profile.create(%{
          "first_name" => "John",
          "last_name" => "Doe",
          "username" => "johndoe",
          "password" => "password",
          "date_of_birth" => ~D[1990-01-01],
          "height" => 180,
          "weight" => 75
        })

      # Save template
      template_data = %{
        "workout" => %{
          "workout_name" => "Chest Day",
          "exercises" => [
            %{
              "exercise_name" => "Bench Press",
              "sets" => [%{"reps" => 10, "weight" => 100}]
            }
          ],
          "length_of_workout" => 60
        }
      }

      {:ok, template_result} = Workout.save_template(profile.username, "Chest Day", template_data)

      # Start workout
      {:ok, active_workout} = Workout.start_workout(profile.username, "Chest Day")

      {:ok, profile: profile}
    end

    test "updates notes for the active workout", %{profile: profile} do
      # Verify active workout exists before update
      {:ok, before_workout} = Workout.get_active_workout(profile.username)

      # Create and inspect request
      params = %{"notes" => "Feeling strong today"}

      conn =
        conn(:put, "/ft/profile/#{profile.username}/workout/active/notes", params)

      conn = Router.call(conn, @opts)

      assert conn.state == :sent
      assert conn.status == 200

      {:ok, workout} = Workout.get_active_workout(profile.username)
      assert workout.notes == "Feeling strong today"
    end
  end

  describe "POST /ft/profile/:username/workout/end" do
    setup do
      {:ok, profile} =
        Profile.create(%{
          "first_name" => "John",
          "last_name" => "Doe",
          "username" => "johndoe",
          "password" => "password",
          "date_of_birth" => ~D[1990-01-01],
          "height" => 180,
          "weight" => 75
        })

      template_data = %{
        "workout" => %{
          "workout_name" => "Chest Day",
          "exercises" => [
            %{
              "exercise_name" => "Bench Press",
              "sets" => [%{"reps" => 10, "weight" => 100}]
            }
          ],
          "length_of_workout" => 60,
          "date_worked_out" => Date.utc_today() |> Date.to_string()
        }
      }

      {:ok, _} = Workout.save_template(profile.username, "Chest Day", template_data)

      {:ok, _} = Workout.start_workout(profile.username, "Chest Day")

      {:ok, profile: profile}
    end

    test "ends the active workout", %{profile: profile} do
      # Verify initial state
      {:ok, initial_workout} = Workout.get_active_workout(profile.username)
      IO.inspect(initial_workout, label: "Initial active workout")

      # End workout
      conn = conn(:post, "/ft/profile/#{profile.username}/workout/end")
      conn = Router.call(conn, @opts)

      IO.inspect(conn.status, label: "Response status")
      IO.inspect(Jason.decode!(conn.resp_body), label: "Response body")

      assert conn.state == :sent
      assert conn.status == 200

      # Verify no active workout
      result = Workout.get_active_workout(profile.username)
      IO.inspect(result, label: "Active workout after end")
      assert match?({:error, :no_active_workout}, result)

      # Get the completed workout
      date = Date.utc_today() |> Date.to_string()
      result = Workout.get(profile.username, "Chest Day", date)
      IO.inspect(result, label: "Get workout result")

      case result do
        {:ok, workout} ->
          IO.inspect(workout, label: "Retrieved workout")
          assert workout.status == "completed"

        other ->
          IO.inspect(other, label: "Unexpected result from get workout")
          flunk("Expected {:ok, workout}, got #{inspect(other)}")
      end
    end
  end

  describe "GET /ft/profile/:username/workout/history" do
    setup do
      {:ok, profile} =
        Profile.create(%{
          "first_name" => "John",
          "last_name" => "Doe",
          "username" => "johndoe",
          "password" => "password",
          "date_of_birth" => ~D[1990-01-01],
          "height" => 180,
          "weight" => 75
        })

      workout_params = %{
        "workout" => %{
          "workout_name" => "Chest Day",
          "exercises" => [
            %{
              "exercise_name" => "Bench Press",
              "sets" => [
                %{
                  "reps" => 10,
                  "weight" => 100,
                  "completed_at" => DateTime.utc_now() |> DateTime.to_iso8601()
                }
              ]
            }
          ],
          "length_of_workout" => 60,
          "date_worked_out" => Date.utc_today() |> Date.to_string(),
          "status" => "completed"
        }
      }

      {:ok, _} = Workout.create(profile.username, workout_params)
      {:ok, profile: profile}
    end

    test "retrieves workout history", %{profile: profile} do
      conn = conn(:get, "/ft/profile/#{profile.username}/workout/history")
      conn = Router.call(conn, @opts)

      assert conn.state == :sent
      assert conn.status == 200

      %{"history" => [history]} = Jason.decode!(conn.resp_body)
      assert history["name"] == "Chest Day"
      assert history["volume"] > 0
    end
  end

  describe "GET /ft/profile/:username/workout/active/stats" do
    setup do
      {:ok, profile} =
        Profile.create(%{
          "first_name" => "John",
          "last_name" => "Doe",
          "username" => "johndoe",
          "password" => "password",
          "date_of_birth" => ~D[1990-01-01],
          "height" => 180,
          "weight" => 75
        })

      # Create and start a workout
      template_data = %{
        "workout" => %{
          "workout_name" => "Chest Day",
          "exercises" => [
            %{
              "exercise_name" => "Bench Press",
              "sets" => [%{"reps" => 10, "weight" => 100}]
            }
          ],
          "length_of_workout" => 60
        }
      }

      {:ok, _} = Workout.save_template(profile.username, "Chest Day", template_data)
      {:ok, _} = Workout.start_workout(profile.username, "Chest Day")

      {:ok, _} =
        Workout.complete_set(profile.username, %{"reps" => 10, "weight" => 100, "rpe" => 8})

      {:ok, profile: profile}
    end

    test "gets stats for the active workout", %{profile: profile} do
      conn = conn(:get, "/ft/profile/#{profile.username}/workout/active/stats")
      conn = Router.call(conn, @opts)

      assert conn.state == :sent
      assert conn.status == 200

      stats = Jason.decode!(conn.resp_body)
      # 10 reps * 100 weight
      assert stats["total_volume"] == 1000
      assert stats["average_rpe"] == 8.0
      assert stats["sets_completed"] == 1
      assert stats["total_sets"] == 1
    end
  end
end
