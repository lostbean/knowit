defmodule Knowit.Repo.Migrations.AddFlatmap do
  use Ecto.Migration

  def up do
    execute "CREATE OR REPLACE AGGREGATE flatMap(anycompatiblearray) (sfunc = array_cat, stype = anycompatiblearray, initcond = '{}')",
            ""
  end

  def down do
    execute "DROP AGGREGATE  IF EXISTS flatMap(anycompatiblearray)"
  end
end
