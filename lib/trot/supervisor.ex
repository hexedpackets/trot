defmodule Trot.Supervisor do
  @moduledoc false

  @doc false
  def start_link do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc false
  def init([]) do
    import Supervisor.Spec

    port = case Application.get_env(:trot, :port, 4000) do
      port when is_binary(port) -> String.to_integer(port)
      port -> port
    end
    protocol_options = Application.get_env(:trot, :protocol_options, [])
    router_module = Application.get_env(:trot, :router, Trot.NotFound)

    children = [
      Plug.Adapters.Cowboy.child_spec(:http, router_module, [], [port: port, protocol_options: protocol_options]),
    ]
    supervise(children, strategy: :one_for_one)
  end
end
