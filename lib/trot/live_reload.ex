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
  def call(conn, _opts) do
    case reload(Mix.env) do
      :ok ->
        location = "/" <> Enum.join(conn.path_info, "/")
        conn
          |> Plug.Conn.put_resp_header("Location", location)
          |> Plug.Conn.send_resp(302, "")
          |> Plug.Conn.halt
      _   -> conn
    end
  end

  defp reload(:dev), do: Mix.Tasks.Compile.Elixir.run([])
  defp reload(_), do: :noreload
end
