defmodule Trot do
  @http_methods [:get, :post, :put, :patch, :delete, :options]

  defmacro is_http_method(thing) do
    quote do
      is_atom(unquote(thing)) and unquote(thing) in @http_methods
    end
  end
end
