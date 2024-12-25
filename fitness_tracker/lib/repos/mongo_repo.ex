# lib/fitness_tracker/repos/mongo_repo.ex
defmodule FitnessTracker.Repos.MongoRepo do
  use GenServer
  require Logger

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: :mongo)
  end

  def init(:ok) do
    {:ok, conn} =
      Mongo.start_link(
        name: :mongo,
        hostname: "localhost",
        database: "fitness_tracker",
        port: 27017,
        pool_size: 2
      )

    {:ok, conn}
  end

  def insert_one(collection, document) do
    Mongo.insert_one(:mongo, collection, document)
  end

  def find_one(collection, filter) do
    Mongo.find_one(:mongo, collection, filter)
  end

  def update_one(collection, filter, update) do
    Mongo.update_one(:mongo, collection, filter, update)
  end

  def delete_one(collection, filter) do
    Mongo.delete_one(:mongo, collection, filter)
  end
end
