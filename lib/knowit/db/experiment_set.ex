defmodule Knowit.DB.ExperimentSet do
  use Ecto.Schema
  import Ecto.Changeset

  schema "experiment_sets" do
    belongs_to :user, Knowit.Accounts.User
    has_many :experiments, Knowit.DB.Experiment
    field :name, :string
    timestamps()
  end

  def changeset(set, params \\ %{}) do
    set
    |> cast(params, [:name])
    |> validate_required([:name])
  end

end
