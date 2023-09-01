defmodule Knowit.Repo.Migrations.CreateGraphDb do
  use Ecto.Migration

  def change do
    execute "SELECT create_graph('knowit_graph');", ""
  end
end
