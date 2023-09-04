defmodule Knowit.Repo.Migrations.DropExperiments do
  use Ecto.Migration

  def up do
    alter table(:experiment_sets) do
      add :company_id, references(:experiments)
    end

    drop table(:experiments), mode: :cascade
  end

  def down do
    create table(:experiments) do
      add :experiment_set_id, references(:experiment_sets, on_delete: :nothing)
      add :origin, :string
      add :link, :string
      add :target, :string
      timestamps()
    end
  end
end
