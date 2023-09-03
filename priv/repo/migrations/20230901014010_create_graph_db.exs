defmodule Knowit.Repo.Migrations.CreateGraphDb do
  use Ecto.Migration

  @graph_database "knowit_graph"

  def has_entries(query) do
    repo().query!(query).num_rows > 0
  end

  def change do
    if has_entries(
         "select * from pg_tables where (schemaname = 'ag_catalog') and (tablename = 'ag_graph');"
       ) && has_entries(
        "select name from ag_catalog.ag_graph where (name = '#{@graph_database}');") do
      IO.puts("AGE graph has already been created.")
    else
      repo().query!("SELECT * FROM create_graph('#{@graph_database}');")
    end
  end
end
