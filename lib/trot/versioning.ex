defmodule Trot.Versioning do
  @moduledoc ~S"""
  Module for handling API versioning within requests.

  To automatically retrieve the requested API version, add Trot.Versioning to
  the list of plugs either manually or by using it. Endpoints can also be set to
  only match a specific version using the `version` option. The special value
  `:any` will match every version, which is also the default behavior.

  ## Example

      defmodele SickAPI do
        use Trot.Versioning
        use Trot.Router

        get "/sweet_endpoint", version: "beta" do
          {:bad_request, "Naw man, that's not ready yet."}
        end

        get "/sweet_endpoint" do
          "Sweet! #{conn.assigns[:version]} is up!"
        end
      end

      $ curl localhost:4000/v1/sweet_endpoint
      Sweet! v1 is up!

      $ curl localhost:4000/beta/sweet_endpoint
      Naw man, that's not ready yet.
  """

  @doc false
  defmacro __using__(_opts) do
    quote do
      import Plug.Builder, only: [plug: 1]
      import Trot.Versioning, only: [version: 2]

      @behaviour Plug
      @plug_builder_opts []
      Module.register_attribute(__MODULE__, :plugs, accumulate: true)

      plug :version
    end
  end

  @doc """
  Plug for pulling the API version out of the request path and assigning it to
  the connection.
  """
  def version(conn = %Plug.Conn{path_info: [v | path]}, _opts) do
    conn
    |> Plug.Conn.assign(:version, v)
    |> Map.put(:path_info, path)
  end

  @doc ~S"""
  Returns a quoted match against the passed in version for use in routing requests.

  ## Examples:
      iex> Trot.Versioning.build_version_match(nil)
      %{}
      iex> Trot.Versioning.build_version_match(:any)
      %{}
      iex> Trot.Versioning.build_version_match("v1")
      %{version: "v1"}
  """
  def build_version_match(version), do: build_version_match(%{}, version)

  @doc """
  Same as `build_version_match/1` but with an existing dictionary of match options passed in.
  """
  def build_version_match(matcher, nil), do: matcher
  def build_version_match(matcher, :any), do: matcher
  def build_version_match(matcher, version), do: Map.put(matcher, :version, version)
end
