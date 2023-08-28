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
    Repo.get_by(ExperimentSet, id: set_id)
    |> Changeset.change(%{name: new_name})
    |> Repo.update()
  end

  def list_experiment_sets(user) do
    query =
      from e in ExperimentSet,
        where: e.user_id == ^user.id,
        order_by: [desc: e.updated_at],
        preload: :user
    Repo.all(query)
  end

  def list_experiment(user, set_id) do
    query =
      from e in Experiment,
        join: s in ExperimentSet,
        on: s.id == e.experiment_set_id,
        where: s.id == ^set_id,
        preload: []
    Repo.all(query)
  end
end
