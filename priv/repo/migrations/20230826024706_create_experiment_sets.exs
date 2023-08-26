defmodule Knowit.Repo.Migrations.CreateExperimentSets do
  use Ecto.Migration

  def change do
    create table(:experiment_sets) do
      add :user_id, references(:users, on_delete: :nothing)
      add :name, :string
      timestamps()
    end

    create unique_index(:experiment_sets, [:user_id, :name])
  end
end
