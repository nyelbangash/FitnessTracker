defmodule GymBro.Repo.Migrations.DropMealIngredientsTimestamps do
  use Ecto.Migration

  # meal_ingredients is a pure many_to_many join table. Ecto's put_assoc for
  # many_to_many doesn't populate inserted_at/updated_at, so the NOT NULL on
  # those columns broke meal creation. Drop them defensively — the test DB
  # was created from the already-fixed original migration, so the columns
  # may not exist there.
  def change do
    execute "ALTER TABLE meal_ingredients DROP COLUMN IF EXISTS inserted_at",
            "ALTER TABLE meal_ingredients ADD COLUMN inserted_at timestamp(0) NOT NULL DEFAULT NOW()"

    execute "ALTER TABLE meal_ingredients DROP COLUMN IF EXISTS updated_at",
            "ALTER TABLE meal_ingredients ADD COLUMN updated_at timestamp(0) NOT NULL DEFAULT NOW()"
  end
end
