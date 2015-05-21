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
    get "/template/:text", do: render_template("index.html.eex", [body: text])

    redirect "/macro_redirect", "/status"
    static "/static", "test/static"
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

  test "route renders eex template" do
    conn = call(Router, :get, "/template/render_me_plz")
    assert conn.status == 200
    assert conn.resp_body == "<html><body>render_me_plz</body></html>\n"
  end
end
