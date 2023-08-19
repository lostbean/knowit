defmodule Knowit.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      KnowitWeb.Telemetry,
      # Start the Ecto repository
      Knowit.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: Knowit.PubSub},
      # Start Finch
      {Finch, name: Knowit.Finch},
      # Start the Endpoint (http/https)
      KnowitWeb.Endpoint,
      # Start a worker by calling: Knowit.Worker.start_link(arg)
      # {Knowit.Worker, arg}
      {Nx.Serving,
       name: Knowit.Serving.AudioToText,
       serving: Knowit.Serving.AudioToText.serving(batch_size: 8),
       batch_timeout: 100}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Knowit.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    KnowitWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
