defmodule Trot.RouterTest do
  use ExUnit.Case, async: true
  import Trot.TestHelper
  doctest Trot.Router

  defmodule APIRouter do
    use Trot.Router
    @path_root "api"
    get "/status", do: :ok
  end

  defmodule Router do
    use Plug.Builder

    plug :begin_plug

    use Trot.Router
    use Trot.Template
    @template_root "test/templates"
    @static_root "test/static"

    get "/status", do: 200
    get "/status_atom", do: :bad_request
    get "/text", headers: %{"x-content-type" => "do it for the"}, do: {200, "lulz"}
    get "/text", host: "bacon.io", do: {200, "wrapped scallops"}
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
    get "/headers/keyword", do: {:ok, "", ["x-test-header": "disrupt"]}
    get "/headers/dict", do: {:ok, "", %{"x-test-header" => "disrupt"}}

    # badrpc tests
    get "/badrpc", do: {:badrpc, :nodedown}
    get "/badrpc/nested", do: {:badrpc, {%Protocol.UndefinedError{description: nil, protocol: Enumerable, value: ""}}}

    redirect "/macro_redirect", "/status"
    static "/static", "/"
    static "/default_static"

    import_routes Trot.RouterTest.APIRouter

    def begin_plug(conn = %{path_info: ["begin"]}, _opts) do
      conn
      |> Plug.Conn.put_resp_header("x-the-beginning", "where it all started")
      |> Plug.Conn.send_resp(420, "")
      |> Plug.Conn.halt
    end
    def begin_plug(conn, _), do: conn
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

  test "route matches on request headers" do
    conn = call(Router, :get, "/text", nil, %{"x-content-type" => "do it for the"})
    assert conn.status == 200
    assert conn.resp_body == "lulz"
  end

  test "route matches on host" do
    conn = call(Router, :get, "http://bacon.io/text")
    assert conn.status == 200
    assert conn.resp_body == "wrapped scallops"
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

  test "route returns a bad rpc call" do
    conn = call(Router, :get, "/badrpc")
    assert conn.status == 500
    assert conn.resp_body == ":nodedown"
  end

  test "route returns a bad rpc call with a nested error message" do
    conn = call(Router, :get, "/badrpc/nested")
    assert conn.status == 500
    assert conn.resp_body == ~S'{%Protocol.UndefinedError{description: nil, protocol: Enumerable, value: ""}}'
  end

  test "route returns redirect" do
    conn = call(Router, :get, "/redirect")
    location = Plug.Conn.get_resp_header(conn, "location") |> List.first
    assert conn.status == 307
    assert location == "/text"
  end

  test "redirect macro" do
    conn = call(Router, :get, "/macro_redirect")
    location = Plug.Conn.get_resp_header(conn, "location") |> List.first
    assert conn.status == 307
    assert location == "/status"
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
    conn = call(Router, :get, "/api/status")
    assert conn.status == 200
  end

  test "keyword list of headers returned from route" do
    conn = call(Router, :get, "/headers/keyword")
    assert conn.status == 200
    header = conn |> Plug.Conn.get_resp_header("x-test-header") |> List.first
    assert header == "disrupt"
  end

  test "dict of headers returned from route" do
    conn = call(Router, :get, "/headers/dict")
    assert conn.status == 200
    header = conn |> Plug.Conn.get_resp_header("x-test-header") |> List.first
    assert header == "disrupt"
  end

  test "default heartbeat route" do
    conn = call(Router, :get, "/heartbeat")
    assert conn.status == 200
    assert conn.resp_body == "OK"
  end

  test "plug added before routing" do
    conn = call(Router, :get, "/begin")
    assert Plug.Conn.get_resp_header(conn, "x-the-beginning") |> List.first == "where it all started"
    assert conn.status == 420
  end
end
