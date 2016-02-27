defmodule Trot.VersioningTest do
  use ExUnit.Case, async: true
  import Trot.TestHelper
  doctest Trot.Versioning


  defmodule VersionedRouter do
    use Trot.Versioning
    use Trot.Router

    get "/status", do: {:ok, conn.assigns[:version]}

    get "/current", version: "v1", do: "o hai"
    get "/current", version: "beta", do: :bad_request
    get "/current", version: :any, do: :ok
  end


  test "routes with versioned API" do
    conn = call(VersionedRouter, :get, "/v1/status")
    assert conn.status == 200
    assert conn.resp_body == "v1"
  end

  test "routes that match a specific version" do
    conn = call(VersionedRouter, :get, "/v1/current")
    assert conn.status == 200
    assert conn.resp_body == "o hai"
    conn = call(VersionedRouter, :get, "/beta/current")
    assert conn.status == 400
    conn = call(VersionedRouter, :get, "/v2/current")
    assert conn.status == 200
    assert conn.resp_body == ""
  end
end
