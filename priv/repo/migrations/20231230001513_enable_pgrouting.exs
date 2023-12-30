defmodule Knowit.Repo.Migrations.EnablePgrouting do
  use Ecto.Migration

  def up do
    execute "CREATE EXTENSION IF NOT EXISTS postgis", ""
    execute "CREATE EXTENSION IF NOT EXISTS pgrouting", ""
  end

  def down do
    execute "DROP EXTENSION IF EXISTS pgrouting", ""
    execute "DROP EXTENSION IF EXISTS postgis", ""
  end
end
