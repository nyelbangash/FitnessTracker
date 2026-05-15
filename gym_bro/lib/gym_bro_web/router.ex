defmodule GymBroWeb.Router do
  use GymBroWeb, :router

  import GymBroWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {GymBroWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :api_authenticated do
    plug :accepts, ["json"]
    plug GymBroWeb.Plugs.ApiAuth
  end

  pipeline :api_authenticated_multipart do
    plug :accepts, ["json", "multipart"]
    plug GymBroWeb.Plugs.ApiAuth
  end

  scope "/", GymBroWeb do
    pipe_through :browser

    get "/", PageController, :home
    get "/hello", HelloController, :index
    get "/hello/:messenger", HelloController, :show
  end

  scope "/api", GymBroWeb.Api, as: :api do
    pipe_through :api

    post "/users", UserController, :create
    post "/login", SessionController, :create
  end

  scope "/api", GymBroWeb.Api, as: :api do
    pipe_through :api_authenticated

    delete "/logout", SessionController, :delete

    get "/me", UserController, :show
    put "/me", UserController, :update

    get "/nutrition/goals", NutritionController, :goals
    put "/nutrition/goals", NutritionController, :update_goals
    get "/nutrition/daily/:date", NutritionController, :daily

    get "/workouts", WorkoutController, :index
    get "/workouts/active", WorkoutController, :active
    post "/workouts/active/start", WorkoutController, :start
    post "/workouts/active/set", WorkoutController, :complete_set
    put "/workouts/active/set/rpe", WorkoutController, :update_set_rpe
    post "/workouts/active/skip", WorkoutController, :skip_exercise
    put "/workouts/active/rest", WorkoutController, :update_rest_timer
    put "/workouts/active/notes", WorkoutController, :update_notes
    put "/workouts/active/exercise/targets", WorkoutController, :update_exercise_targets
    post "/workouts/active/end", WorkoutController, :end_active
    get "/workouts/active/stats", WorkoutController, :stats
    get "/workouts/history", WorkoutController, :history
    get "/workouts/templates", WorkoutController, :list_templates
    post "/workouts/templates", WorkoutController, :create_template
    post "/workouts/templates/from-workout", WorkoutController, :save_as_template
    put "/workouts/templates/:template_name", WorkoutController, :update_template
    delete "/workouts/templates/:template_name", WorkoutController, :delete_template
    get "/workouts/:workout_name/:date", WorkoutController, :show
    delete "/workouts/:workout_name/:date", WorkoutController, :delete
    get "/workouts/:workout_name/:date/summary", WorkoutController, :summary

    get "/meals", MealController, :index
    post "/meals", MealController, :create
    # /meals/analyze is multipart and lives in its own scope below

    get "/meals/favorites", MealController, :favorites
    get "/meals/quick-access", MealController, :quick_access
    get "/meals/recurring", MealController, :recurring
    get "/meals/templates", MealController, :list_templates
    post "/meals/templates", MealController, :create_template
    delete "/meals/templates/:template_name", MealController, :delete_template
    get "/meals/:meal_name/:date", MealController, :show
    put "/meals/:meal_name/:date", MealController, :update
    delete "/meals/:meal_name/:date", MealController, :delete
    post "/meals/:meal_name/:date/favorite", MealController, :toggle_favorite
    post "/meals/:meal_name/:date/quick-access", MealController, :toggle_quick_access
    post "/meals/:meal_name/:date/recurring", MealController, :set_recurring

    post "/meals/analyze/refine", MealController, :refine
  end

  scope "/api", GymBroWeb.Api, as: :api_multipart do
    pipe_through :api_authenticated_multipart

    post "/meals/analyze", MealController, :analyze
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:gym_bro, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: GymBroWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", GymBroWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{GymBroWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live "/users/register", UserRegistrationLive, :new
      live "/users/log_in", UserLoginLive, :new
      live "/users/reset_password", UserForgotPasswordLive, :new
      live "/users/reset_password/:token", UserResetPasswordLive, :edit
    end

    post "/users/log_in", UserSessionController, :create
  end

  scope "/", GymBroWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{GymBroWeb.UserAuth, :ensure_authenticated}] do
      live "/users/settings", UserSettingsLive, :edit
      live "/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email
    end
  end

  scope "/", GymBroWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete

    live_session :current_user,
      on_mount: [{GymBroWeb.UserAuth, :mount_current_user}] do
      live "/users/confirm/:token", UserConfirmationLive, :edit
      live "/users/confirm", UserConfirmationInstructionsLive, :new
    end
  end
end
