defmodule Knowit.Repo.Migrations.CreateSemanticTable do
  use Ecto.Migration

  def change do
    create table(:semantic_table) do
      add :embedding, :vector, size: 384
      add :content, :string
      add :graph_id, :bigserial
    end

    create unique_index(:semantic_table, [:graph_id])

    create index(:semantic_table, ["(to_tsvector('english', content))"],
             name: :semantic_name_vector,
             using: "GIN"
           )

    create index(:semantic_table, ["embedding vector_l2_ops"], using: :ivfflat)
  end
end
