defmodule Trot.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    port = Application.get_env(:trot, :port, 4000)
    router_module = Application.get_env(:trot, :router, Trot.NotFound)

    children = [
      Plug.Adapters.Cowboy.child_spec(:http, router_module, [], [port: port]),
    ]
    supervise(children, strategy: :one_for_one)
  end
end
