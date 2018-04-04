defmodule Trot.AuthCheckTest do
  use ExUnit.Case, async: true
  import Trot.TestHelper

  defmodule AuthCheckRouter do
    use Plug.Builder
    plug Trot.AuthCheck, [routes: ["/secret"]]
    use Trot.Router

    get "/public", do: :ok
    get "/secret", do: "secret squirrel!"
  end

  test "public route is allowed through" do
    conn = call(AuthCheckRouter, :get, "/public")
    assert conn.status == 200
  end

  test "default route returns unauthorized" do
    conn = call(AuthCheckRouter, :get, "/secret")
    assert conn.status == 403
  end

  defmodule CustomAuthCheckRouter do
    use Plug.Builder
    plug Trot.AuthCheck, [routes: ["/secret"], match_fun: &CustomAuthCheckRouter.secret_resp/1]
    use Trot.Router

    get "/secret", do: "secret squirrel!"

    def secret_resp(conn) do
      conn |> send_resp(420, "") |> halt
    end
  end

  test "custom auth match function" do
    conn = call(CustomAuthCheckRouter, :get, "/secret")
    assert conn.status == 420
  end
end
