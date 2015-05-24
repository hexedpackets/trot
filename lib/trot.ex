defmodule Trot do
  @http_methods [:get, :post, :put, :patch, :delete, :options]

  defmacro is_http_method(thing) do
    quote do
      is_atom(unquote(thing)) and unquote(thing) in @http_methods
    end
  end

  @doc """
  Parses a query string into a keyword list.
  """
  def parse_query_string(string) do
    URI.query_decoder(string)
        |> Enum.reverse
        |> Enum.reduce([], &decode_pair(&1, &2))
  end

  defp decode_pair({key, nil}, acc) do
    key = String.to_atom(key)
    Keyword.put(acc, key, true)
  end
  defp decode_pair({key, value}, acc) do
    key = String.to_atom(key)
    case Poison.decode(value) do
      {:ok, decoded} -> Keyword.put(acc, key, decoded)
      {:error, _} -> Keyword.put(acc, key, value)
    end
  end
end
