defmodule Knowit.DB.Experiment do
  use Ecto.Schema
  import Ecto.Changeset

  schema "experiments" do
    belongs_to :experiment_set, Knowit.DB.ExperimentSet
    field :origin, :string
    field :link, :string
    field :target, :string
    timestamps()
  end

  def changeset(name, params \\ %{}) do
    name
    |> cast(params, [:origin, :link, :target])
    |> validate_required([:origin, :link, :target])
  end

end
