defmodule YourApp.Repo.Migrations.CreateExperiments do
  use Ecto.Migration

  def change do
    create table(:experiments) do
      add :experiment_set_id, references(:experiment_sets, on_delete: :nothing)
      add :origin, :string
      add :link, :string
      add :target, :string
      timestamps()
    end
  end
end
