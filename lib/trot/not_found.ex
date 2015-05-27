defmodule Trot.NotFound do
  @moduledoc """
  Plug for inserting a 404 not found response.

  Use this module or plug it in at the end of the plug system. If the connection
  has not been sent yet, it will be set to 404 with a not found message.

  ## Example

    defmodule WhereIsIt.Router do
      use Trot.Router

      get "/real", do: :ok

      use Trot.NotFound
    end
  """
  @doc false
  defmacro __using__(_opts) do
    quote do
      import Plug.Builder, only: [plug: 1]
      plug Trot.NotFound
    end
  end

  @doc false
  def init(opts), do: opts

  @doc false
  def call(conn, opts), do: not_found(conn, opts)

  @doc """
  When using `import_routes`, `match/2` is used as the Plug function. Simply passes on to `not_found/2`.
  """
  def match(conn, opts), do: not_found(conn, opts)

  @doc """
  See `not_found/2`.
  """
  def not_found(conn), do: not_found(conn, [])

  @doc """
  Takes a Plug.Conn and sends a "not found" message to the requestor.
  """
  def not_found(conn = %Plug.Conn{state: :unset}, _opts) do
    Plug.Conn.send_resp(conn, Plug.Conn.Status.code(:not_found), "<html><body>Not Found</body></html>")
  end
  def not_found(conn, _opts), do: conn
end
