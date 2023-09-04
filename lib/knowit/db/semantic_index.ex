defmodule Knowit.DB.SemanticIndex do
  use Ecto.Schema
  import Ecto.Changeset

  schema "semantic_table" do
    field :embedding, Pgvector.Ecto.Vector
    field :content, :string
    field :graph_id, :id
  end

  def changeset(name, params \\ %{}) do
    name
    |> cast(params, [:embedding, :content, :graph_id])
    |> validate_required([:embedding, :content, :graph_id])
  end

end
