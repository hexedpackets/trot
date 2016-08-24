defmodule Trot do
  @moduledoc """
  Main Trot application. When added to a projects application list, Trot.Supervisor will be started.
  Also contains some generic parsing functions.
  """

  use Application

  @doc false
  def start(_type, _args) do
    Trot.Supervisor.start_link
  end

  @http_methods [:get, :post, :put, :patch, :delete, :options]

  @doc """
  Returns a boolean indicating whether the passed in atom is a valid HTTP method.
  """
  defmacro is_http_method(thing) do
    quote do
      is_atom(unquote(thing)) and unquote(thing) in unquote(@http_methods)
    end
  end

  @doc """
  Parses a query string into a keyword list.
  """
  def parse_query_string(string) do
    string
    |> URI.query_decoder
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
