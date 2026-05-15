defmodule GymBro.Meals.USDA do
  @moduledoc """
  Thin wrapper around USDA FoodData Central. Caches lookups in food_cache so
  repeated meals don't hammer the upstream API.

  USDA returns nutrient values per 100g (or per 100mL for liquids) which we
  store canonically; portion math happens at the call site.

  Lookup strategy: try the exact name first; if no useful match, progressively
  simplify the query (drop adjectives, drop the rightmost word) and retry.
  Prefer SR Legacy / Foundation entries over Branded products for generic
  ingredient names, since Branded results often return zero-macro placeholders.
  """

  import Ecto.Query, warn: false
  require Logger
  alias GymBro.Repo
  alias GymBro.Meals.FoodCacheEntry

  @base "https://api.nal.usda.gov/fdc/v1"

  # USDA nutrient IDs. These are stable.
  @kcal 1008
  @protein 1003
  @fat 1004
  @carbs 1005

  @doc """
  Looks up a food by name. Returns a FoodCacheEntry (cached or freshly
  fetched). Falls back to {:error, reason} on upstream failure or no match.
  """
  def find(name) when is_binary(name) do
    normalized = normalize(name)

    case Repo.get_by(FoodCacheEntry, name: normalized) do
      %FoodCacheEntry{} = entry ->
        {:ok, entry}

      nil ->
        with {:ok, parsed} <- search_with_fallbacks(normalized) do
          upsert(parsed, normalized)
        end
    end
  end

  def find(_), do: {:error, :invalid_name}

  defp normalize(name), do: name |> String.trim() |> String.downcase()

  # Try the original query, then progressively simpler ones. Return the first
  # search that yields a useful (non-zero kcal) match.
  defp search_with_fallbacks(query) do
    candidates = query_candidates(query)

    Enum.reduce_while(candidates, {:error, :no_match}, fn candidate, _acc ->
      case fetch_best_match(candidate) do
        {:ok, parsed} = ok ->
          if parsed.kcal_per_100g > 0 or parsed.protein_per_100g > 0 or
               parsed.fat_per_100g > 0 do
            {:halt, ok}
          else
            # Zero-macro result usually means a Branded placeholder with no
            # nutrition data. Try the next candidate.
            {:cont, ok}
          end

        {:error, _} = err ->
          {:cont, err}
      end
    end)
  end

  defp query_candidates(query) do
    words = String.split(query)

    base =
      case words do
        [] -> []
        [w] -> [w]
        _ ->
          # Try original, then simplified to last 2 words, then last word.
          # E.g., "chicken tenders fried breaded" → ["chicken tenders fried breaded",
          # "fried breaded", "breaded", "chicken tenders", "chicken"]
          last_two = words |> Enum.take(-2) |> Enum.join(" ")
          last_one = List.last(words)
          first_two = words |> Enum.take(2) |> Enum.join(" ")
          first_one = List.first(words)

          [query, last_two, first_two, first_one, last_one]
      end

    Enum.uniq(base)
  end

  defp fetch_best_match(query) do
    api_key = System.get_env("USDA_FDC_API_KEY") || "DEMO_KEY"

    url = "#{@base}/foods/search"

    body = %{
      query: query,
      pageSize: 10,
      # Search across curated and branded; we'll re-rank below.
      dataType: ["Foundation", "SR Legacy", "Branded", "Survey (FNDDS)"]
    }

    case Req.post(url, params: [api_key: api_key], json: body, receive_timeout: 8_000) do
      {:ok, %{status: 200, body: %{"foods" => foods}}} when is_list(foods) and foods != [] ->
        pick_best(foods, query)

      {:ok, %{status: 200, body: %{"foods" => []}}} ->
        {:error, :no_match}

      {:ok, %{status: 429}} ->
        Logger.warning("USDA rate-limited. Export a real USDA_FDC_API_KEY.")
        {:error, :rate_limited}

      {:ok, %{status: status, body: body}} ->
        {:error, {:upstream, status, body}}

      {:error, reason} ->
        {:error, {:transport, reason}}
    end
  end

  defp pick_best(foods, query) do
    # Score each candidate: prefer curated data types and non-zero macros.
    # Among ties, prefer descriptions that contain more of the original
    # query's words.
    query_words = String.split(query)

    scored =
      foods
      |> Enum.map(fn food ->
        extracted = extract(food)
        score = score_food(food, extracted, query_words)
        {score, extracted}
      end)
      |> Enum.sort_by(fn {s, _} -> -s end)

    case scored do
      [{score, best} | _] when score > 0 -> {:ok, best}
      _ -> {:error, :no_useful_match}
    end
  end

  defp score_food(food, extracted, query_words) do
    type_score =
      case food["dataType"] do
        "Foundation" -> 100
        "SR Legacy" -> 90
        "Survey (FNDDS)" -> 80
        "Branded" -> 30
        _ -> 0
      end

    # Reward non-zero macros heavily — zero macros usually means a useless entry.
    nutrient_score =
      (if extracted.kcal_per_100g > 0, do: 50, else: 0) +
        (if extracted.protein_per_100g > 0, do: 20, else: 0) +
        (if extracted.fat_per_100g > 0, do: 10, else: 0) +
        (if extracted.carbs_per_100g > 0, do: 10, else: 0)

    description = (food["description"] || "") |> String.downcase()

    word_match_score =
      Enum.count(query_words, fn w -> String.contains?(description, w) end) * 15

    type_score + nutrient_score + word_match_score
  end

  defp upsert(parsed, name) do
    case Repo.get_by(FoodCacheEntry, fdc_id: parsed.fdc_id) do
      %FoodCacheEntry{} = existing ->
        {:ok, existing}

      nil ->
        %FoodCacheEntry{}
        |> FoodCacheEntry.changeset(Map.put(parsed, :name, name))
        |> Repo.insert()
    end
  end

  defp extract(food) do
    nutrients = food["foodNutrients"] || []

    %{
      fdc_id: food["fdcId"],
      data_type: food["dataType"],
      brand_owner: food["brandOwner"],
      kcal_per_100g: nutrient(nutrients, @kcal) || 0.0,
      protein_per_100g: nutrient(nutrients, @protein) || 0.0,
      carbs_per_100g: nutrient(nutrients, @carbs) || 0.0,
      fat_per_100g: nutrient(nutrients, @fat) || 0.0,
      raw: %{
        "description" => food["description"],
        "fdcId" => food["fdcId"]
      }
    }
  end

  defp nutrient(list, id) do
    Enum.find_value(list, fn n ->
      cond do
        n["nutrientId"] == id -> n["value"]
        get_in(n, ["nutrient", "id"]) == id -> n["amount"] || n["value"]
        true -> nil
      end
    end)
  end

  @doc """
  Scales per-100g macros by `grams` and returns a meal-portion struct.
  """
  def macros_for(%FoodCacheEntry{} = entry, grams) when is_number(grams) do
    factor = grams / 100.0

    %{
      grams: grams,
      kcal: round(entry.kcal_per_100g * factor),
      protein: Float.round(entry.protein_per_100g * factor, 1),
      carbs: Float.round(entry.carbs_per_100g * factor, 1),
      fat: Float.round(entry.fat_per_100g * factor, 1)
    }
  end
end
