defmodule GymBro.Meals do
  @moduledoc """
  The Meals context: meal CRUD scoped per user/date, favorites, recurring,
  quick-access, templates, and daily nutrition totals.
  """

  import Ecto.Query, warn: false

  alias Ecto.Multi
  alias GymBro.Accounts
  alias GymBro.Accounts.User
  alias GymBro.{Ingredient, Meal, MealLog, Repo}
  alias GymBro.Meals.{AnalysisCache, MealTemplate, USDA, Vision}

  ## Meals CRUD

  def list_meals(%User{} = user) do
    Meal
    |> join(:inner, [m], l in MealLog, on: m.meal_log_id == l.id)
    |> where([_, l], l.user_id == ^user.id)
    |> order_by([_, l], desc: l.date)
    |> preload([:ingredients, :meal_log])
    |> Repo.all()
    |> Enum.map(&attach_date/1)
  end

  def list_meals_on(%User{} = user, %Date{} = date) do
    Meal
    |> join(:inner, [m], l in MealLog, on: m.meal_log_id == l.id)
    |> where([_, l], l.user_id == ^user.id and l.date == ^date)
    |> preload([:ingredients, :meal_log])
    |> Repo.all()
    |> Enum.map(&attach_date/1)
  end

  def get_meal(%User{} = user, name, %Date{} = date) do
    Meal
    |> join(:inner, [m], l in MealLog, on: m.meal_log_id == l.id)
    |> where([m, l], l.user_id == ^user.id and m.name == ^name and l.date == ^date)
    |> preload([:ingredients, :meal_log])
    |> Repo.one()
    |> case do
      nil -> {:error, :not_found}
      meal -> {:ok, attach_date(meal)}
    end
  end

  defp attach_date(%Meal{meal_log: %MealLog{date: d}} = meal), do: %{meal | date: d}
  defp attach_date(meal), do: meal

  @doc """
  Creates a meal on the user's meal_log for the given date (auto-creating the
  log if needed). Ingredients are passed as a list of maps with at least a
  "name" key; they are looked up by name or created.
  """
  def create_meal(%User{} = user, attrs) do
    attrs = stringify(attrs)
    date = parse_date(attrs["date"])

    cond do
      is_nil(date) ->
        {:error, :invalid_date}

      true ->
        case Accounts.ensure_meal_log(user, date) do
          {:ok, log} ->
            ingredient_attrs = List.wrap(attrs["ingredients"])

            Multi.new()
            |> Multi.run(:ingredients, fn _repo, _ ->
              upsert_ingredients(ingredient_attrs)
            end)
            |> Multi.insert(:meal, fn %{ingredients: ingredients} ->
              %Meal{}
              |> Meal.changeset(
                attrs
                |> Map.put("meal_log_id", log.id)
                |> Map.put("date", date)
              )
              |> Ecto.Changeset.put_assoc(:ingredients, ingredients)
            end)
            |> Repo.transaction()
            |> case do
              {:ok, %{meal: meal}} ->
                {:ok, meal |> Repo.preload([:ingredients, :meal_log]) |> attach_date()}

              {:error, _step, changeset, _} ->
                {:error, changeset}
            end

          error ->
            error
        end
    end
  end

  def update_meal(%User{} = user, name, %Date{} = date, attrs) do
    with {:ok, meal} <- get_meal(user, name, date),
         :ok <- ensure_editable(meal) do
      attrs = stringify(attrs)
      ingredient_attrs = List.wrap(attrs["ingredients"])

      Multi.new()
      |> Multi.run(:ingredients, fn _repo, _ ->
        if ingredient_attrs == [], do: {:ok, meal.ingredients}, else: upsert_ingredients(ingredient_attrs)
      end)
      |> Multi.update(:meal, fn %{ingredients: ingredients} ->
        meal
        |> Meal.changeset(Map.drop(attrs, ["ingredients"]))
        |> Ecto.Changeset.put_assoc(:ingredients, ingredients)
      end)
      |> Repo.transaction()
      |> case do
        {:ok, %{meal: meal}} ->
          {:ok, meal |> Repo.preload([:ingredients, :meal_log]) |> attach_date()}

        {:error, _step, changeset, _} ->
          {:error, changeset}
      end
    end
  end

  defp ensure_editable(meal) do
    if Meal.editable?(meal), do: :ok, else: {:error, :locked}
  end

  def delete_meal(%User{} = user, name, %Date{} = date) do
    with {:ok, meal} <- get_meal(user, name, date) do
      Repo.delete(meal)
    end
  end

  ## Flags

  def list_favorites(%User{} = user), do: list_with_flag(user, :is_favorite)
  def list_quick_access(%User{} = user), do: list_with_flag(user, :is_quick_access)
  def list_recurring(%User{} = user), do: list_with_flag(user, :is_recurring)

  def toggle_favorite(%User{} = user, name, %Date{} = date) do
    flip_flag(user, name, date, :is_favorite)
  end

  def toggle_quick_access(%User{} = user, name, %Date{} = date) do
    flip_flag(user, name, date, :is_quick_access)
  end

  def set_recurring(%User{} = user, name, %Date{} = date, schedule) when is_binary(schedule) do
    with {:ok, meal} <- get_meal(user, name, date) do
      meal
      |> Meal.changeset(%{is_recurring: true, schedule: schedule})
      |> Repo.update()
      |> case do
        {:ok, updated} -> {:ok, %{updated | date: date}}
        error -> error
      end
    end
  end

  ## Templates

  def list_templates(%User{} = user) do
    MealTemplate
    |> where(user_id: ^user.id)
    |> order_by([t], asc: t.name)
    |> Repo.all()
  end

  def get_template(%User{} = user, name) do
    case Repo.get_by(MealTemplate, user_id: user.id, name: name) do
      nil -> {:error, :template_not_found}
      t -> {:ok, t}
    end
  end

  def create_template(%User{} = user, attrs) do
    %MealTemplate{}
    |> MealTemplate.changeset(Map.put(stringify(attrs), "user_id", user.id))
    |> Repo.insert()
  end

  def delete_template(%MealTemplate{} = template), do: Repo.delete(template)

  ## Daily nutrition aggregation

  def daily_totals(%User{} = user, %Date{} = date) do
    meals = list_meals_on(user, date)

    totals =
      Enum.reduce(meals, %{calories: 0, protein: 0.0, carbs: 0.0, fat: 0.0}, fn m, acc ->
        %{
          calories: acc.calories + (m.calories || 0),
          protein: acc.protein + (m.protein || 0.0),
          carbs: acc.carbs + (m.carbs || 0.0),
          fat: acc.fat + (m.fat || 0.0)
        }
      end)

    Map.put(totals, :meals, Enum.map(meals, &meal_summary/1))
  end

  ## Photo analysis

  @doc """
  Takes an uploaded meal photo, asks Claude to identify items + grams, looks
  each up in USDA, and returns a prefilled meal payload (no DB write — the
  user reviews and saves through the normal create_meal/2 flow).

  Returns:
    {:ok, %{
      meal_name: "...",
      meal_type: "...",
      calories: int,
      protein: float,
      carbs: float,
      fat: float,
      ingredients: [%{name, amount, unit, calories, protein, carbs, fat, confidence}],
      overall_confidence: "low" | "medium" | "high",
      warnings: [...]
    }}
  """
  def analyze_photo(%User{} = user, image_bytes, media_type) do
    favorites = collect_favorites_for_hint(user)

    with {:ok, parsed} <- Vision.analyze(image_bytes, media_type, favorites: favorites) do
      result = assemble_analysis_result(parsed)
      analysis_id = AnalysisCache.put(user.id, image_bytes, media_type, parsed)
      {:ok, Map.put(result, :analysis_id, analysis_id)}
    end
  end

  @doc """
  Takes a natural-language meal description (e.g. "4 eggs with olive oil,
  glass of OJ, half a cup of rice") and returns the same prefilled payload
  as `analyze_photo/3`. No DB write — user reviews and saves via the normal
  create_meal flow.
  """
  def analyze_text(%User{} = user, description) when is_binary(description) do
    trimmed = String.trim(description)

    cond do
      trimmed == "" ->
        {:error, :empty_description}

      true ->
        favorites = collect_favorites_for_hint(user)

        with {:ok, parsed} <- Vision.analyze_text(trimmed, favorites: favorites) do
          result = assemble_analysis_result(parsed)
          analysis_id = AnalysisCache.put_text(user.id, trimmed, parsed)
          {:ok, Map.put(result, :analysis_id, analysis_id)}
        end
    end
  end

  def analyze_text(_user, _), do: {:error, :empty_description}

  @doc """
  Re-runs the analysis with user feedback applied. The image and previous
  analysis are looked up from the in-memory cache by `analysis_id`. Returns
  the same shape as analyze_photo/3, plus a `reply` string.

  `history` is the prior chat turns excluding the current message:
  [%{role: "user" | "assistant", text: "..."}, ...]
  """
  def refine_analysis(%User{} = user, analysis_id, message, history)
      when is_binary(analysis_id) and is_binary(message) and is_list(history) do
    with {:ok, entry} <- AnalysisCache.get(analysis_id, user.id) do
      next_history = history ++ [%{role: "user", text: message}]

      vision_result =
        case Map.get(entry, :kind, :photo) do
          :photo ->
            Vision.refine(entry.image_bytes, entry.media_type, entry.analysis, next_history)

          :text ->
            Vision.refine_text(entry.description, entry.analysis, next_history)
        end

      with {:ok, parsed} <- vision_result do
        AnalysisCache.update_analysis(analysis_id, parsed)
        result = assemble_analysis_result(parsed)

        {:ok,
         result
         |> Map.put(:analysis_id, analysis_id)
         |> Map.put(:reply, parsed["reply"] || "Updated.")}
      end
    end
  end

  defp assemble_analysis_result(parsed) do
    items = (parsed["items"] || []) |> Enum.map(&resolve_item/1)

    totals =
      Enum.reduce(items, %{kcal: 0, protein: 0.0, carbs: 0.0, fat: 0.0}, fn item, acc ->
        %{
          kcal: acc.kcal + (item.calories || 0),
          protein: acc.protein + (item.protein || 0.0),
          carbs: acc.carbs + (item.carbs || 0.0),
          fat: acc.fat + (item.fat || 0.0)
        }
      end)

    %{
      meal_name: parsed["meal_name"] || "Meal",
      meal_type: parsed["meal_type"] || guess_meal_type(),
      calories: totals.kcal,
      protein: Float.round(totals.protein, 1),
      carbs: Float.round(totals.carbs, 1),
      fat: Float.round(totals.fat, 1),
      ingredients: items,
      overall_confidence: parsed["overall_confidence"] || "medium",
      warnings: parsed["warnings"] || []
    }
  end

  defp collect_favorites_for_hint(%User{} = user) do
    favorites = list_favorites(user) |> Enum.map(& &1.name)
    quick = list_quick_access(user) |> Enum.map(& &1.name)
    (favorites ++ quick) |> Enum.uniq() |> Enum.take(30)
  end

  defp resolve_item(item) do
    name = item["name"] || ""
    grams = item["grams"] || 0
    confidence = item["confidence"] || "medium"
    notes = item["prep_notes"]

    case USDA.find(name) do
      {:ok, entry} ->
        macros = USDA.macros_for(entry, grams)

        %{
          name: name,
          amount: grams,
          unit: "g",
          calories: macros.kcal,
          protein: macros.protein,
          carbs: macros.carbs,
          fat: macros.fat,
          confidence: confidence,
          prep_notes: notes,
          source: "usda"
        }

      {:error, _reason} ->
        # No USDA match — surface the LLM's identification without macros so
        # the user can fill them in manually.
        %{
          name: name,
          amount: grams,
          unit: "g",
          calories: nil,
          protein: nil,
          carbs: nil,
          fat: nil,
          confidence: "low",
          prep_notes: notes,
          source: "unmatched"
        }
    end
  end

  defp guess_meal_type do
    hour = DateTime.utc_now() |> Map.get(:hour)

    cond do
      hour < 10 -> "breakfast"
      hour < 15 -> "lunch"
      hour < 21 -> "dinner"
      true -> "snack"
    end
  end

  ## Private helpers

  defp list_with_flag(%User{} = user, flag) do
    Meal
    |> join(:inner, [m], l in MealLog, on: m.meal_log_id == l.id)
    |> where([m, l], l.user_id == ^user.id and field(m, ^flag) == true)
    |> preload([:ingredients, :meal_log])
    |> Repo.all()
    |> Enum.map(&attach_date/1)
  end

  defp flip_flag(%User{} = user, name, date, flag) do
    with {:ok, meal} <- get_meal(user, name, date) do
      meal
      |> Meal.changeset(%{flag => not Map.get(meal, flag, false)})
      |> Repo.update()
      |> case do
        {:ok, updated} -> {:ok, %{updated | date: date}}
        error -> error
      end
    end
  end

  defp upsert_ingredients(attrs_list) when is_list(attrs_list) do
    ingredients =
      Enum.map(attrs_list, fn attrs ->
        attrs = stringify(attrs)
        name = attrs["name"]

        if is_binary(name) and name != "" do
          case Repo.get_by(Ingredient, name: name) do
            nil ->
              %Ingredient{}
              |> Ingredient.changeset(attrs)
              |> Repo.insert!()

            existing ->
              existing
          end
        else
          nil
        end
      end)
      |> Enum.reject(&is_nil/1)

    {:ok, ingredients}
  end

  defp upsert_ingredients(_), do: {:ok, []}

  defp meal_summary(meal) do
    %{
      name: meal.name,
      time: meal.time_eaten,
      type: meal.meal_type,
      calories: meal.calories,
      macros: %{protein: meal.protein, carbs: meal.carbs, fat: meal.fat},
      ingredients: Enum.map(meal.ingredients, & &1.name)
    }
  end

  defp parse_date(%Date{} = d), do: d
  defp parse_date(s) when is_binary(s), do: Date.from_iso8601(s) |> elem_or_nil()
  defp parse_date(_), do: nil

  defp elem_or_nil({:ok, v}), do: v
  defp elem_or_nil(_), do: nil

  defp stringify(map) when is_map(map) do
    Map.new(map, fn {k, v} -> {to_string(k), v} end)
  end
end
