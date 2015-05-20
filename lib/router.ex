defmodule Trot.Router do
  alias Plug.Conn.Status
  require Logger

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
        Map.get(conn.private, :trot_route).(conn)
      end

      def call(conn, opts) do
        super(conn, opts)
        |> Trot.not_found(opts)
        |> assign(:called_all_plugs, true)
      end

      @before_compile Trot.Router
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      defp do_match(_method, _path, _host) do
        fn(conn) -> conn end
      end
    end
  end

  @doc ~S"""
  Encodes HTTP responses as appropriate and passes them to Plug.Conn.

  ## Examples

      # Sets status code to 200 with an empty body
      get "/" do
        200
      end

      # Returns an empty body with a status code of 404
      get "/bad" do
        :bad_request
      end

      # Sets the status code to 200 with a text body
      get "/text" do
        "Thank you for your question."
      end

      # Sets the status code to 201 with a text body
      get "/text/body" do
        {201, "Thank you for your question."}
      end

      # Sets status code to 200 with a JSON-encoded body
      get "/json" do
        %{"hyper" => "social"}
      end

      # Sets the status code to 201 with a JSON-encoded body
      get "/json/code" do
        {201, %{"hyper" => "social"}}
      end

      # Set the response manually as when using Plug directly
      get "/conn" do
        send_resp(conn, 200, "optimal tip-to-tip efficiency")
      end

      # Pattern match part of the path into a variable
      get "/presenter/:name" do
        "The presenter is #{name}"
      end

      # Redirect the incoming request
      get "/redirect" do
        {:redirect, "/text/body"}
      end
  """
  def make_response(%Plug.Conn{state: :set}, _conn) do
    raise ArgumentError, message: "conn must be sent before being returned"
  end
  def make_response(conn = %Plug.Conn{}, _conn), do: conn
  def make_response({:redirect, to}, conn), do: do_redirect(to, conn)
  def make_response(code, conn) when is_number(code) do
    Plug.Conn.send_resp(conn, code, "")
  end
  def make_response(code, conn) when is_atom(code) do
    code = Status.code(code)
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
    Plug.Conn.send_resp(conn, Status.code(:ok), body)
  end
  def make_response(body, conn) do
    body = Poison.encode!(body)
    Plug.Conn.send_resp(conn, Status.code(:ok), body)
  end

  @doc """
  Redirect the request to another location.
  """
  def do_redirect(path, conn) when is_binary(path) do
    Logger.info "Redirecting to #{path}"
    URI.parse(path) |> do_redirect(conn)
  end
  def do_redirect(uri = %URI{}, conn) do
    conn
    |> Plug.Conn.put_resp_header("Location", to_string(uri))
    |> Plug.Conn.send_resp(Status.code(:temporary_redirect), "")
  end

  defmacro get(path, options \\ [], do: body), do: compile(:get, path, options, body)
  defmacro post(path, options \\ [], do: body), do: compile(:post, path, options, body)
  defmacro put(path, options \\ [], do: body), do: compile(:put, path, options, body)
  defmacro patch(path, options \\ [], do: body), do: compile(:patch, path, options, body)
  defmacro delete(path, options \\ [], do: body), do: compile(:delete, path, options, body)
  defmacro options(path, options \\ [], do: body), do: compile(:options, path, options, body)

  defmacro static(at, from) do
    quote do
      @plugs {Plug.Static, [at: unquote(at), from: unquote(from)], true}
    end
  end

  defmacro redirect(from, to) do
    body = quote do: {:redirect, unquote(to)}
    compile(:get, from, [], body)
  end

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

      defp do_match(unquote(method), unquote(match), unquote(host)) when unquote(guards) do
        fn var!(conn) -> unquote(body) |> Trot.Router.make_response(var!(conn)) end
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
