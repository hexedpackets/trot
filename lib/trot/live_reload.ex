defmodule Trot.LiveReload do
  @moduledoc """
  Plug for reloading modules on every request, allowing fast iteration during
  development.

  Reloading only happens in dev, every other environment is a noop for this plug.
  If a module is reloaded, a redirect is sent to the client for the same location,
  allowing the whole plug pipeline to be used with the new code. All further
  processing on the original request is halted.

  Modified from https://github.com/sugar-framework/plugs/blob/master/lib/sugar/plugs/hot_code_reload.ex
  """

  @behaviour Plug

  @doc false
  def init(opts), do: opts

  @doc false
  def call(conn, [env: :dev]), do: reload |> check_reload(conn)
  def call(conn, _opts), do: conn

  @doc """
  Recompiles any modules that have changed.
  """
  def reload, do: Mix.Tasks.Compile.Elixir.run([])

  defp check_reload(:ok, conn) do
    location = "/" <> Enum.join(conn.path_info, "/")
    conn
      |> Plug.Conn.put_resp_header("location", location)
      |> Plug.Conn.send_resp(302, "")
      |> Plug.Conn.halt
  end
  defp check_reload(_, conn), do: conn
end
