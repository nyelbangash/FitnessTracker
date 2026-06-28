defmodule GymBroWeb.Api.MealController do
  use GymBroWeb, :controller

  alias GymBro.Meals
  alias GymBroWeb.Api.Helpers

  action_fallback GymBroWeb.Api.FallbackController

  ## Meals

  def index(conn, _params) do
    meals = Meals.list_meals(conn.assigns.current_user)
    json(conn, %{meals: Enum.map(meals, &render_meal/1)})
  end

  def show(conn, %{"meal_name" => name, "date" => date_str}) do
    with {:ok, date} <- Helpers.parse_date(date_str),
         {:ok, meal} <- Meals.get_meal(conn.assigns.current_user, name, date) do
      json(conn, %{meal: render_meal(meal)})
    end
  end

  def create(conn, params) do
    attrs = params["meal"] || params

    with {:ok, meal} <- Meals.create_meal(conn.assigns.current_user, attrs) do
      conn
      |> put_status(:created)
      |> json(%{meal: render_meal(meal)})
    end
  end

  def update(conn, %{"meal_name" => name, "date" => date_str} = params) do
    attrs = params["meal"] || Map.drop(params, ~w(meal_name date))

    with {:ok, date} <- Helpers.parse_date(date_str),
         {:ok, meal} <- Meals.update_meal(conn.assigns.current_user, name, date, attrs) do
      json(conn, %{meal: render_meal(meal)})
    end
  end

  def delete(conn, %{"meal_name" => name, "date" => date_str}) do
    with {:ok, date} <- Helpers.parse_date(date_str),
         {:ok, _} <- Meals.delete_meal(conn.assigns.current_user, name, date) do
      send_resp(conn, :no_content, "")
    end
  end

  ## Flags

  def favorites(conn, _params) do
    json(conn, %{meals: Enum.map(Meals.list_favorites(conn.assigns.current_user), &render_meal/1)})
  end

  def toggle_favorite(conn, %{"meal_name" => name, "date" => date_str}) do
    with {:ok, date} <- Helpers.parse_date(date_str),
         {:ok, meal} <- Meals.toggle_favorite(conn.assigns.current_user, name, date) do
      json(conn, %{meal: render_meal(meal)})
    end
  end

  def quick_access(conn, _params) do
    json(conn, %{meals: Enum.map(Meals.list_quick_access(conn.assigns.current_user), &render_meal/1)})
  end

  def toggle_quick_access(conn, %{"meal_name" => name, "date" => date_str}) do
    with {:ok, date} <- Helpers.parse_date(date_str),
         {:ok, meal} <- Meals.toggle_quick_access(conn.assigns.current_user, name, date) do
      json(conn, %{meal: render_meal(meal)})
    end
  end

  def recurring(conn, _params) do
    json(conn, %{meals: Enum.map(Meals.list_recurring(conn.assigns.current_user), &render_meal/1)})
  end

  def set_recurring(conn, %{"meal_name" => name, "date" => date_str, "schedule" => schedule}) do
    with {:ok, date} <- Helpers.parse_date(date_str),
         {:ok, meal} <- Meals.set_recurring(conn.assigns.current_user, name, date, schedule) do
      json(conn, %{meal: render_meal(meal)})
    end
  end

  ## Photo analysis

  def analyze(conn, %{"image" => %Plug.Upload{} = upload}) do
    case File.read(upload.path) do
      {:ok, bytes} ->
        media_type = upload.content_type || "image/jpeg"

        case Meals.analyze_photo(conn.assigns.current_user, bytes, media_type) do
          {:ok, result} ->
            json(conn, %{analysis: result})

          {:error, :missing_api_key} ->
            conn
            |> put_status(:service_unavailable)
            |> json(%{error: "vision_unavailable", detail: "ANTHROPIC_API_KEY not configured"})

          {:error, {:upstream, status, body}} ->
            conn
            |> put_status(:bad_gateway)
            |> json(%{error: "vision_upstream", status: status, detail: inspect(body)})

          {:error, reason} ->
            conn
            |> put_status(:bad_gateway)
            |> json(%{error: "analysis_failed", detail: inspect(reason)})
        end

      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: "image_read_failed", detail: inspect(reason)})
    end
  end

  def analyze(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "missing_image"})
  end

  def analyze_text(conn, %{"description" => description}) when is_binary(description) do
    case Meals.analyze_text(conn.assigns.current_user, description) do
      {:ok, result} ->
        json(conn, %{analysis: result})

      {:error, :empty_description} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: "empty_description"})

      {:error, :missing_api_key} ->
        conn
        |> put_status(:service_unavailable)
        |> json(%{error: "vision_unavailable", detail: "ANTHROPIC_API_KEY not configured"})

      {:error, {:upstream, status, body}} ->
        conn
        |> put_status(:bad_gateway)
        |> json(%{error: "vision_upstream", status: status, detail: inspect(body)})

      {:error, reason} ->
        conn
        |> put_status(:bad_gateway)
        |> json(%{error: "analysis_failed", detail: inspect(reason)})
    end
  end

  def analyze_text(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "missing_description"})
  end

  def refine(conn, %{"analysis_id" => analysis_id, "message" => message} = params) do
    history =
      case params["history"] do
        list when is_list(list) ->
          Enum.flat_map(list, fn
            %{"role" => role, "text" => text} when role in ["user", "assistant"] ->
              [%{role: role, text: to_string(text)}]

            _ ->
              []
          end)

        _ ->
          []
      end

    case Meals.refine_analysis(conn.assigns.current_user, analysis_id, message, history) do
      {:ok, result} ->
        json(conn, %{analysis: result})

      {:error, :not_found} ->
        conn |> put_status(:not_found) |> json(%{error: "analysis_not_found"})

      {:error, :expired} ->
        conn |> put_status(:gone) |> json(%{error: "analysis_expired"})

      {:error, :forbidden} ->
        conn |> put_status(:forbidden) |> json(%{error: "forbidden"})

      {:error, :missing_api_key} ->
        conn
        |> put_status(:service_unavailable)
        |> json(%{error: "vision_unavailable"})

      {:error, {:upstream, status, body}} ->
        conn
        |> put_status(:bad_gateway)
        |> json(%{error: "vision_upstream", status: status, detail: inspect(body)})

      {:error, reason} ->
        conn
        |> put_status(:bad_gateway)
        |> json(%{error: "refine_failed", detail: inspect(reason)})
    end
  end

  def refine(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "missing_analysis_id_or_message"})
  end

  ## Templates

  def list_templates(conn, _params) do
    templates = Meals.list_templates(conn.assigns.current_user)
    json(conn, %{templates: Enum.map(templates, &render_template/1)})
  end

  def create_template(conn, params) do
    attrs = params["template"] || params["meal"] || params

    with {:ok, template} <- Meals.create_template(conn.assigns.current_user, attrs) do
      conn
      |> put_status(:created)
      |> json(%{template: render_template(template)})
    end
  end

  def delete_template(conn, %{"template_name" => name}) do
    with {:ok, template} <- Meals.get_template(conn.assigns.current_user, name),
         {:ok, _} <- Meals.delete_template(template) do
      send_resp(conn, :no_content, "")
    end
  end

  ## Rendering

  defp render_meal(meal) do
    %{
      id: meal.id,
      name: meal.name,
      date: meal.date,
      time_eaten: meal.time_eaten,
      meal_type: meal.meal_type,
      calories: meal.calories,
      protein: meal.protein,
      carbs: meal.carbs,
      fat: meal.fat,
      is_favorite: meal.is_favorite,
      is_recurring: meal.is_recurring,
      is_quick_access: meal.is_quick_access,
      template_name: meal.template_name,
      notes: meal.notes,
      schedule: meal.schedule,
      editable: GymBro.Meal.editable?(meal),
      editable_until: GymBro.Meal.editable_until(meal),
      ingredients: render_ingredients(meal.ingredients)
    }
  end

  defp render_ingredients(%Ecto.Association.NotLoaded{}), do: []
  defp render_ingredients(ingredients) when is_list(ingredients) do
    Enum.map(ingredients, fn i ->
      %{
        id: i.id,
        name: i.name,
        amount: i.amount,
        unit: i.unit,
        calories: i.calories,
        protein: i.protein,
        carbs: i.carbs,
        fat: i.fat
      }
    end)
  end

  defp render_template(t) do
    %{
      id: t.id,
      name: t.name,
      meal_type: t.meal_type,
      calories: t.calories,
      protein: t.protein,
      carbs: t.carbs,
      fat: t.fat,
      ingredients: t.ingredients,
      notes: t.notes
    }
  end
end
