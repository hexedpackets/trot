defmodule Trot.AuthCheck do
  @moduledoc """
  Checks that a user has an authorized session before allowing them to access certain routes.
  By default, all routes are allowed.

  ## Options
  `routes`: List of URLs to check authorization on. Defaults to `[]`.
  `match_fun`: Function to run when a request matches the routes. Defaults to returning a 403.
  `match_default`: Function to run when a request does not match any configured routes. Defaults to passing the connection through.

  ## Example:

      defmodule PiedPiper do
        use Plug.Builder
        plug Trot.AuthCheck, [routes: ["/secrets"]]
        use Trot.AuthCheck

        get "/marketing", do: "We are amazing, srsly you guys."
        get "/secrets", do: "We're actually about to go bankrupt"
      end
  """

  import Plug.Conn
  @behaviour Plug

  @doc false
  def init(opts) do
    routes = opts
    |> Keyword.get(:routes, [])
    |> Enum.map(fn(route) -> route |> Plug.Router.Utils.build_path_match |> elem(1) end)

    opts
    |> Keyword.put(:routes, routes)
    |> Keyword.put_new(:match_fun, &__MODULE__.private_route/1)
    |> Keyword.put_new(:default_fun, &__MODULE__.public_route/1)
  end

  @doc false
  def call(conn, opts) do
    conn.path_info
    |> Enum.map(&URI.decode/1)
    |> check_route(opts[:routes], opts, conn)
  end

  defp check_route(_, [], opts, conn), do: apply(opts[:default_fun], [conn])
  defp check_route(path, [path | _], opts, conn), do: apply(opts[:match_fun], [conn])
  defp check_route(path, [_ | routes], opts, conn), do: check_route(path, routes, opts, conn)

  @doc """
  Called when a given route is publicly accessible. This will simply pass
  the connection through to the next plug.
  """
  def public_route(conn), do: conn

  @doc """
  Called when a route needs to be authenticated. Returns a 403 if there is no authentication,
  and passes the conn through untouched otherwise.
  """
  def private_route(conn) do
    conn
    |> send_resp(403, "")
    |> halt
  end
end
