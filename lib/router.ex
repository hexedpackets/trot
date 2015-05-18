defmodule Trot.Router do
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
          :plug_route,
          do_match(conn.method, Enum.map(conn.path_info, &URI.decode/1), conn.host))
      end

      defp dispatch(%Plug.Conn{assigns: assigns} = conn, _opts) do
        Map.get(conn.private, :plug_route).() |> Trot.Router.make_response(conn)
      end
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
  def send_resp(%Plug.Conn{state: :set}) do
    raise ArgumentError, message: "conn must be sent before being returned"
  end
  def send_resp(conn = %Plug.Conn{}), do: conn

  defmacro get(path, options, contents \\ []) do
    compile(:get, path, options, contents)
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
    {path, guards} = extract_path_and_guards(expr)

    quote bind_quoted: [method: method,
                        path: path,
                        options: options,
                        guards: Macro.escape(guards, unquote: true),
                        body: Macro.escape(body, unquote: true)] do
      {method, match, host, guards} = Plug.Router.__route__(method, path, guards, options)

      defp do_match(unquote(method), unquote(match), unquote(host)) when unquote(guards) do
        fn () -> unquote(body) end
      end
    end
  end

  # Extract the path and guards from the path.
  defp extract_path_and_guards({:when, _, [path, guards]}), do: {extract_path(path), guards}
  defp extract_path_and_guards(path), do: {extract_path(path), true}

  defp extract_path({:_, _, var}) when is_atom(var), do: "/*_path"
  defp extract_path(path), do: path
end
