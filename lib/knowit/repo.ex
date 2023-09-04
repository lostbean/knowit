defmodule Knowit.Repo do
  use Ecto.Repo,
    otp_app: :knowit,
    adapter: Ecto.Adapters.Postgres

  # Load age extension on every connection
  def set_graph_extension(conn) do
    {:ok, _result} = Postgrex.query(conn, "LOAD 'age';", [])
    {:ok, _result} = Postgrex.query(conn, "SET search_path = \"$user\", public, ag_catalog;", [])
  end
end
