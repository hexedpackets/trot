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
  def call(conn, [env: :dev]), do: reload() |> check_reload(conn)
  def call(conn, _opts), do: conn

  @doc """
  Recompiles any modules that have changed. This is similar to how IEx handles recompilation,
  but only for the elixir compiler.
  https://github.com/elixir-lang/elixir/blob/v1.3.2/lib/iex/lib/iex/helpers.ex#L77
  """
  def reload do
    Mix.Task.reenable("compile.elixir")
    Mix.Task.run("compile.elixir")
  end

  # As of Elixir 1.6, the `compile.elixir` task returns the result of `Mix.Compilers.Elixir.compile/6` directly
  # instead of pattern matching/transforming it.
  defp check_reload(res, conn) when is_atom(res), do: check_reload([res], conn)
  defp check_reload({:noop, rest}, conn), do: check_reload(rest, conn)
  defp check_reload([:noop | rest], conn), do: check_reload(rest, conn)
  defp check_reload({:ok, _rest}, conn), do: force_redirect(conn)
  defp check_reload([:ok | _rest], conn), do: force_redirect(conn)
  defp check_reload([%{} | rest], conn), do: check_reload(rest, conn)
  defp check_reload([], conn), do: conn

  defp force_redirect(conn) do
    location = "/" <> Enum.join(conn.path_info, "/")
    conn
    |> Plug.Conn.put_resp_header("location", location)
    |> Plug.Conn.send_resp(302, "")
    |> Plug.Conn.halt
  end
end
