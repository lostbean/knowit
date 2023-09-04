defmodule Knowit.DB do
  import Ecto.Query
  alias Ecto.Changeset
  alias Knowit.Accounts.User
  alias Knowit.Repo
  alias Knowit.DB.{ExperimentSet}

  def new_experiment_set(name, %User{} = user) do
    %ExperimentSet{name: name}
    |> ExperimentSet.changeset()
    |> Changeset.put_assoc(:user, user)
    |> Repo.insert()
  end

  def get_experiment_set(%User{} = user, set_id) do
    Repo.get_by!(ExperimentSet, id: set_id, user_id: user.id)
  end

  def rename_experiment_set(new_name, %User{} = user, set_id) do
    Repo.get_by(ExperimentSet, id: set_id, user_id: user.id)
    |> Changeset.change(%{name: new_name})
    |> Repo.update()
  end

  def delete_experiment_set(%User{} = user, set_id) do
    delete_graph_experiment_set(set_id)
    from(s in ExperimentSet,
      where: s.id == ^set_id,
      where: s.user_id == ^user.id,
      select: s
    )
    |> Repo.delete_all()
  end

  def list_experiment_sets(user) do
    from(e in ExperimentSet,
      where: e.user_id == ^user.id,
      order_by: [desc: e.updated_at],
      preload: :user
    )
    |> Repo.all()
  end

  def latest_updated_experiment_set(user) do
    from(e in ExperimentSet,
      where: e.user_id == ^user.id,
      order_by: [desc: e.updated_at],
      limit: 1,
      preload: :user
    )
    |> Repo.one()
  end

  def delete_graph_experiment_set(set_id) do
    "SELECT * FROM cypher('knowit_graph', $$ MATCH (a {set_id:#{set_id}}) DETACH DELETE a $$) as (a agtype)"
    |> Repo.query([])
  end

end
