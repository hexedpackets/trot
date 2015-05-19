defmodule Trot.Router do
  @http_methods [:get, :post, :put, :patch, :delete, :options]

  @doc false
  defmacro __using__(_opts) do
    quote do
      import Trot.Router
      use Plug.Builder

      plug Plug.Logger
      plug :match
      plug :dispatch

      defp match(conn, _opts) do
        Plug.Conn.put_private(conn,
          :trot_route,
          do_match(conn.method, Enum.map(conn.path_info, &URI.decode/1), conn.host))
      end

      defp dispatch(%Plug.Conn{assigns: assigns} = conn, _opts) do
        Map.get(conn.private, :trot_route).(conn) |> Trot.Router.make_response(conn)
      end
    end
  end

  defmacro is_http_method(thing) do
    quote do
      is_atom(unquote(thing)) and unquote(thing) in @http_methods
    end
  end

  @doc """
  Encodes HTTP responses as appropriate and passes them to Plug.Conn.

  ## Examples

      ### Sets status code to 200 with an empty body
      get "/" do
        200
      end

      ### Sets the status code to 201 and sets the body to "oh yeah!"
      get "/text/body" do
        {201, "oh yeah!"}
      end

      ### Sets status code to 200 with a JSON-encoded body
      get "/" do
        %{"oh" => "yeah"}
      end

      ### Sets the status code to 201 with a JSON-encoded body
      get "/" do
        {201, %{"oh" => "yeah"}}
      end

      ### Sets the status code to 200 and sets the body to "oh yeah!"
      get "/" do
        "oh yeah!"
      end
  """
  def make_response(%Plug.Conn{state: :set}, _conn) do
    raise ArgumentError, message: "conn must be sent before being returned"
  end
  def make_response(conn = %Plug.Conn{}, _conn), do: conn
  def make_response(code, conn) when is_number(code) do
    Plug.Conn.send_resp(conn, code, "")
  end
  def make_response({code, body}, conn) when is_number(code) and is_binary(body) do
    Plug.Conn.send_resp(conn, code, body)
  end
  def make_response({code, body}, conn) when is_number(code) do
    body = Poison.encode!(body)
    Plug.Conn.send_resp(conn, code, body)
  end
  def make_response(body, conn) when is_binary(body) do
    Plug.Conn.send_resp(conn, 200, body)
  end
  def make_response(body, conn) do
    body = Poison.encode!(body)
    Plug.Conn.send_resp(conn, 200, body)
  end

  defmacro get(path, options \\ [], do: body), do: compile(:get, path, options, body)
  defmacro post(path, options \\ [], do: body), do: compile(:post, path, options, body)
  defmacro put(path, options \\ [], do: body), do: compile(:put, path, options, body)
  defmacro patch(path, options \\ [], do: body), do: compile(:patch, path, options, body)
  defmacro delete(path, options \\ [], do: body), do: compile(:delete, path, options, body)
  defmacro options(path, options \\ [], do: body), do: compile(:options, path, options, body)

  # Entry point for both forward and match that is actually
  # responsible to compile the route.
  defp compile(method, expr, options, body) do
    {path, guards} = extract_path_and_guards(expr)
    options = sanitize_options(options)

    quote bind_quoted: [method: method,
                        path: path,
                        options: options,
                        guards: Macro.escape(guards, unquote: true),
                        body: Macro.escape(body, unquote: true)] do
      {method, match, host, guards} = Plug.Router.__route__(method, path, guards, options)

      if Keyword.get(options, :with_conn) do
        defp do_match(unquote(method), unquote(match), unquote(host)) when unquote(guards) do
          fn var!(conn) -> unquote(body) end
        end
      else
        defp do_match(unquote(method), unquote(match), unquote(host)) when unquote(guards) do
          fn (_conn) -> unquote(body) end
        end
      end
    end
  end

  defp sanitize_options(options), do: Enum.map(options, &default_keyword/1)

  defp default_keyword(item = {_key, _value}), do: item
  defp default_keyword(key) when is_atom(key), do: {key, true}

  # Extract the path and guards from the path.
  defp extract_path_and_guards({:when, _, [path, guards]}), do: {extract_path(path), guards}
  defp extract_path_and_guards(path), do: {extract_path(path), true}

  defp extract_path({:_, _, var}) when is_atom(var), do: "/*_path"
  defp extract_path(path), do: path
end
