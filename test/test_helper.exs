ExUnit.start()


defmodule Trot.TestHelper do
  use ExUnit.Case

  @doc """
  Calls a routing endpoint with a fake connections, then returns the connection after it has
  gone through the server code path.
  """
  def call(router, verb, path, params \\ nil, headers \\ []) do
    conn = Plug.Test.conn(verb, path, params, headers)
    |> Plug.Conn.fetch_query_params
    |> router.call(router.init([]))
    assert conn.state == :sent
    conn
  end
end
