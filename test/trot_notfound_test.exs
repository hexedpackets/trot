defmodule Trot.NotFoundTest do
  use ExUnit.Case, async: true
  import Trot.TestHelper


  defmodule NotFoundRouter do
    use Trot.Router
    use Trot.NotFound
  end


  test "unknown route is handled" do
    conn = call(NotFoundRouter, :get, "/this/does/not/exist")
    assert conn.status == 404
  end
end
