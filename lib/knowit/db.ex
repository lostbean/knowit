defmodule Knowit.DB do
  import Ecto.Query
  alias Ecto.Changeset
  alias Knowit.Accounts.User
  alias Knowit.Repo
  alias Knowit.DB.{ExperimentSet, Experiment}

  def insert_triple([origin, link, target], %ExperimentSet{} = experiment_set) do
    %Experiment{origin: origin, link: link, target: target}
    |> Experiment.changeset()
    |> Changeset.put_assoc(:experiment_set, experiment_set)
    |> Repo.insert()
  end

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

  def list_experiment(user, set_id) do
    if is_nil(set_id) do
      []
    else
      from(e in Experiment,
        join: s in ExperimentSet,
        on: s.id == e.experiment_set_id,
        where: s.id == ^set_id,
        where: s.user_id == ^user.id,
        preload: []
      )
      |> Repo.all()
    end
  end
end
