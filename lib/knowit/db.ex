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

  def insert_triple([origin, link, target], %ExperimentSet{} = experiment_set) do
    set_id = experiment_set.id
    link_label = String.replace(link, ~r/[\W_]+/, "")

    """
    SELECT *
    FROM cypher('knowit_graph', $$
      MERGE (a:node {set_id:#{set_id}, value:'#{origin}'})
      MERGE (b:node {set_id:#{set_id}, value:'#{target}'})
      MERGE (a)-[:#{link_label} {set_id:#{set_id}, value:'#{link}'}]->(b)
    $$) as (e agtype);
    """
    |> Repo.query([])
  end

  defmacro exists_frag() do
    arguments = ["""
    SELECT *
    FROM cypher('knowit_graph', $$
      MATCH (a)-[link]->(b)
      RETURN a.value, link.value, b.value, a.set_id
    $$) as (origin agtype, link agtype, target agtype, set_id agtype)
    """]
    quote do: fragment(unquote_splicing(arguments))
  end

  def list_experiment(user, set_id) do
    if is_nil(set_id) do
      []
    else
      from(e in exists_frag(),
        join: s in ExperimentSet,
        on: s.id == e.set_id,
        where: s.id == ^set_id,
        where: s.user_id == ^user.id,
        select: [e.origin, e.link, e.target],
        preload: []
      )
      |> Repo.all()
      |> Enum.map(&Enum.map(&1, fn {:ok, data} -> data end))
    end
  end
end
