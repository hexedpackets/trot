defmodule Trot.RouterTest do
  use ExUnit.Case, async: true

  @doc """
  Calls a routing endpoint with a fake connections, then returns the connection after it has
  gone through the server code path.
  """
  def call(router, verb, path, params \\ nil, headers \\ []) do
    conn = Plug.Test.conn(verb, path, params, headers)
    |> Plug.Conn.fetch_query_params
    |> router.call(router.init([]))
    assert conn.state == :sent
    conn
  end

  defmodule Router do
    use Trot.Router
    use Trot.Template
    @template_root "test/templates"
    @static_root "test/static"

    get "/status", do: 200
    get "/status_atom", do: :bad_request
    get "/text", do: "Thank you for your question."
    get "/text/body", do: {201, "Thank you for your question."}
    get "/json", do: %{"hyper" => "social"}
    get "/json/status", do: {201, %{"hyper" => "social"}}
    get "/json/status_atom", do: {:created, %{"hyper" => "social"}}
    get "/conn", do: send_resp(conn, 200, "optimal tip-to-tip efficiency")
    get "/presenter/:name", do: "The presenter is #{name}"
    get "/redirect", do: {:redirect, "/text"}
    get "/template/eex/:text", do: render_template("index.html.eex", [body: text])
    get "/template/haml/:text", do: render_template("index.html.haml", [body: text])

    redirect "/macro_redirect", "/status"
    static "/static", "/"
    static "/default_static"

    defmodule API do
      use Trot.Router
      @path_root "api"
      get "/status", do: :ok
    end

    defmodule VersionedAPI do
      use Trot.Router
      use Trot.Versioning

      get "/status", do: {:ok, conn.assigns[:version]}

      get "/current", version: "v1", do: "o hai"
      get "/current", version: "beta", do: :bad_request
      get "/current", version: :any, do: :ok
    end
  end

  test "route returns status code" do
    conn = call(Router, :get, "/status")
    assert conn.status == 200
    assert conn.resp_body == ""
  end

  test "route returns status atom" do
    conn = call(Router, :get, "/status_atom")
    assert conn.status == 400
    assert conn.resp_body == ""
  end

  test "route returns text" do
    conn = call(Router, :get, "/text")
    assert conn.status == 200
    assert conn.resp_body == "Thank you for your question."
  end

  test "route returns text with status code" do
    conn = call(Router, :get, "/text/body")
    assert conn.status == 201
    assert conn.resp_body == "Thank you for your question."
  end

  test "route returns json" do
    conn = call(Router, :get, "/json")
    assert conn.status == 200
    assert conn.resp_body == "{\"hyper\":\"social\"}"
  end

  test "route returns json with status code" do
    conn = call(Router, :get, "/json/status")
    assert conn.status == 201
    assert conn.resp_body == "{\"hyper\":\"social\"}"
  end

  test "route returns json with status atom" do
    conn = call(Router, :get, "/json/status_atom")
    assert conn.status == 201
    assert conn.resp_body == "{\"hyper\":\"social\"}"
  end

  test "route returns conn" do
    conn = call(Router, :get, "/conn")
    assert conn.status == 200
    assert conn.resp_body == "optimal tip-to-tip efficiency"
  end

  test "route passes path variable" do
    conn = call(Router, :get, "/presenter/erlich")
    assert conn.status == 200
    assert conn.resp_body == "The presenter is erlich"
  end

  test "route returns redirect" do
    conn = call(Router, :get, "/redirect")
    location = Plug.Conn.get_resp_header(conn, "Location") |> List.first
    assert conn.status == 307
    assert location == "/text"
  end

  test "redirect macro" do
    conn = call(Router, :get, "/macro_redirect")
    location = Plug.Conn.get_resp_header(conn, "Location") |> List.first
    assert conn.status == 307
    assert location == "/status"
  end

  test "default not found route" do
    conn = call(Router, :get, "/this/does/not/exist")
    assert conn.status == 404
  end

  test "static routes" do
    conn = call(Router, :get, "/static/text.html")
    assert conn.status == 200
    assert conn.resp_body == "<html><body>You found me</body></html>\n"
  end

  test "static routes with default path" do
    conn = call(Router, :get, "/default_static/text.html")
    assert conn.status == 200
    assert conn.resp_body == "<html><body>You found me</body></html>\n"
  end

  test "route renders eex template" do
    conn = call(Router, :get, "/template/eex/render_me_plz")
    assert conn.status == 200
    assert conn.resp_body == "<html><body>render_me_plz</body></html>\n"
  end

  test "route renders haml template" do
    conn = call(Router, :get, "/template/haml/render_me_plz")
    assert conn.status == 200
    assert conn.resp_body == "<h1>render_me_plz</h1>"
  end

  test "routes with module-level path prefix" do
    conn = call(Router.API, :get, "/api/status")
    assert conn.status == 200
  end

  test "routes with versioned API" do
    conn = call(Router.VersionedAPI, :get, "/v1/status")
    assert conn.status == 200
    assert conn.resp_body == "v1"
  end

  test "routes that match a specific version" do
    conn = call(Router.VersionedAPI, :get, "/v1/current")
    assert conn.status == 200
    assert conn.resp_body == "o hai"
    conn = call(Router.VersionedAPI, :get, "/beta/current")
    assert conn.status == 400
    conn = call(Router.VersionedAPI, :get, "/v2/current")
    assert conn.status == 200
    assert conn.resp_body == ""
  end
end
