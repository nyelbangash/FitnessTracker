defmodule GymBro.Meals.Vision do
  @moduledoc """
  Calls the Anthropic Messages API to extract a structured food breakdown
  from a meal photo. Uses tool-use forcing for guaranteed-valid JSON.

  The model is given the user's recent favorites/quick-access meal names so
  it can prefer those names when applicable (matches the user's existing
  food library and gives a nicer cache hit rate on USDA lookups later).
  """

  @endpoint "https://api.anthropic.com/v1/messages"
  @model "claude-sonnet-4-6"
  @anthropic_version "2023-06-01"

  @tool %{
    "name" => "log_meal",
    "description" => """
    Identify each distinct food/ingredient visible in the photo and estimate
    its portion size in grams. Be honest about uncertainty — set confidence
    to "low" when the photo is ambiguous, partially obscured, or the
    portion is hard to judge.

    For each item, prefer the closest match from the user's favorites_hint
    if the food clearly matches one. Otherwise, use a generic descriptive
    name (e.g., "grilled chicken breast", "white jasmine rice", "olive oil").

    Include hidden ingredients you can reasonably infer (cooking oil,
    butter, dressings) with a separate item and low confidence.
    """,
    "input_schema" => %{
      "type" => "object",
      "required" => ["meal_name", "items", "overall_confidence"],
      "properties" => %{
        "meal_name" => %{
          "type" => "string",
          "description" =>
            "A short descriptive name for the meal as a whole (e.g., 'Chicken bowl with rice and broccoli')."
        },
        "meal_type" => %{
          "type" => "string",
          "enum" => ["breakfast", "lunch", "dinner", "snack"]
        },
        "items" => %{
          "type" => "array",
          "items" => %{
            "type" => "object",
            "required" => ["name", "grams", "confidence"],
            "properties" => %{
              "name" => %{
                "type" => "string",
                "description" =>
                  "Specific food name suitable for a USDA database lookup (e.g., 'chicken breast cooked', 'rice white cooked')."
              },
              "grams" => %{"type" => "number"},
              "confidence" => %{
                "type" => "string",
                "enum" => ["low", "medium", "high"]
              },
              "prep_notes" => %{
                "type" => "string",
                "description" =>
                  "Optional: how it appears prepared (grilled, fried, raw, with sauce, etc.). Affects calorie load."
              }
            }
          }
        },
        "overall_confidence" => %{
          "type" => "string",
          "enum" => ["low", "medium", "high"]
        },
        "warnings" => %{
          "type" => "array",
          "items" => %{"type" => "string"},
          "description" => "Free-form caveats for the user (e.g., 'Hard to judge oil content', 'Portion partially out of frame')."
        },
        "reply" => %{
          "type" => "string",
          "description" =>
            "Short conversational reply (1–2 sentences) acknowledging any user feedback and explaining what changed. Used during refinement; can be empty on the initial analysis."
        }
      }
    }
  }

  @doc """
  Analyzes an image (raw bytes + media type) and returns the structured
  log_meal payload from the tool call.
  """
  def analyze(image_bytes, media_type, opts \\ []) when is_binary(image_bytes) do
    api_key = System.get_env("ANTHROPIC_API_KEY")

    if is_nil(api_key) do
      {:error, :missing_api_key}
    else
      do_analyze(image_bytes, media_type, opts, api_key)
    end
  end

  defp do_analyze(image_bytes, media_type, opts, api_key) do
    favorites = Keyword.get(opts, :favorites, [])
    encoded = Base.encode64(image_bytes)

    favorites_block =
      case favorites do
        [] -> "(no saved favorites yet)"
        list -> Enum.map_join(list, "\n", &"- #{&1}")
      end

    user_text = """
    Analyze this meal photo. Use the log_meal tool to return structured output.

    User's favorite/quick-access meals (prefer these names when applicable):
    #{favorites_block}

    Be honest about uncertainty — portion sizes are hard. Lean low on
    confidence when in doubt.
    """

    body = %{
      "model" => @model,
      "max_tokens" => 1024,
      "tools" => [@tool],
      "tool_choice" => %{"type" => "tool", "name" => "log_meal"},
      "messages" => [
        %{
          "role" => "user",
          "content" => [
            %{
              "type" => "image",
              "source" => %{
                "type" => "base64",
                "media_type" => media_type,
                "data" => encoded
              }
            },
            %{"type" => "text", "text" => user_text}
          ]
        }
      ]
    }

    headers = [
      {"x-api-key", api_key},
      {"anthropic-version", @anthropic_version},
      {"content-type", "application/json"}
    ]

    case Req.post(@endpoint, headers: headers, json: body, receive_timeout: 30_000) do
      {:ok, %{status: 200, body: %{"content" => content}}} ->
        extract_tool_input(content)

      {:ok, %{status: status, body: body}} ->
        {:error, {:upstream, status, body}}

      {:error, reason} ->
        {:error, {:transport, reason}}
    end
  end

  defp extract_tool_input(content) when is_list(content) do
    Enum.find_value(content, {:error, :no_tool_use}, fn
      %{"type" => "tool_use", "name" => "log_meal", "input" => input} ->
        {:ok, input}

      _ ->
        nil
    end)
  end

  @doc """
  Re-runs the analysis with the user's feedback applied. The image is the same
  as the initial analysis. `previous_analysis` is the last tool_use output we
  returned. `history` is the prior chat turns: a list of
  %{role: "user" | "assistant", text: "..."}.

  Returns the same shape as `analyze/3`. The model is asked to populate `reply`
  with a short acknowledgement of what changed.
  """
  def refine(image_bytes, media_type, previous_analysis, history)
      when is_binary(image_bytes) and is_map(previous_analysis) and is_list(history) do
    api_key = System.get_env("ANTHROPIC_API_KEY")

    if is_nil(api_key) do
      {:error, :missing_api_key}
    else
      do_refine(image_bytes, media_type, previous_analysis, history, api_key)
    end
  end

  defp do_refine(image_bytes, media_type, previous_analysis, history, api_key) do
    encoded = Base.encode64(image_bytes)
    previous_json = Jason.encode!(previous_analysis)

    intro_text = """
    Here is the meal photo and the previous analysis you returned:

    #{previous_json}

    The user is now giving feedback to refine the estimate. Apply their
    corrections to the analysis. Use the log_meal tool again with the full
    updated payload — every field, not a patch — and populate `reply` with a
    1–2 sentence acknowledgement of what changed.
    """

    initial_user_content = [
      %{
        "type" => "image",
        "source" => %{
          "type" => "base64",
          "media_type" => media_type,
          "data" => encoded
        }
      },
      %{"type" => "text", "text" => intro_text}
    ]

    history_messages =
      Enum.flat_map(history, fn
        %{role: "user", text: text} ->
          [%{"role" => "user", "content" => [%{"type" => "text", "text" => text}]}]

        %{role: "assistant", text: text} ->
          [%{"role" => "assistant", "content" => [%{"type" => "text", "text" => text}]}]

        _ ->
          []
      end)

    messages = [%{"role" => "user", "content" => initial_user_content} | history_messages]

    body = %{
      "model" => @model,
      "max_tokens" => 1024,
      "tools" => [@tool],
      "tool_choice" => %{"type" => "tool", "name" => "log_meal"},
      "messages" => messages
    }

    headers = [
      {"x-api-key", api_key},
      {"anthropic-version", @anthropic_version},
      {"content-type", "application/json"}
    ]

    case Req.post(@endpoint, headers: headers, json: body, receive_timeout: 30_000) do
      {:ok, %{status: 200, body: %{"content" => content}}} ->
        extract_tool_input(content)

      {:ok, %{status: status, body: body}} ->
        {:error, {:upstream, status, body}}

      {:error, reason} ->
        {:error, {:transport, reason}}
    end
  end
end
