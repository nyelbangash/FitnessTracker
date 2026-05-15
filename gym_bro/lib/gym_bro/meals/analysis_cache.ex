defmodule GymBro.Meals.AnalysisCache do
  @moduledoc """
  Short-lived in-memory cache for in-flight meal photo analyses. Stores the
  original image bytes + media type + initial analysis result so the user can
  refine without re-uploading. Entries expire after 30 minutes.

  Scoped per user — only the user who initiated the analysis can refine it.
  Keys are UUIDs (opaque to clients).
  """

  use Agent

  @ttl_seconds 30 * 60

  def start_link(_opts) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  @doc """
  Stores an analysis under a fresh UUID. Returns the id.
  Inputs: user_id, image bytes, media_type ("image/jpeg" etc), analysis map.
  """
  def put(user_id, image_bytes, media_type, analysis) do
    id = uuid()
    expires_at = System.monotonic_time(:second) + @ttl_seconds

    entry = %{
      user_id: user_id,
      image_bytes: image_bytes,
      media_type: media_type,
      analysis: analysis,
      expires_at: expires_at
    }

    Agent.update(__MODULE__, fn map -> Map.put(map, id, entry) end)
    sweep_async()
    id
  end

  @doc """
  Fetches an entry. Returns {:ok, entry} if it exists, belongs to the user,
  and isn't expired; otherwise {:error, :not_found} or {:error, :forbidden}.
  """
  def get(id, user_id) do
    now = System.monotonic_time(:second)

    Agent.get(__MODULE__, fn map ->
      case Map.get(map, id) do
        nil -> {:error, :not_found}
        %{expires_at: exp} when exp < now -> {:error, :expired}
        %{user_id: ^user_id} = entry -> {:ok, entry}
        _ -> {:error, :forbidden}
      end
    end)
  end

  @doc """
  Replaces the analysis on an existing entry (used after refinement).
  """
  def update_analysis(id, new_analysis) do
    Agent.update(__MODULE__, fn map ->
      case Map.get(map, id) do
        nil -> map
        entry -> Map.put(map, id, %{entry | analysis: new_analysis})
      end
    end)
  end

  def delete(id) do
    Agent.update(__MODULE__, fn map -> Map.delete(map, id) end)
  end

  defp sweep_async do
    Task.start(fn -> sweep() end)
  end

  defp sweep do
    now = System.monotonic_time(:second)

    Agent.update(__MODULE__, fn map ->
      Enum.reject(map, fn {_id, %{expires_at: exp}} -> exp < now end)
      |> Map.new()
    end)
  end

  defp uuid do
    :crypto.strong_rand_bytes(16) |> Base.url_encode64(padding: false)
  end
end
