defmodule Trot.Test do
  use ExUnit.Case, async: true

  test "parsing a query string" do
    assert Trot.parse_query_string("foo=bar&this=thing") == [foo: "bar", this: "thing"]
  end

  test "parsing a query string with no value" do
    assert Trot.parse_query_string("foo=bar&bacon") == [foo: "bar", bacon: true]
  end

  test "parsing a query string with multiple value" do
    assert Trot.parse_query_string("delicious=[\"bacon\", \"steak\"]") == [delicious: ["bacon", "steak"]]
  end
end
