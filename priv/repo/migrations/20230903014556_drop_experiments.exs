defmodule Knowit.Repo.Migrations.DropExperiments do
  use Ecto.Migration

  def change do
    alter table(:experiment_sets) do
      add :company_id, references(:experiments)
    end

    drop table(:experiments), mode: :cascade
  end
end
