defmodule Isee.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      Isee.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: Isee.PubSub},
      # Cache 
      {Cachex, name: Isee.Cache},
      # Start Finch
      {Finch, name: Isee.Finch},
      # Start Service lookup
      Isee.ServiceLookup,
      # Start the streamer
      Isee.StreamProxy,
      {DynamicSupervisor, name: Isee.StreamSupervisor, strategy: :one_for_one}
      # Isee.Streamer
      # Start a worker by calling: Isee.Worker.start_link(arg)
      # {Isee.Worker, arg}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Isee.Supervisor)
  end
end
