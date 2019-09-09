defmodule Trot.CacheBodyReader do
  @moduledoc """
  Caching for Plug body parsers. This allows the original, raw body to be accessed farther down the plug call chain.
  """

  def read_body(conn, opts) do
    {:ok, body, conn} = Plug.Conn.read_body(conn, opts)
    conn = update_in(conn.assigns[:raw_body], &[body | (&1 || [])])
    {:ok, body, conn}
  end
end
