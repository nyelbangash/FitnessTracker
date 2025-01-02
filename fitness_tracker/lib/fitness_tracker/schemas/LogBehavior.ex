defmodule FitnessTracker.Schemas.LogBehavior do
  @callback new(map()) :: {:ok, struct()}
  @callback create(String.t(), map()) :: {:ok, struct()} | {:error, term()}
  @callback get_all(String.t()) :: {:ok, list(struct())} | {:error, term()}
  @callback get(String.t(), String.t(), String.t()) :: {:ok, struct()} | {:error, term()}
  @callback update(String.t(), String.t(), String.t(), map()) ::
              {:ok, struct()} | {:error, term()}
  @callback delete(String.t(), String.t(), String.t()) :: :ok | {:error, term()}
  @callback clear_log(String.t()) :: :ok | {:error, term()}
  @callback to_json(struct()) :: map()
  @callback from_json(map()) :: struct()
end

defmodule FitnessTracker.Schemas.BaseLog do
  @moduledoc """
  Provides base implementation for common logging functionality.
  """

  defmacro __using__(opts) do
    quote do
      @behaviour FitnessTracker.Schemas.LogBehavior

      @log_type unquote(opts[:log_type])
      @name_field unquote(opts[:name_field])
      @date_field unquote(opts[:date_field])

      # Shared get_all implementation
      def get_all(username) do
        case get_profile(username) do
          {:ok, %{@log_type => log}} -> {:ok, Enum.map(log, &from_json/1)}
          {:error, :profile_not_found} -> {:error, :profile_not_found}
          _ -> {:error, "#{@log_type}_not_found"}
        end
      end

      # Shared get implementation
      def get(username, name, date) do
        with {:ok, profile} <- get_profile(username),
             item when not is_nil(item) <- find_item(profile[@log_type], name, date) do
          {:ok, from_json(item)}
        else
          nil -> {:error, :not_found}
          error -> error
        end
      end

      # Shared delete implementation
      def delete(username, name, date) do
        case remove_item(username, name, date) do
          {:ok, %{modified_count: 1}} -> :ok
          {:ok, %{modified_count: 0}} -> {:error, :not_found}
          {:error, error} -> {:error, error}
        end
      end

      # Shared clear_log implementation
      def clear_log(username) do
        case clear_all(username) do
          {:ok, %{modified_count: 1}} -> :ok
          {:ok, %{modified_count: 0}} -> {:error, :profile_not_found}
          {:error, error} -> {:error, error}
        end
      end

      # Shared private functions
      defp get_profile(username) do
        case Mongo.find_one(:mongo, "profiles", %{username: username}) do
          nil -> {:error, :profile_not_found}
          profile -> {:ok, profile}
        end
      end

      defp matches_criteria?(item, name, date) do
        name_field = @name_field
        date_field = @date_field

        IO.inspect({@log_type, name_field, date_field}, label: "Checking with fields")
        IO.inspect({item[name_field], item[date_field]}, label: "Found values")
        IO.inspect({name, date}, label: "Looking for")

        item[name_field] == name && item[date_field] == date
      end

      defp find_item(log, name, date) do
        IO.inspect(@log_type, label: "Log type")
        IO.inspect(log, label: "Full log")
        IO.inspect({name, date}, label: "Looking for")
        IO.inspect(@name_field, label: "Name field")
        IO.inspect(@date_field, label: "Date field")

        found =
          Enum.find(log || [], fn item ->
            IO.inspect(item, label: "Checking item")
            matches_criteria?(item, name, date)
          end)

        IO.inspect(found, label: "Found")
        found
      end

      defp remove_item(username, name, date) do
        Mongo.update_one(:mongo, "profiles", %{username: username}, %{
          "$pull": %{
            @log_type => %{
              @name_field => name,
              @date_field => date
            }
          }
        })
      end

      defp clear_all(username) do
        Mongo.update_one(:mongo, "profiles", %{username: username}, %{"$set": %{@log_type => []}})
      end

      defp save_item(username, item) do
        Mongo.update_one(:mongo, "profiles", %{username: username}, %{
          "$push": %{@log_type => to_json(item)}
        })
      end

      def save_template(username, template_name, data) do
        with {:ok, profile} <- get_profile(username),
             true <- validate_template_name(template_name, profile),
             template <- prepare_template(data, template_name) do
          Mongo.update_one(:mongo, "profiles", %{username: username}, %{
            "$push": %{templates_field() => to_json(template)}
          })
        else
          false -> {:error, :template_exists}
          error -> error
        end
      end

      def get_template(username, template_name) do
        with {:ok, profile} <- get_profile(username),
             template when not is_nil(template) <- find_template(profile, template_name) do
          {:ok, from_json(template)}
        else
          nil -> {:error, :template_not_found}
          error -> error
        end
      end

      def delete_template(username, template_name) do
        Mongo.update_one(:mongo, "profiles", %{username: username}, %{
          "$pull": %{templates_field() => %{template_name: template_name}}
        })
      end

      defp validate_template_name(name, profile) do
        templates = Map.get(profile, templates_field(), [])
        not Enum.any?(templates, &(&1["template_name"] == name))
      end

      defp find_template(profile, template_name) do
        profile
        |> Map.get(templates_field(), [])
        |> Enum.find(&(&1["template_name"] == template_name))
      end

      defp templates_field do
        case @log_type do
          "workout_log" -> "workout_templates"
          "meal_log" -> "meal_templates"
        end
      end

      defp prepare_template(data, template_name) do
        Map.put(data, :template_name, template_name)
      end

      # Allow overriding template functions
      defoverridable get_all: 1,
                     get: 3,
                     delete: 3,
                     clear_log: 1,
                     save_template: 3,
                     get_template: 2,
                     find_template: 2,
                     delete_template: 2
    end
  end
end
