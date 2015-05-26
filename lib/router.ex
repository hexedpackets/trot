defmodule Trot.Router do
  @moduledoc """
  Module for creating routes based on the URL path.
  Routes are specified using one of the HTTP method macros:
  `get/2 post/2 put/2 patch/2 delete/2 options/2`.
  The first argument is a the path to route to, and the second argument is the
  block of code to execute. See examples below.

  ## Module attributes
  `@path_root`: URL path to prefix to all routes in the module. Defaults to "/".

  `@static_root`: File path to use as the root when looking for static files.
  Defaults to "priv/static".
  """

  alias Plug.Conn.Status
  require Logger

  @doc false
  defmacro __using__(_opts) do
    quote do
      import Trot.Router
      import Plug.Builder, only: [plug: 1, plug: 2]
      import Plug.Conn

      @behaviour Plug
      @plug_builder_opts []
      Module.register_attribute(__MODULE__, :plugs, accumulate: true)

      def match(conn = %Plug.Conn{state: :unset}, _opts) do
        headers = conn.req_headers |> Enum.into(%{})
        fun = do_match(conn.method, Enum.map(conn.path_info, &URI.decode/1), conn.host, headers, conn.assigns[:version])
        fun.(conn)
      end
      def match(conn, _opts), do: conn

      def init(opts), do: opts
      def call(conn, opts) do
        plug_builder_call(conn, opts)
      end

      @static_root Path.relative_to_cwd("priv/static")
      @path_root "/"

      plug Plug.Logger
      plug :match

      @before_compile Trot.Router
      @before_compile Plug.Builder
    end
  end

  @doc false
  defmacro __before_compile__(_env) do
    quote do
      @doc """
      Pass-through route that matches all parametes. This ensures that the plug
      pipeline won't die if there are more plugs after this module.
      """
      def do_match(_method, _path, _host, _headers, _version) do
        fn(conn) -> conn end
      end
    end
  end

  @doc """
  Sets up routes from other modules my plugging into the `match/2` function
  in the module.
  """
  defmacro import_routes(module) do
    quote do
      defp external_match(conn, [module: unquote(module)]) do
        unquote(module).match(conn, [])
      end
      plug :external_match, module: unquote(module)
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
  def make_response(body, conn) when is_binary(body), do: make_response({:ok, body}, conn)
  def make_response(code, conn) when is_number(code), do: make_response({code, ""}, conn)
  def make_response(code, conn) when is_atom(code), do: make_response({Status.code(code), ""}, conn)
  def make_response({code, body}, conn) when is_atom(code), do: make_response({Status.code(code), body}, conn)
  def make_response({code, body}, conn) when is_number(code) and is_binary(body) do
    Plug.Conn.send_resp(conn, code, body)
  end
  def make_response({code, body, headers}, conn) do
    conn = headers
    |> Enum.map(&format_header/1)
    |> Enum.reduce(conn, fn({header, value}, conn) -> Plug.Conn.put_resp_header(conn, header, value) end)
    make_response({code, body}, conn)
  end
  def make_response({code, body}, conn) when is_number(code) do
    body = Poison.encode!(body)
    make_response({code, body}, conn)
  end
  def make_response(body, conn) do
    body = Poison.encode!(body)
    make_response({:ok, body}, conn)
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

  defmacro get(path, options, contents \\ []), do: compile(:get, path, options, contents)
  defmacro post(path, options, contents \\ []), do: compile(:post, path, options, contents)
  defmacro put(path, options, contents \\ []), do: compile(:put, path, options, contents)
  defmacro patch(path, options, contents \\ []), do: compile(:patch, path, options, contents)
  defmacro delete(path, options, contents \\ []), do: compile(:delete, path, options, contents)
  defmacro options(path, options, contents \\ []), do: compile(:options, path, options, contents)

  @doc """
  Redirects all incoming requests for "from" to "to". The value of "to" will be put into the Location response header.
  """
  defmacro redirect(from, to) do
    body = quote do: {:redirect, unquote(to)}
    compile(:get, from, [], do: body)
  end

  @doc """
  Sets up a route to static assets. All requests beginning with "at" will look for a matching file under "from".
  @static_root will be prepended to "from" and defaults to "priv/static".

  ## Examples
      static "/js", "assets/js"

      @static_root "priv/assets/static"
      static "/css", "css"
  """
  defmacro static(at, from), do: static_plug(at, from)
  @doc """
  Sets up a route for static to path at the @static_root, which defaults to "priv/static".
  """
  defmacro static(at), do: static_plug(at, "/")

  defp static_plug(at, from) do
    quote do
      path = Path.join(@static_root, unquote(from))
      @plugs {Plug.Static, [at: unquote(at), from: path], true}
    end
  end

  # Entry point for both forward and match that is actually
  # responsible to compile the route.
  defp compile(method, expr, options, contents) do
    {body, options} =
      cond do
        b = contents[:do] ->
          {b, options}
        options[:do] ->
          Keyword.pop(options, :do)
        true ->
          raise ArgumentError, message: "expected :do to be given as option"
      end
    options = sanitize_options(options)

    quote bind_quoted: [method: method,
                        options: options,
                        expr: expr,
                        body: Macro.escape(body, unquote: true)] do

      path = Path.join(@path_root, expr)
      {path, guards} = Trot.Router.extract_path_and_guards(path)
      {method, match, host, guards} = Plug.Router.__route__(method, path, guards, options)
      version = Trot.Versioning.build_version_match(options[:version])
      headers = Trot.Router.extract_headers(options[:headers])

      def do_match(unquote(method), unquote(match), unquote(host), unquote(headers), unquote(version)) when unquote(guards) do
        fn var!(conn) -> unquote(body) |> Trot.Router.make_response(var!(conn)) end
      end
    end
  end

  defp sanitize_options(options), do: Enum.map(options, &default_keyword/1)

  defp default_keyword(item = {_key, _value}), do: item
  defp default_keyword(key) when is_atom(key), do: {key, true}

  @doc """
  Extracts the request headers to be used in route matches.
  """
  def extract_headers(nil), do: quote do: %{}
  def extract_headers(headers) do
    match = headers
    |> Enum.map(fn({header, value}) -> {format_header_name(header), value} end)
    |> Enum.into(%{})
    Macro.escape(match)
  end

  defp format_header_name(name) do
    name
    |> to_string
    |> String.downcase
  end

  @doc """
  Extract the path and guards from the path.
  """
  def extract_path_and_guards({:when, _, [path, guards]}), do: {extract_path(path), guards}
  def extract_path_and_guards(path), do: {extract_path(path), true}

  defp extract_path({:_, _, var}) when is_atom(var), do: "/*_path"
  defp extract_path(path), do: path

  defp format_header({header, value}) do
    name = header |> to_string |> String.downcase
    {name, value}
  end
end
