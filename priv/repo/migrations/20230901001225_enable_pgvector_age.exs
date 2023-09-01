defmodule Knowit.Repo.Migrations.EnablePgvectorAge do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS vector", ""
    execute "CREATE EXTENSION IF NOT EXISTS age", ""
  end
end
