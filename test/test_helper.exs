ExUnit.start()


defmodule Trot.TestHelper do
  use ExUnit.Case

  @doc """
  Calls a routing endpoint with a fake connections, then returns the connection after it has
  gone through the server code path.
  """
  def call(router, method, uri, params \\ nil, headers \\ []) do
    conn = %Plug.Conn{req_headers: headers}
    |> Plug.Adapters.Test.Conn.conn(method, uri, params)
    |> Plug.Conn.fetch_query_params
    |> router.call(router.init([]))
    assert conn.state == :sent
    conn
  end
end
