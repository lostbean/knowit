defmodule Knowit.Repo.Migrations.DeletePropagateDeletion do
  use Ecto.Migration

  def change do
    alter table(:experiments) do
      modify(:experiment_set_id, references(:experiment_sets, on_delete: :delete_all),
        from: references(:experiment_sets, on_delete: :nothing)
      )
    end

    alter table(:experiment_sets) do
      modify(:user_id, references(:users, on_delete: :delete_all),
        from: references(:users, on_delete: :nothing)
      )
    end
  end
end
